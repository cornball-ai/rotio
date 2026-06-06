# OpenTimelineIO object model, pure R.
#
# Each object is an ordinary list with an OTIO_SCHEMA field and an S3 class tag.
# Fields are stored in OTIO JSON key order so the serializer (see serialize.R)
# can emit canonical OTIO without reordering. Objects are immutable values:
# the builders in build.R return new objects rather than mutating in place.
#
# Schema versions match the linked OTIO (Clip.2, everything else *.1), captured
# from rotio's serializer so emitted JSON round-trips through real OTIO.

#' Construct a media reference
#'
#' \code{ExternalReference} points a clip at media by URL.
#' \code{MissingReference} is a placeholder for a clip with no resolvable media
#' (e.g. a caption clip whose visible artifact is a burned subtitle).
#'
#' @param target_url Media URL for an \code{ExternalReference}.
#' @param available_range Optional \code{\link{TimeRange}} of available media.
#' @param metadata Named list of metadata (serialized as a JSON object).
#' @return A media reference object.
#' @examples
#' ExternalReference("media/clip01.mp4")
#' MissingReference()
#' @export
ExternalReference <- function(target_url, available_range = NULL,
                              metadata = NULL) {
    structure(list(OTIO_SCHEMA = "ExternalReference.1",
                   metadata = .as_metadata(metadata), name = "",
                   available_range = available_range,
                   available_image_bounds = NULL,
                   target_url = as.character(target_url)),
              class = c("ExternalReference", "MediaReference", "otio_object"))
}

#' @rdname ExternalReference
#' @param name Reference name (default empty).
#' @export
MissingReference <- function(name = "", available_range = NULL,
                             metadata = NULL) {
    structure(list(OTIO_SCHEMA = "MissingReference.1",
                   metadata = .as_metadata(metadata),
                   name = as.character(name),
                   available_range = available_range,
                   available_image_bounds = NULL),
              class = c("MissingReference", "MediaReference", "otio_object"))
}

#' Construct a Clip
#'
#' An OTIO \code{Clip} is a media reference plus a \code{source_range} (the
#' portion of the media used). The reference is stored under the
#' \code{DEFAULT_MEDIA} key, matching OTIO's multi-reference model.
#'
#' @param name Clip name.
#' @param media_reference A media reference (see \code{\link{ExternalReference}});
#'   defaults to a \code{MissingReference}.
#' @param source_range Optional \code{\link{TimeRange}} into the media.
#' @param metadata Named list of metadata.
#' @return A \code{Clip} object.
#' @examples
#' Clip("a", ExternalReference("a.mp4"),
#'      source_range = TimeRange(RationalTime(0, 30), RationalTime(90, 30)))
#' @export
Clip <- function(name, media_reference = MissingReference(),
                 source_range = NULL, metadata = NULL) {
    if (!is_media_reference(media_reference)) {
        stop("Clip: media_reference must be a media reference", call. = FALSE)
    }
    structure(list(OTIO_SCHEMA = "Clip.2", metadata = .as_metadata(metadata),
                   name = as.character(name), source_range = source_range,
                   effects = list(), markers = list(), enabled = TRUE,
                   color = NULL,
                   media_references = list(DEFAULT_MEDIA = media_reference),
                   active_media_reference_key = "DEFAULT_MEDIA"),
              class = c("Clip", "Item", "otio_object"))
}

#' Construct a Gap
#'
#' A \code{Gap} is empty space on a track of a given duration.
#'
#' @param duration A \code{\link{RationalTime}} for the gap length.
#' @param name Gap name.
#' @param metadata Named list of metadata.
#' @return A \code{Gap} object.
#' @examples
#' Gap(RationalTime(15, 30))
#' @export
Gap <- function(duration, name = "", metadata = NULL) {
    if (!is_rational_time(duration)) {
        stop("Gap: duration must be a RationalTime", call. = FALSE)
    }
    sr <- TimeRange(RationalTime(0, duration$rate), duration)
    structure(list(OTIO_SCHEMA = "Gap.1", metadata = .as_metadata(metadata),
                   name = as.character(name), source_range = sr,
                   effects = list(), markers = list(), enabled = TRUE,
                   color = NULL),
              class = c("Gap", "Item", "otio_object"))
}

#' Construct a Track
#'
#' An OTIO \code{Track} is an ordered sequence of items (clips, gaps). Add
#' children with \code{\link{add_child}}.
#'
#' @param name Track name.
#' @param kind Track kind, \code{"Video"} (default) or \code{"Audio"}.
#' @param source_range Optional \code{\link{TimeRange}}.
#' @param metadata Named list of metadata.
#' @return A \code{Track} object.
#' @examples
#' Track("V1", kind = "Video")
#' @export
Track <- function(name, kind = "Video", source_range = NULL, metadata = NULL) {
    structure(list(OTIO_SCHEMA = "Track.1", metadata = .as_metadata(metadata),
                   name = as.character(name), source_range = source_range,
                   effects = list(), markers = list(), enabled = TRUE,
                   color = NULL, children = list(), kind = as.character(kind)),
              class = c("Track", "Composition", "otio_object"))
}

#' Construct a Stack
#'
#' An OTIO \code{Stack} holds parallel tracks (the timeline's \code{tracks} is a
#' Stack). Add tracks with \code{\link{add_child}}.
#'
#' @param name Stack name (default \code{"tracks"}).
#' @param source_range Optional \code{\link{TimeRange}}.
#' @param metadata Named list of metadata.
#' @return A \code{Stack} object.
#' @export
Stack <- function(name = "tracks", source_range = NULL, metadata = NULL) {
    structure(list(OTIO_SCHEMA = "Stack.1", metadata = .as_metadata(metadata),
                   name = as.character(name), source_range = source_range,
                   effects = list(), markers = list(), enabled = TRUE,
                   color = NULL, children = list()),
              class = c("Stack", "Composition", "otio_object"))
}

#' Construct a Timeline
#'
#' An OTIO \code{Timeline} wraps a \code{\link{Stack}} of tracks. Add tracks with
#' \code{\link{add_track}}.
#'
#' @param name Timeline name.
#' @param global_start_time Optional \code{\link{RationalTime}} timeline start.
#' @param metadata Named list of metadata.
#' @return A \code{Timeline} object.
#' @examples
#' Timeline("demo")
#' @export
Timeline <- function(name = "", global_start_time = NULL, metadata = NULL) {
    structure(list(OTIO_SCHEMA = "Timeline.1",
                   metadata = .as_metadata(metadata),
                   name = as.character(name),
                   global_start_time = global_start_time,
                   tracks = Stack("tracks")),
              class = c("Timeline", "otio_object"))
}

# ---- predicates ----------------------------------------------------------

#' Type predicates for OTIO objects
#' @param x Object to test.
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

# ---- print methods -------------------------------------------------------

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

`%||%` <- function(a, b) if (is.null(a)) b else a

