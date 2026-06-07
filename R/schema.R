# Phase 6: schema machinery. Schema name/version introspection, the current
# type->version map (matching OpenTimelineIO 0.18.1 / rotio), unknown-schema
# detection, and an upgrade/downgrade registry consulted when parsing JSON.

# Current schema versions, matching rotio's type_version_map(). Everything is at
# version 1 except Clip and Marker (version 2).
.TYPE_VERSION_MAP <- c(UnknownSchema = 1L, Timeline = 1L, Transition = 1L,
                       TimeEffect = 1L, Stack = 1L,
                       SerializableObjectWithMetadata = 1L,
                       SerializableObject = 1L, Track = 1L,
                       MissingReference = 1L, Composition = 1L,
                       Composable = 1L, FreezeFrame = 1L, Effect = 1L,
                       GeneratorReference = 1L, LinearTimeWarp = 1L,
                       SerializableCollection = 1L, ExternalReference = 1L,
                       ImageSequenceReference = 1L, Item = 1L, Clip = 2L,
                       MediaReference = 1L, Gap = 1L, Marker = 2L)

# Schema-migration registries (one entry per schema name -> version -> function).
.schema_upgrades <- new.env(parent = emptyenv())
.schema_downgrades <- new.env(parent = emptyenv())

.schema_type <- function(schema) sub("\\.[0-9]+$", "", schema)
.schema_ver <- function(schema) {
    m <- regmatches(schema, regexpr("[0-9]+$", schema))
    if (length(m)) {
        as.integer(m)
    } else {
        NA_integer_
    }
}

#' Current OTIO schema versions
#'
#' A named integer vector mapping each schema type to its current version,
#' matching OpenTimelineIO 0.18.1.
#'
#' @return A named integer vector.
#' @export
type_version_map <- function() .TYPE_VERSION_MAP

#' Schema name of an OTIO object
#'
#' The schema type (without the version suffix); unrecognised types report
#' \code{"UnknownSchema"} (matching OTIO).
#'
#' @param x An OTIO object.
#' @return A character scalar.
#' @export
schema_name <- function(x) {
    if (!is_otio(x) || is.null(x$OTIO_SCHEMA)) {
        stop("schema_name: x must be an OTIO object", call. = FALSE)
    }
    type <- .schema_type(x$OTIO_SCHEMA)
    if (type %in% names(.TYPE_VERSION_MAP)) {
        type
    } else {
        "UnknownSchema"
    }
}

#' Schema version of an OTIO object
#' @param x An OTIO object.
#' @return An integer.
#' @export
schema_version <- function(x) {
    if (!is_otio(x) || is.null(x$OTIO_SCHEMA)) {
        stop("schema_version: x must be an OTIO object", call. = FALSE)
    }
    .schema_ver(x$OTIO_SCHEMA)
}

#' Is an object's schema unknown?
#'
#' \code{TRUE} when the object's schema type is not a recognised OTIO type
#' (e.g. parsed from JSON written by a newer or third-party schema).
#'
#' @param x An OTIO object.
#' @export
is_unknown_schema <- function(x) {
    if (!is_otio(x) || is.null(x$OTIO_SCHEMA)) {
        return(FALSE)
    }
    !(.schema_type(x$OTIO_SCHEMA) %in% names(.TYPE_VERSION_MAP))
}

#' Register a schema upgrade function
#'
#' \code{fn} receives the parsed field list of a \code{schema_name} object at the
#' version below \code{version_to_upgrade_to} and returns the upgraded list. It is
#' applied automatically by \code{\link{from_json_string}} when an older version
#' is read.
#'
#' @param schema_name Schema type name (e.g. \code{"Marker"}). Must be a known
#'   OTIO schema.
#' @param version_to_upgrade_to Target version (integer).
#' @param fn Function of one argument (the field list) returning a field list.
#' @return \code{TRUE} if registered; \code{FALSE} for an unknown schema or a
#'   duplicate \code{(schema, version)} pair (matching rotio).
#' @export
register_upgrade_function <- function(schema_name, version_to_upgrade_to, fn) {
    if (!is.function(fn)) {
        stop("register_upgrade_function: fn must be a function", call. = FALSE)
    }
    .register_migration(.schema_upgrades, schema_name, version_to_upgrade_to,
                        fn)
}

