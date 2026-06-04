# Additional edit verbs: timeline -> timeline (pure functions).
#
# Like the core verbs, these read the current state, edit the materialised
# track/clip table, and rebuild the OTIO Timeline. They need no new C++ — they
# are structural operations expressible in the gap model. Effect-dependent and
# new-OTIO-object verbs (transitions, markers, time-remap) are elsewhere / later.

#' Delete a track and all its clips
#'
#' @param timeline An \code{nle_timeline}.
#' @param track Track id to remove (must exist).
#' @return The updated timeline.
#' @examples
#' tl <- new_timeline()
#' tl <- track_add(tl, "video", id = "v1")
#' tl <- track_delete(tl, "v1")
#' @export
track_delete <- function(timeline, track) {
    .track_exists(timeline, track)
    tracks <- .seq_tracks_tbl(timeline)
    clips <- timeline$clips
    tracks <- tracks[tracks$id != track, , drop = FALSE]
    clips <- clips[clips$track != track, , drop = FALSE]
    .seq_rebuild(timeline, tracks, clips)
}

#' Move a track to a new position (compositing order)
#'
#' Track order is compositing order: position 1 is the first track in the
#' stack. \code{to} is the 1-based destination index.
#'
#' @param timeline An \code{nle_timeline}.
#' @param track Track id to move (must exist).
#' @param to New 1-based position among the tracks.
#' @return The updated timeline.
#' @export
track_move <- function(timeline, track, to) {
    .track_exists(timeline, track)
    tracks <- .seq_tracks_tbl(timeline)
    n <- nrow(tracks)
    to <- max(1L, min(as.integer(to), n))
    from <- match(track, tracks$id)
    order <- seq_len(n)[-from]
    order <- append(order, from, after = to - 1L)
    .seq_rebuild(timeline, tracks[order, , drop = FALSE], timeline$clips)
}

#' Ripple-delete a clip (delete and close the gap)
#'
#' Removes the clip and pulls every later clip on the same track earlier by the
#' deleted clip's duration, so no gap is left. Contrast \code{clip_delete},
#' which leaves a gap.
#'
#' @param timeline An \code{nle_timeline}.
#' @param clip Clip id.
#' @return The updated timeline.
#' @export
ripple_delete <- function(timeline, clip) {
    clips <- timeline$clips
    i <- .clip_idx(clips, clip)
    cl <- clips[i, ]
    dur <- cl$tl_out - cl$tl_in
    later <- clips$track == cl$track & clips$tl_in >= cl$tl_out
    clips$tl_in[later]  <- clips$tl_in[later]  - dur
    clips$tl_out[later] <- clips$tl_out[later] - dur
    clips <- clips[-i, , drop = FALSE]
    .seq_rebuild(timeline, .seq_tracks_tbl(timeline), clips)
}

#' Slip a clip's source content without moving it
#'
#' Shifts the clip's source in/out points by \code{by} while leaving its
#' timeline position and duration unchanged — the clip shows different source
#' content in the same slot. \code{by} accepts frames / seconds /
#' \code{rational_time}.
#'
#' @param timeline An \code{nle_timeline}.
#' @param clip Clip id.
#' @param by Amount to shift the source in-point (positive = later in source).
#' @return The updated timeline.
#' @export
clip_slip <- function(timeline, clip, by) {
    clips <- timeline$clips
    i <- .clip_idx(clips, clip)
    by_f <- .to_frames_at_seq(by, timeline)
    new_src_in <- clips$source_in[i] + by_f
    if (new_src_in < 0) {
        stop("clip_slip: would move source in-point before the source start",
             call. = FALSE)
    }
    span <- clips$source_out[i] - clips$source_in[i]
    clips$source_in[i]  <- new_src_in
    clips$source_out[i] <- new_src_in + span
    .seq_rebuild(timeline, .seq_tracks_tbl(timeline), clips)
}

#' Duplicate a clip
#'
#' Copies a clip (same source range) to a new timeline position. By default the
#' copy lands immediately after the original on the same track with an
#' auto-generated id.
#'
#' @param timeline An \code{nle_timeline}.
#' @param clip Clip id to copy.
#' @param tl_in New timeline in-point; NULL places it right after the original.
#' @param track Destination track id; NULL keeps the original's track.
#' @param id New clip id; auto-generated if NULL.
#' @return The updated timeline.
#' @export
clip_duplicate <- function(timeline, clip, tl_in = NULL, track = NULL,
                           id = NULL) {
    clips <- timeline$clips
    i <- .clip_idx(clips, clip)
    cl <- clips[i, ]
    if (!is.null(track)) .track_exists(timeline, track)
    dest_track <- track %||% cl$track
    new_in <- if (is.null(tl_in)) cl$tl_out else .to_frames_at_seq(tl_in, timeline)
    dur <- cl$tl_out - cl$tl_in
    new_id <- id %||% .new_clip_id(clips, stem = paste0(cl$id, "_copy"))
    if (new_id %in% clips$id) {
        stop(sprintf("clip_duplicate: id '%s' already exists", new_id),
             call. = FALSE)
    }
    row <- cl
    row$id <- new_id
    row$track <- dest_track
    row$tl_in <- new_in
    row$tl_out <- new_in + dur
    row$source_out <- row$source_in + dur
    .seq_rebuild(timeline, .seq_tracks_tbl(timeline), rbind(clips, row))
}
