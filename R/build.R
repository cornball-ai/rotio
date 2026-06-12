# Accessors/setters and the functional builders.
#
# Setters mutate the object's environment in place (reference semantics) and
# return it, so the replacement forms (metadata(x) <- v) work. The functional
# builders add_child()/add_track() are value-semantics sugar over the mutating
# tree ops: they clone, append, and return a new object, leaving inputs
# untouched (the contract licuadora and other callers rely on).

#' Append a child, functionally (clone + append)
#'
#' Returns a new composition: a clone of \code{parent} with a clone of
#' \code{child} appended. Neither input is mutated (cf. \code{\link{append_child}},
#' which mutates in place).
#'
#' @param parent A composition (Track/Stack) or collection.
#' @param child An OTIO object.
#' @return A new composition.
#' @examples
#' v <- add_child(Track("V1"), Clip("a", ExternalReference("a.mp4")))
#' @export
add_child <- function(parent, child) {
    out <- clone(parent)
    append_child(out, clone(child))
    out
}

#' Append a track to a timeline, functionally
#'
#' Returns a new timeline (clone) with a clone of \code{track} appended to its
#' stack. Neither input is mutated.
#'
#' @param timeline A \code{\link{Timeline}}.
#' @param track A \code{\link{Track}}.
#' @return A new timeline.
#' @examples
#' tl <- add_track(Timeline("demo"), Track("V1", kind = "Video"))
#' @export
add_track <- function(timeline, track) {
    if (!is_timeline(timeline)) {
        stop("add_track: timeline must be a Timeline", call. = FALSE)
    }
    if (!inherits(track, "Track")) {
        stop("add_track: track must be a Track", call. = FALSE)
    }
    out <- clone(timeline)
    append_child(out$tracks, clone(track))
    out
}

#' The track stack of a timeline
#' @param x A \code{\link{Timeline}}.
#' @param value A \code{\link{Stack}}.
#' @return The timeline's \code{\link{Stack}}.
#' @examples
#' tl <- add_track(Timeline("demo"), Track("V1", kind = "Video"))
#' length(children(tracks(tl)))
#' @export
tracks <- function(x) {
    if (!is_timeline(x)) {
        stop("tracks: x must be a Timeline", call. = FALSE)
    }
    x$tracks
}

#' @rdname tracks
#' @export
`tracks<-` <- function(x, value) {
    x$tracks <- value
    x
}

#' Get or set object metadata
#' @param x An OTIO object.
#' @param value A named list.
#' @return The object's metadata as a named list (possibly empty).
#' @examples
#' cl <- Clip("a")
#' metadata(cl) <- list(note = "take 2")
#' metadata(cl)
#' @export
metadata <- function(x) x$metadata

#' @rdname metadata
#' @export
`metadata<-` <- function(x, value) {
    x$metadata <- .as_metadata(value)
    x
}

#' Get or set the name of an OTIO object
#' @param x An OTIO object.
#' @param value New name.
#' @return The object's name, a character string.
#' @examples
#' cl <- Clip("a")
#' name(cl) <- "b"
#' name(cl)
#' @export
name <- function(x) x$name

#' @rdname name
#' @export
`name<-` <- function(x, value) {
    x$name <- as.character(value)
    x
}

#' Get or set a track's kind
#' @param x A \code{\link{Track}}.
#' @param value \code{"Video"} or \code{"Audio"}.
#' @return The track kind, \code{"Video"} or \code{"Audio"}.
#' @examples
#' trk <- Track("A1", kind = "Audio")
#' kind(trk)
#' @export
kind <- function(x) x$kind

#' @rdname kind
#' @export
`kind<-` <- function(x, value) {
    x$kind <- as.character(value)
    x
}

#' Get or set an item's source range
#' @param x An item (clip, gap, track).
#' @param value A \code{\link{TimeRange}}.
#' @return The item's \code{\link{TimeRange}}, or \code{NULL} if unset.
#' @examples
#' cl <- Clip("a")
#' source_range(cl) <- TimeRange(RationalTime(0, 24), RationalTime(48, 24))
#' source_range(cl)
#' @export
source_range <- function(x) x$source_range

#' @rdname source_range
#' @export
`source_range<-` <- function(x, value) {
    x$source_range <- value
    x
}

#' Whether an item, composition, or effect is enabled
#'
#' A disabled clip/track is muted; a disabled effect is bypassed.
#'
#' @param x An object with an \code{enabled} field.
#' @param value \code{TRUE} or \code{FALSE}.
#' @return \code{TRUE} if the object is enabled, else \code{FALSE}.
#' @examples
#' cl <- Clip("a")
#' enabled(cl) <- FALSE
#' enabled(cl)
#' @export
enabled <- function(x) x$enabled

#' @rdname enabled
#' @export
`enabled<-` <- function(x, value) {
    x$enabled <- isTRUE(value)
    x
}

#' Get or set an item's display color
#' @param x An item or composition.
#' @param value A color value (or \code{NULL}).
#' @return The item's color value, or \code{NULL} if unset.
#' @examples
#' cl <- Clip("a")
#' color(cl) <- "RED"
#' color(cl)
#' @export
color <- function(x) x$color

#' @rdname color
#' @export
`color<-` <- function(x, value) {
    x$color <- value
    x
}

#' Active media reference of a clip
#' @param x A \code{\link{Clip}}.
#' @param value A media reference.
#' @return The clip's active media reference object.
#' @examples
#' cl <- Clip("a", ExternalReference("a.mp4"))
#' media_reference(cl)
#' @export
media_reference <- function(x) {
    if (!inherits(x, "Clip")) {
        stop("media_reference: x must be a Clip", call. = FALSE)
    }
    x$media_references[[x$active_media_reference_key]]
}

#' @rdname media_reference
#' @export
`media_reference<-` <- function(x, value) {
    if (!inherits(x, "Clip")) {
        stop("media_reference<-: x must be a Clip", call. = FALSE)
    }
    if (!is_media_reference(value)) {
        stop("media_reference<-: value must be a media reference",
             call. = FALSE)
    }
    x$media_references[[x$active_media_reference_key]] <- value
    x
}

#' Target URL of a clip or external reference
#' @param x A \code{\link{Clip}} or \code{\link{ExternalReference}}.
#' @param value New URL.
#' @return The target URL string, or \code{NULL} if the active reference has
#'   no URL.
#' @examples
#' cl <- Clip("a", ExternalReference("a.mp4"))
#' target_url(cl) <- "b.mp4"
#' target_url(cl)
#' @export
target_url <- function(x) {
    if (inherits(x, "ExternalReference")) {
        return(x$target_url)
    }
    if (inherits(x, "Clip")) {
        ref <- media_reference(x)
        return(if (inherits(ref, "ExternalReference")) ref$target_url else NULL)
    }
    NULL
}

#' @rdname target_url
#' @export
`target_url<-` <- function(x, value) {
    value <- as.character(value)
    if (inherits(x, "ExternalReference")) {
        x$target_url <- value
        return(x)
    }
    if (inherits(x, "Clip")) {
        key <- x$active_media_reference_key
        ref <- x$media_references[[key]]
        if (inherits(ref, "ExternalReference")) {
            ref$target_url <- value
        } else {
            # Promote a non-URL ref (e.g. MissingReference) to an ExternalReference.
            x$media_references[[key]] <- ExternalReference(value,
                available_range = ref$available_range, metadata = ref$metadata)
        }
        return(x)
    }
    stop("target_url<-: x must be a Clip or ExternalReference", call. = FALSE)
}