# Shared registration: TRUE on a fresh registration; FALSE for an unknown schema
# or a duplicate (schema, version) pair (matching rotio).
.register_migration <- function(reg, schema_name, version, fn) {
    key <- as.character(schema_name)
    if (!(key %in% names(.TYPE_VERSION_MAP))) {
        return(FALSE)
    }
    vkey <- as.character(as.integer(version))
    tbl <- reg[[key]]
    if (!is.null(tbl) && !is.null(tbl[[vkey]])) {
        return(FALSE)
    }
    if (is.null(tbl)) {
        tbl <- list()
    }
    tbl[[vkey]] <- fn
    reg[[key]] <- tbl
    TRUE
}

#' Register a schema downgrade function
#'
#' \code{fn} receives the field list of a \code{schema_name} object at
#' \code{version_to_downgrade_from} and returns the field list one version lower.
#' Stored for use when writing older schema versions.
#'
#' @param schema_name Schema type name. Must be a known OTIO schema.
#' @param version_to_downgrade_from Source version (integer).
#' @param fn Function of one argument (the field list) returning a field list.
#' @return \code{TRUE} if registered; \code{FALSE} for an unknown schema or a
#'   duplicate \code{(schema, version)} pair (matching rotio).
#' @export
register_downgrade_function <- function(schema_name,
                                        version_to_downgrade_from, fn) {
    if (!is.function(fn)) {
        stop("register_downgrade_function: fn must be a function",
             call. = FALSE)
    }
    .register_migration(.schema_downgrades, schema_name,
                        version_to_downgrade_from, fn)
}

# Apply registered upgrade functions to a parsed field list whose schema version
# is below the current one. Only relabels OTIO_SCHEMA up to the highest version a
# registered upgrade actually reached (so stale data is never mislabeled).
.apply_upgrades <- function(x) {
    schema <- x[["OTIO_SCHEMA"]]
    type <- .schema_type(schema)
    ver <- .schema_ver(schema)
    if (!(type %in% names(.TYPE_VERSION_MAP)) || is.na(ver)) {
        return(x)
    }
    target <- .TYPE_VERSION_MAP[[type]]
    if (ver >= target) {
        return(x)
    }
    tbl <- .schema_upgrades[[type]]
    reached <- ver
    for (v in (ver + 1L):target) {
        if (is.null(tbl)) {
            fn <- NULL
        } else {
            fn <- tbl[[as.character(v)]]
        }
        if (is.null(fn)) {
            break
        }
        x <- fn(x)
        reached <- v
    }
    x[["OTIO_SCHEMA"]] <- paste0(type, ".", reached)
    x
}

# Validate and coerce target_schema_versions (a named whole-number vector) to a
# named list for lookup. Rejects unnamed, duplicate, NA, non-numeric, and
# non-whole versions (matching rotio's guard).
.normalize_targets <- function(targets) {
    if (is.null(targets)) {
        return(NULL)
    }
    nm <- names(targets)
    if (is.null(nm) || anyNA(nm) || any(!nzchar(nm))) {
        stop("target_schema_versions must be a named integer vector (schema -> version)",
             call. = FALSE)
    }
    if (anyDuplicated(nm)) {
        stop("target_schema_versions has duplicate schema names", call. = FALSE)
    }
    if (!is.numeric(targets) || anyNA(targets) ||
        any(targets != floor(targets))) {
        stop("target_schema_versions versions must be whole numbers",
             call. = FALSE)
    }
    stats::setNames(as.list(as.integer(targets)), nm)
}

