# OpenTimelineIO object model, pure R, environment-backed (reference semantics).
#
# Each OTIO object is an environment carrying its serializable fields plus two
# internal bindings: `.keys` (the field names in OTIO JSON order) and `.parent`
# (the containing composition, or NULL). `.parent` and `.keys` are never
# serialized. Mutating tree ops (see tree.R) update `.parent` in place; `clone()`
# is a deep copy that detaches the root and rewires descendant parents. See
# PLAN.md for the binding object contract.

# Empty JSON object (serializes as {}, not []).
.empty_obj <- function() stats::setNames(list(), character())

# Normalize a metadata argument to a named list (serializes as a JSON object).
.as_metadata <- function(m) {
    if (is.null(m) || length(m) == 0L) {
        return(.empty_obj())
    }
    if (is.null(names(m))) {
        stop("metadata must be a named list", call. = FALSE)
    }
    m
}

# Construct an OTIO object environment. `keys` is the OTIO field order; `fields`
# supplies each key's value (NULL allowed and preserved).
.new_otio <- function(classes, keys, fields) {
    e <- new.env(parent = emptyenv())
    for (k in keys) {
        assign(k, fields[[k]], envir = e)
    }
    e$.keys <- keys
    e$.parent <- NULL
    class(e) <- c(classes, "otio_object")
    e
}

# ---- predicates -----------------------------------------------------------

#' Type predicates for OTIO objects
#' @param x Object to test.
#' @return \code{TRUE} if \code{x} is of the corresponding class, else \code{FALSE}.
#' @examples
#' is_otio(Timeline("demo"))
#' is_timeline(Track("V1"))
#' @export
is_otio <- function(x) inherits(x, "otio_object")

#' @rdname is_otio
#' @export
is_timeline <- function(x) inherits(x, "Timeline")

#' @rdname is_otio
#' @export
is_composition <- function(x) inherits(x, "Composition")

#' @rdname is_otio
#' @export
is_media_reference <- function(x) inherits(x, "MediaReference")

# ---- deep copy / clone ----------------------------------------------------

# Recursively copy an object graph, detaching every node (.parent <- NULL).
.deep_copy <- function(x) {
    if (is_otio(x)) {
        keys <- x$.keys
        e <- new.env(parent = emptyenv())
        for (k in keys) {
            assign(k, .deep_copy(x[[k]]), envir = e)
        }
        e$.keys <- keys
        e$.parent <- NULL
        class(e) <- class(x)
        return(e)
    }
    if (is.list(x)) {
        return(lapply(x, .deep_copy))
    }
    x
}

# Wire `.parent` pointers top-down. A Timeline's root track Stack stays
# parentless (matches OTIO); composition children point to their container.
.rewire_parents <- function(x) {
    if (is_timeline(x)) {
        x$tracks$.parent <- NULL
        .rewire_parents(x$tracks)
    } else if (is_composition(x)) {
        for (ch in x$children) {
            ch$.parent <- x
            .rewire_parents(ch)
        }
    }
    invisible(x)
}

#' Deep-clone an OTIO object
#'
#' Returns a deep copy of \code{x}. The clone's parent is reset to \code{NULL}
#' and its descendants' parent pointers are rewired inside the clone, so it is a
#' fully detached, internally consistent subtree.
#'
#' @param x An OTIO object.
#' @return A deep copy.
#' @examples
#' tl <- add_track(Timeline("a"), Track("V1"))
#' tl2 <- clone(tl)
#' @export
clone <- function(x) {
    if (!is_otio(x)) {
        stop("clone: x must be an OTIO object", call. = FALSE)
    }
    cp <- .deep_copy(x)
    .rewire_parents(cp)
    cp
}

# ---- media references -----------------------------------------------------

