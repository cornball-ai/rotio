# Functional builders and accessors for the OTIO object model.
#
# Everything here is value-semantics: builders return a NEW object with the
# change applied; the input is untouched. Compose timelines bottom-up (build
# clips, add them to a track, add tracks to a timeline) so nothing ever needs
# to reach into a sub-node and mutate it.

#' Append a child to a composition
#'
#' Returns a new composition (Track or Stack) with \code{child} appended. The
#' input is unchanged.
#'
#' @param parent A \code{\link{Track}} or \code{\link{Stack}}.
#' @param child An item to append (clip, gap, or track for a stack).
#' @return A new composition.
#' @examples
#' v <- Track("V1", kind = "Video")
#' v <- add_child(v, Clip("a", ExternalReference("a.mp4")))
#' @export
add_child <- function(parent, child) {
    if (!is_composition(parent)) {
        stop("add_child: parent must be a Track or Stack", call. = FALSE)
    }
    if (!(inherits(child, "Item") || is_composition(child))) {
        stop("add_child: child must be a composable (clip, gap, track)",
             call. = FALSE)
    }
    parent$children <- c(parent$children, list(child))
    parent
}

#' Append a track to a timeline
#'
#' Returns a new timeline with \code{track} appended to its track stack. The
#' input is unchanged.
#'
#' @param timeline A \code{\link{Timeline}}.
#' @param track A \code{\link{Track}}.
#' @return A new timeline.
#' @examples
#' tl <- Timeline("demo")
#' tl <- add_track(tl, Track("V1", kind = "Video"))
#' @export
add_track <- function(timeline, track) {
    if (!is_timeline(timeline)) {
        stop("add_track: timeline must be a Timeline", call. = FALSE)
    }
    if (!inherits(track, "Track")) {
        stop("add_track: track must be a Track", call. = FALSE)
    }
    timeline$tracks <- add_child(timeline$tracks, track)
    timeline
}

#' The track stack of a timeline
#' @param x A \code{\link{Timeline}}.
#' @return The timeline's \code{\link{Stack}} of tracks.
#' @export
tracks <- function(x) {
    if (!is_timeline(x)) {
        stop("tracks: x must be a Timeline", call. = FALSE)
    }
    x$tracks
}

#' Children of a composition
#' @param x A \code{\link{Track}} or \code{\link{Stack}}.
#' @export
children <- function(x) {
    if (!is_composition(x)) {
        stop("children: x must be a composition", call. = FALSE)
    }
    x$children
}

#' Get or set object metadata
#'
#' \code{metadata(x)} reads the metadata object; \code{metadata(x) <- value}
#' returns a copy of \code{x} with metadata replaced (value semantics, so it
#' rebinds \code{x} in the caller).
#'
#' @param x An OTIO object.
#' @param value A named list.
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
#' @export
name <- function(x) x$name

#' @rdname name
#' @export
`name<-` <- function(x, value) {
    x$name <- as.character(value)
    x
}

#' Track kind
#' @param x A \code{\link{Track}}.
#' @export
kind <- function(x) x$kind

#' Source range of an item
#' @param x An item (clip, gap, track).
#' @param value A \code{\link{TimeRange}}.
#' @export
source_range <- function(x) x$source_range

#' @rdname source_range
#' @export
`source_range<-` <- function(x, value) {
    x$source_range <- value
    x
}

#' Active media reference of a clip
#' @param x A \code{\link{Clip}}.
#' @export
media_reference <- function(x) {
    if (!inherits(x, "Clip")) {
        stop("media_reference: x must be a Clip", call. = FALSE)
    }
    x$media_references[[x$active_media_reference_key]]
}

#' Target URL of a clip or external reference
#' @param x A \code{\link{Clip}} or \code{\link{ExternalReference}}.
#' @param value New URL.
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
            # Active ref has no URL (e.g. a MissingReference): promote it to an
            # ExternalReference, carrying over its name/range/metadata.
            ref <- ExternalReference(value,
                                     available_range = ref$available_range,
                                     metadata = ref$metadata)
        }
        x$media_references[[key]] <- ref
        return(x)
    }
    stop("target_url<-: x must be a Clip or ExternalReference", call. = FALSE)
}