# Apply registered downgrade functions to a serialized field list whose schema
# version is above the requested target. `targets` is a named list type->version.
.apply_downgrades <- function(d, targets) {
    schema <- d[["OTIO_SCHEMA"]]
    if (is.null(schema)) {
        return(d)
    }
    type <- .schema_type(schema)
    ver <- .schema_ver(schema)
    tgt <- targets[[type]]
    if (is.null(tgt) || is.na(ver) || tgt >= ver) {
        return(d)
    }
    tbl <- .schema_downgrades[[type]]
    reached <- ver
    for (v in ver:(as.integer(tgt) + 1L)) {
        if (is.null(tbl)) {
            fn <- NULL
        } else {
            fn <- tbl[[as.character(v)]]
        }
        if (is.null(fn)) {
            break
        }
        d <- fn(d) # downgrade from v to v-1
        reached <- v - 1L
    }
    d[["OTIO_SCHEMA"]] <- paste0(type, ".", reached)
    d
}

# ---- default-field materialization ----------------------------------------
# A parsed (and possibly upgraded) object may omit fields that have current-schema
# defaults; OTIO materializes them. We merge parsed values over a template built
# from the type's constructor, in canonical key order.
.schema_template_cache <- new.env(parent = emptyenv())

.template_builder <- function(type) {
    switch(type, Clip = function() Clip(""),
           Gap = function() Gap(RationalTime(0, 1)),
           Track = function() Track(""), Stack = function() Stack(),
           Timeline = function() Timeline(), Item = function() Item(),
           Marker = function() Marker(), Transition = function() Transition(),
           Effect = function() Effect(), TimeEffect = function() TimeEffect(),
           LinearTimeWarp = function() LinearTimeWarp(),
           FreezeFrame = function() FreezeFrame(),
           ExternalReference = function() ExternalReference(""),
           MissingReference = function() MissingReference(),
           MediaReference = function() MediaReference(),
           GeneratorReference = function() GeneratorReference(),
           ImageSequenceReference = function() ImageSequenceReference(),
           SerializableCollection = function() SerializableCollection(), NULL)
}

# The plain (canonical keys + default values) field list for a type, cached.
.schema_template <- function(type) {
    cached <- .schema_template_cache[[type]]
    if (!is.null(cached)) {
        return(cached)
    }
    b <- .template_builder(type)
    if (is.null(b)) {
        return(NULL)
    }
    tmpl <- .to_plain(b())
    .schema_template_cache[[type]] <- tmpl
    tmpl
}

# Overlay a parsed field list over its type's template defaults (canonical order).
.fill_schema_defaults <- function(x, type) {
    tmpl <- .schema_template(type)
    if (is.null(tmpl)) {
        return(x)
    }
    out <- tmpl
    for (k in names(x)) {
        out[k] <- list(x[[k]]) # single-bracket: preserves an explicit NULL value
    }
    out
}

# ---- built-in migrations (mirroring OTIO typeRegistry.cpp) ----------------
.schema_upgrades[["Marker"]] <- list(`2` = function(d) {
    d[["marked_range"]] <- d[["range"]]
    d[["range"]] <- NULL
    d
})
.schema_upgrades[["Clip"]] <- list(`2` = function(d) {
    mref <- d[["media_reference"]]
    if (is.null(mref)) {
        mref <- list(OTIO_SCHEMA = "MissingReference.1",
                     metadata = setNames(list(), character()), name = "",
                     available_range = NULL, available_image_bounds = NULL)
    }
    d[["media_references"]] <- list(DEFAULT_MEDIA = mref)
    d[["active_media_reference_key"]] <- "DEFAULT_MEDIA"
    d[["media_reference"]] <- NULL
    d
})
.schema_downgrades[["Clip"]] <- list(`2` = function(d) {
    mrefs <- d[["media_references"]]
    active <- d[["active_media_reference_key"]]
    if (!is.null(mrefs) && !is.null(active) && !is.null(mrefs[[active]])) {
        d[["media_reference"]] <- mrefs[[active]]
    }
    d[["media_references"]] <- NULL
    d[["active_media_reference_key"]] <- NULL
    d
})