#' Construct a media reference
#'
#' \code{ExternalReference} points a clip at media by URL.
#' \code{MissingReference} is a placeholder for a clip with no resolvable media.
#'
#' @param target_url Media URL for an \code{ExternalReference}.
#' @param available_range Optional \code{\link{TimeRange}} of available media.
#' @param metadata Named list of metadata.
#' @return A media reference object.
#' @examples
#' ExternalReference("media/clip01.mp4")
#' MissingReference()
#' @export
ExternalReference <- function(target_url, available_range = NULL,
                              metadata = NULL) {
    .new_otio(
              c("ExternalReference", "MediaReference"),
              c("OTIO_SCHEMA", "metadata", "name", "available_range",
                "available_image_bounds", "target_url"),
              list(OTIO_SCHEMA = "ExternalReference.1", metadata = .as_metadata(metadata),
                   name = "", available_range = available_range,
                   available_image_bounds = NULL, target_url = as.character(target_url)))
}

#' @rdname ExternalReference
#' @param name Reference name (default empty).
#' @export
MissingReference <- function(name = "", available_range = NULL,
                             metadata = NULL) {
    .new_otio(
              c("MissingReference", "MediaReference"),
              c("OTIO_SCHEMA", "metadata", "name", "available_range",
                "available_image_bounds"),
              list(OTIO_SCHEMA = "MissingReference.1", metadata = .as_metadata(metadata),
                   name = as.character(name), available_range = available_range,
                   available_image_bounds = NULL))
}

# ---- items and compositions -----------------------------------------------

#' Construct a Clip
#'
#' A media reference plus a \code{source_range}. The reference is stored under
#' the \code{DEFAULT_MEDIA} key (OTIO's multi-reference model).
#'
#' @param name Clip name.
#' @param media_reference A media reference (default \code{MissingReference}).
#' @param source_range Optional \code{\link{TimeRange}}.
#' @param metadata Named list of metadata.
#' @return A \code{Clip}.
#' @examples
#' Clip("a", ExternalReference("a.mp4"),
#'      source_range = TimeRange(RationalTime(0, 30), RationalTime(90, 30)))
#' @export
Clip <- function(name, media_reference = MissingReference(),
                 source_range = NULL, metadata = NULL) {
    if (!is_media_reference(media_reference)) {
        stop("Clip: media_reference must be a media reference", call. = FALSE)
    }
    .new_otio(
              c("Clip", "Item"),
              c("OTIO_SCHEMA", "metadata", "name", "source_range", "effects",
                "markers", "enabled", "color", "media_references",
                "active_media_reference_key"),
              list(OTIO_SCHEMA = "Clip.2", metadata = .as_metadata(metadata),
                   name = as.character(name), source_range = source_range,
                   effects = list(), markers = list(), enabled = TRUE, color = NULL,
                   media_references = list(DEFAULT_MEDIA = media_reference),
                   active_media_reference_key = "DEFAULT_MEDIA"))
}

#' Construct a Gap
#'
#' Empty space on a track of a given duration.
#'
#' @param duration A \code{\link{RationalTime}}.
#' @param name Gap name.
#' @param metadata Named list of metadata.
#' @return A \code{Gap}.
#' @examples
#' Gap(RationalTime(15, 30))
#' @export
Gap <- function(duration, name = "", metadata = NULL) {
    if (!is_rational_time(duration)) {
        stop("Gap: duration must be a RationalTime", call. = FALSE)
    }
    sr <- TimeRange(RationalTime(0, duration$rate), duration)
    .new_otio(
              c("Gap", "Item"),
              c("OTIO_SCHEMA", "metadata", "name", "source_range", "effects",
                "markers", "enabled", "color"),
              list(OTIO_SCHEMA = "Gap.1", metadata = .as_metadata(metadata),
                   name = as.character(name), source_range = sr, effects = list(),
                   markers = list(), enabled = TRUE, color = NULL))
}

#' Construct a base Item
#'
#' A generic OTIO \code{Item} (the base class of clips, gaps, and compositions).
#' Mainly used by the \code{"Fit"} reference point of \code{\link{fill}}, which
#' wraps media in a plain item carrying a time warp.
#'
#' @param name Item name.
#' @param source_range Optional \code{\link{TimeRange}}.
#' @param effects List of \code{\link{Effect}}s.
#' @param markers List of \code{\link{Marker}}s.
#' @param enabled Whether the item is enabled (default \code{TRUE}).
#' @param metadata Named list of metadata.
#' @return An \code{Item}.
#' @examples
#' Item("warp", source_range = TimeRange(RationalTime(0, 30), RationalTime(60, 30)))
#' @export
Item <- function(name = "", source_range = NULL, effects = NULL,
                 markers = NULL, enabled = TRUE, metadata = NULL) {
    .new_otio("Item",
              c("OTIO_SCHEMA", "metadata", "name", "source_range", "effects",
                "markers", "enabled", "color"),
              list(OTIO_SCHEMA = "Item.1", metadata = .as_metadata(metadata),
                   name = as.character(name), source_range = source_range,
                   effects = effects %||% list(), markers = markers %||% list(),
                   enabled = isTRUE(enabled), color = NULL))
}

