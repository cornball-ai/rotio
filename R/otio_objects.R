#' OpenTimelineIO object model (Timeline / Track / Clip)
#'
#' These constructors build live OpenTimelineIO objects in the linked C++
#' library and return lightweight S3 handles wrapping an external pointer. They
#' are the foundation the sequence model migrates onto (see PLAN.md); the
#' pure-R \code{\link{new_sequence}} model is unchanged for now.
#'
#' Unlike the pure-R edit verbs, these objects are mutable: \code{otio_add_track}
#' and \code{otio_add_clip} modify the timeline in place (the C++ object is
#' shared, not copied). Serialization and all field reads are performed by OTIO.
#'
#' @param name Object name.
#' @return An \code{otio_timeline}, \code{otio_track}, or \code{otio_clip}.
#' @examples
#' tl <- otio_timeline("demo")
#' v1 <- otio_track("v1", "Video")
#' otio_add_track(tl, v1)
#' otio_add_clip(v1, otio_clip("a", "a.mp4", start = 0, duration = 90, rate = 30))
#' otio_tracks(tl)
#' otio_clips(v1)
#' @name otio_objects
NULL

#' @rdname otio_objects
#' @export
otio_timeline <- function(name = "") {
    structure(list(ptr = otio_timeline_create(as.character(name))),
              class = "otio_timeline")
}

#' @rdname otio_objects
#' @param kind Track kind, \code{"Video"} (default) or \code{"Audio"}.
#' @export
otio_track <- function(name = "", kind = c("Video", "Audio")) {
    kind <- match.arg(kind)
    structure(list(ptr = otio_track_create(as.character(name), kind)),
              class = "otio_track")
}

#' @rdname otio_objects
#' @param target_url Media URL for the clip's external reference.
#' @param start First frame of the source range (value, in \code{rate} units).
#' @param duration Source range duration (value, in \code{rate} units).
#' @param rate Rate (fps) for \code{start} and \code{duration}.
#' @export
otio_clip <- function(name = "", target_url = "", start = 0, duration = 0,
                      rate = 30) {
    structure(
        list(ptr = otio_clip_create(as.character(name), as.character(target_url),
                                    as.double(start), as.double(rate),
                                    as.double(duration), as.double(rate))),
        class = "otio_clip")
}

#' @rdname otio_objects
#' @param timeline An \code{otio_timeline}.
#' @param track An \code{otio_track}.
#' @export
otio_add_track <- function(timeline, track) {
    stopifnot(inherits(timeline, "otio_timeline"), inherits(track, "otio_track"))
    otio_timeline_add_track(timeline$ptr, track$ptr)
    invisible(timeline)
}

#' @rdname otio_objects
#' @param clip An \code{otio_clip}.
#' @export
otio_add_clip <- function(track, clip) {
    stopifnot(inherits(track, "otio_track"), inherits(clip, "otio_clip"))
    otio_track_add_clip(track$ptr, clip$ptr)
    invisible(track)
}

#' @rdname otio_objects
#' @param i 1-based index of the child to remove from a track.
#' @export
otio_remove_clip <- function(track, i) {
    stopifnot(inherits(track, "otio_track"))
    otio_track_remove_clip(track$ptr, as.integer(i) - 1L)
    invisible(track)
}

#' @rdname otio_objects
#' @export
otio_tracks <- function(timeline) {
    stopifnot(inherits(timeline, "otio_timeline"))
    otio_timeline_tracks_df(timeline$ptr)
}

#' @rdname otio_objects
#' @export
otio_clips <- function(track) {
    stopifnot(inherits(track, "otio_track"))
    otio_track_clips_df(track$ptr)
}

#' Name / kind of an OTIO object
#' @param x An \code{otio_timeline}, \code{otio_track}, or \code{otio_clip}.
#' @return The object's name (character).
#' @export
otio_name <- function(x) {
    if (inherits(x, "otio_timeline")) return(otio_get_timeline_name(x$ptr))
    if (inherits(x, "otio_track")) return(otio_get_track_name(x$ptr))
    if (inherits(x, "otio_clip")) return(otio_get_clip_name(x$ptr))
    stop("otio_name: not an OTIO object", call. = FALSE)
}

#' @rdname otio_name
#' @export
otio_kind <- function(x) {
    stopifnot(inherits(x, "otio_track"))
    otio_get_track_kind(x$ptr)
}

#' Serialize / deserialize an OTIO timeline as JSON
#'
#' \code{otio_to_json()} renders a timeline to canonical OTIO JSON via the
#' library's own serializer; \code{otio_from_json()} parses it back into a live
#' timeline. The JSON is the standard \code{.otio} format (each object carries
#' its own \code{OTIO_SCHEMA}).
#'
#' @param timeline An \code{otio_timeline}.
#' @param json An OTIO JSON string.
#' @return \code{otio_to_json}: a JSON string. \code{otio_from_json}: an
#'   \code{otio_timeline}.
#' @examples
#' tl <- otio_timeline("demo")
#' js <- otio_to_json(tl)
#' identical(otio_name(otio_from_json(js)), "demo")
#' @export
otio_to_json <- function(timeline) {
    stopifnot(inherits(timeline, "otio_timeline"))
    otio_timeline_to_json(timeline$ptr)
}

#' @rdname otio_to_json
#' @export
otio_from_json <- function(json) {
    structure(list(ptr = otio_timeline_from_json(as.character(json))),
              class = "otio_timeline")
}

#' @export
print.otio_timeline <- function(x, ...) {
    tr <- otio_tracks(x)
    cat(sprintf("<otio_timeline \"%s\": %d track(s)>\n", otio_name(x), nrow(tr)))
    if (nrow(tr)) print(tr)
    invisible(x)
}

#' @export
print.otio_track <- function(x, ...) {
    cl <- otio_clips(x)
    cat(sprintf("<otio_track \"%s\" [%s]: %d child(ren)>\n",
                otio_name(x), otio_kind(x), nrow(cl)))
    invisible(x)
}

#' @export
print.otio_clip <- function(x, ...) {
    cat(sprintf("<otio_clip \"%s\">\n", otio_name(x)))
    invisible(x)
}
