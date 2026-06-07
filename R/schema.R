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
#' @param schema_name Schema type name (e.g. \code{"Marker"}).
#' @param version_to_upgrade_to Target version (integer).
#' @param fn Function of one argument (the field list) returning a field list.
#' @return Invisibly \code{NULL}.
#' @export
register_upgrade_function <- function(schema_name, version_to_upgrade_to, fn) {
    if (!is.function(fn)) {
        stop("register_upgrade_function: fn must be a function", call. = FALSE)
    }
    key <- as.character(schema_name)
    if (is.null(.schema_upgrades[[key]])) {
        .schema_upgrades[[key]] <- list()
    }
    tbl <- .schema_upgrades[[key]]
    tbl[[as.character(as.integer(version_to_upgrade_to))]] <- fn
    .schema_upgrades[[key]] <- tbl
    invisible(NULL)
}

#' Register a schema downgrade function
#'
#' \code{fn} receives the field list of a \code{schema_name} object at
#' \code{version_to_downgrade_from} and returns the field list one version lower.
#' Stored for use when writing older schema versions.
#'
#' @param schema_name Schema type name.
#' @param version_to_downgrade_from Source version (integer).
#' @param fn Function of one argument (the field list) returning a field list.
#' @return Invisibly \code{NULL}.
#' @export
register_downgrade_function <- function(schema_name,
                                        version_to_downgrade_from, fn) {
    if (!is.function(fn)) {
        stop("register_downgrade_function: fn must be a function",
             call. = FALSE)
    }
    key <- as.character(schema_name)
    if (is.null(.schema_downgrades[[key]])) {
        .schema_downgrades[[key]] <- list()
    }
    tbl <- .schema_downgrades[[key]]
    tbl[[as.character(as.integer(version_to_downgrade_from))]] <- fn
    .schema_downgrades[[key]] <- tbl
    invisible(NULL)
}

# Apply registered upgrade functions to a parsed field list whose schema version
# is below the current one. Returns the (possibly migrated) list with its
# OTIO_SCHEMA bumped to the current version.
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
    if (!is.null(tbl)) {
        for (v in (ver + 1L):target) {
            fn <- tbl[[as.character(v)]]
            if (!is.null(fn)) {
                x <- fn(x)
            }
        }
    }
    x[["OTIO_SCHEMA"]] <- paste0(type, ".", target)
    x
}