#' Construct a Track
#'
#' An ordered sequence of items. Add children with \code{\link{add_child}} (or
#' the mutating \code{\link{append_child}}).
#'
#' @param name Track name.
#' @param kind \code{"Video"} (default) or \code{"Audio"}.
#' @param source_range Optional \code{\link{TimeRange}}.
#' @param metadata Named list of metadata.
#' @return A \code{Track}.
#' @examples
#' Track("V1", kind = "Video")
#' @export
Track <- function(name, kind = "Video", source_range = NULL, metadata = NULL) {
    .new_otio(
              c("Track", "Composition"),
              c("OTIO_SCHEMA", "metadata", "name", "source_range", "effects",
                "markers", "enabled", "color", "children", "kind"),
              list(OTIO_SCHEMA = "Track.1", metadata = .as_metadata(metadata),
                   name = as.character(name), source_range = source_range,
                   effects = list(), markers = list(), enabled = TRUE, color = NULL,
                   children = list(), kind = as.character(kind)))
}

#' Construct a Stack
#'
#' Parallel tracks (a Timeline's \code{tracks} is a Stack).
#'
#' @param name Stack name (default \code{"tracks"}).
#' @param source_range Optional \code{\link{TimeRange}}.
#' @param metadata Named list of metadata.
#' @return A \code{Stack}.
#' @examples
#' Stack()
#' @export
Stack <- function(name = "tracks", source_range = NULL, metadata = NULL) {
    .new_otio(
              c("Stack", "Composition"),
              c("OTIO_SCHEMA", "metadata", "name", "source_range", "effects",
                "markers", "enabled", "color", "children"),
              list(OTIO_SCHEMA = "Stack.1", metadata = .as_metadata(metadata),
                   name = as.character(name), source_range = source_range,
                   effects = list(), markers = list(), enabled = TRUE, color = NULL,
                   children = list()))
}

#' Construct a Timeline
#'
#' Wraps a \code{\link{Stack}} of tracks. Add tracks with \code{\link{add_track}}.
#'
#' @param name Timeline name.
#' @param global_start_time Optional \code{\link{RationalTime}}.
#' @param metadata Named list of metadata.
#' @return A \code{Timeline}.
#' @examples
#' Timeline("demo")
#' @export
Timeline <- function(name = "", global_start_time = NULL, metadata = NULL) {
    .new_otio(
              "Timeline",
              c("OTIO_SCHEMA", "metadata", "name", "global_start_time", "tracks"),
              list(OTIO_SCHEMA = "Timeline.1", metadata = .as_metadata(metadata),
                   name = as.character(name), global_start_time = global_start_time,
                   tracks = Stack("tracks")))
}

# ---- print methods --------------------------------------------------------

#' @export
print.Timeline <- function(x, ...) {
    tr <- x$tracks$children
    cat(sprintf("<Timeline \"%s\": %d track(s)>\n", x$name, length(tr)))
    for (t in tr) {
        cat(sprintf("  %s [%s]: %d child(ren)\n", t$name, t$kind %||% "",
                    length(t$children)))
    }
    invisible(x)
}

#' @export
print.Composition <- function(x, ...) {
    cat(sprintf("<%s \"%s\": %d child(ren)>\n", class(x)[1], x$name,
                length(x$children)))
    invisible(x)
}

#' @export
print.Clip <- function(x, ...) {
    cat(sprintf("<Clip \"%s\" -> %s>\n", x$name,
                target_url(x) %||% "<missing>"))
    invisible(x)
}

#' @export
print.ExternalReference <- function(x, ...) {
    cat(sprintf("<ExternalReference \"%s\">\n", x$target_url))
    invisible(x)
}


