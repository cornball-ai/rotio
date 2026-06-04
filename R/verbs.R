# Edit verbs: nle_timeline -> nle_timeline (pure functions).
#
# Each verb reads the current state from the OTIO Timeline, applies the change
# to the materialised clip/track table, and rebuilds the Timeline (gap model A).
# Rebuilding yields a fresh Timeline, so the verbs are naturally pure: the input
# timeline is untouched.
#
# Effect-dependent verbs (clip_speed, clip_transform, clip_crop, clip_set) are
# deferred to PR 4, when OTIO Effects / per-clip metadata are wrapped; they
# currently stop with a pointer to that work.

#' Add a track
#'
#' @param timeline An \code{nle_timeline}.
#' @param kind One of \code{"video"}, \code{"audio"}, \code{"image"},
#'   \code{"subtitle"}.
#' @param label Ignored for now (track labels return with metadata in PR 4).
#' @param id Explicit track id; auto-generated from \code{kind} if NULL.
#' @param idx Ignored for now; tracks append in order.
#' @return The updated timeline.
#' @examples
#' timeline <- new_timeline()
#' timeline <- track_add(timeline, "video")
#' nrow(timeline$tracks)
#' @export
track_add <- function(timeline, kind, label = NULL, id = NULL, idx = NULL) {
    kind <- match.arg(kind, c("video", "audio", "image", "subtitle"))
    tracks <- .seq_tracks_tbl(timeline)
    if (is.null(id)) {
        stem <- substr(kind, 1, 1)
        n <- sum(startsWith(tracks$id, stem)) + 1L
        id <- sprintf("%s%d", stem, n)
    }
    if (id %in% tracks$id) {
        stop(sprintf("track '%s' already exists", id), call. = FALSE)
    }
    tracks <- rbind(tracks, data.frame(id = id, kind = kind,
                                       stringsAsFactors = FALSE))
    .seq_rebuild(timeline, tracks, timeline$clips)
}

#' Add a clip to a track
#'
#' Time inputs accept integer frames at the timeline fps, numeric seconds, or a
#' \code{rational_time} / \code{otio_time}.
#'
#' @param timeline An \code{nle_timeline}.
#' @param track Target track id (must exist).
#' @param tl_in,tl_out Timeline in/out points.
#' @param asset Source path or media url.
#' @param kind Unused (clip kind follows its track).
#' @param source_in Source media in-point (default 0).
#' @param source_out Source media out-point; default keeps clip duration.
#' @param speed Must be 1 in this release; time-remap arrives in PR 4.
#' @param label,id Optional; \code{id} auto-generated if NULL.
#' @return The updated timeline.
#' @export
clip_add <- function(timeline, track, tl_in, tl_out, asset,
                     kind = NULL, source_in = 0L, source_out = NULL,
                     speed = 1.0, label = NULL, id = NULL) {
    .track_exists(timeline, track)
    if (!isTRUE(all.equal(speed, 1.0))) {
        stop("clip_add: speed != 1 (time-remap) lands in PR 4 with OTIO effects",
             call. = FALSE)
    }
    tl_in_f  <- .to_frames_at_seq(tl_in, timeline)
    tl_out_f <- .to_frames_at_seq(tl_out, timeline)
    if (tl_out_f <= tl_in_f) {
        stop("clip_add: tl_out must be strictly after tl_in", call. = FALSE)
    }
    src_in_f <- .to_frames_at_seq(source_in, timeline)
    if (!is.null(source_out)) {
        src_out_f <- .to_frames_at_seq(source_out, timeline)
        if (src_out_f - src_in_f != tl_out_f - tl_in_f) {
            stop("clip_add: source span must equal timeline span (speed != 1 is PR 4)",
                 call. = FALSE)
        }
    }
    clips <- timeline$clips
    tkind <- .seq_tracks_tbl(timeline)$kind[.seq_tracks_tbl(timeline)$id == track][1]
    id <- id %||% .new_clip_id(clips, stem = track)
    if (id %in% clips$id) stop(sprintf("clip '%s' already exists", id),
                               call. = FALSE)
    row <- data.frame(
        id = id, track = track, kind = tkind, asset = as.character(asset),
        tl_in = tl_in_f, tl_out = tl_out_f,
        source_in = src_in_f, source_out = src_in_f + (tl_out_f - tl_in_f),
        rate = timeline_fps(timeline), stringsAsFactors = FALSE)
    .seq_rebuild(timeline, .seq_tracks_tbl(timeline), rbind(clips, row))
}

#' Delete a clip
#' @param timeline An \code{nle_timeline}.
#' @param clip Clip id.
#' @export
clip_delete <- function(timeline, clip) {
    clips <- timeline$clips
    i <- .clip_idx(clips, clip)
    .seq_rebuild(timeline, .seq_tracks_tbl(timeline), clips[-i, , drop = FALSE])
}

#' Move a clip in time and/or to another track
#' @param timeline An \code{nle_timeline}.
#' @param clip Clip id.
#' @param tl_in New timeline in-point; NULL to keep.
#' @param track New track id (must exist); NULL to keep.
#' @export
clip_move <- function(timeline, clip, tl_in = NULL, track = NULL) {
    clips <- timeline$clips
    i <- .clip_idx(clips, clip)
    if (!is.null(track)) {
        .track_exists(timeline, track)
        clips$track[i] <- track
    }
    if (!is.null(tl_in)) {
        new_in <- .to_frames_at_seq(tl_in, timeline)
        span <- clips$tl_out[i] - clips$tl_in[i]
        clips$tl_in[i]  <- new_in
        clips$tl_out[i] <- new_in + span
    }
    .seq_rebuild(timeline, .seq_tracks_tbl(timeline), clips)
}

#' Trim a clip's visible range
#'
#' Moving \code{tl_in} (left edge) shifts the source in-point so the picture
#' stays put. Moving \code{tl_out} (right edge) changes the duration.
#'
#' @param timeline An \code{nle_timeline}.
#' @param clip Clip id.
#' @param tl_in,tl_out New edge times; NULL to keep.
#' @export
clip_trim <- function(timeline, clip, tl_in = NULL, tl_out = NULL) {
    clips <- timeline$clips
    i <- .clip_idx(clips, clip)
    cl <- clips[i, ]
    new_in  <- if (is.null(tl_in)) cl$tl_in else .to_frames_at_seq(tl_in, timeline)
    new_out <- if (is.null(tl_out)) cl$tl_out else .to_frames_at_seq(tl_out, timeline)
    if (new_out <= new_in) {
        stop("clip_trim: would leave non-positive duration", call. = FALSE)
    }
    new_src_in <- cl$source_in + (new_in - cl$tl_in)   # speed 1: 1:1 shift
    if (new_src_in < 0) {
        stop("clip_trim: would move source in-point before the source start",
             call. = FALSE)
    }
    clips$tl_in[i]      <- new_in
    clips$tl_out[i]     <- new_out
    clips$source_in[i]  <- new_src_in
    clips$source_out[i] <- new_src_in + (new_out - new_in)
    .seq_rebuild(timeline, .seq_tracks_tbl(timeline), clips)
}

#' Split a clip at a timeline frame
#' @param timeline An \code{nle_timeline}.
#' @param clip Clip id.
#' @param at Timeline time at which to cut.
#' @export
clip_split <- function(timeline, clip, at) {
    clips <- timeline$clips
    i <- .clip_idx(clips, clip)
    cl <- clips[i, ]
    at_f <- .to_frames_at_seq(at, timeline)
    if (at_f <= cl$tl_in || at_f >= cl$tl_out) {
        stop("clip_split: split point must fall strictly inside the clip",
             call. = FALSE)
    }
    left_dur <- at_f - cl$tl_in
    clips$tl_out[i]     <- at_f
    clips$source_out[i] <- cl$source_in + left_dur
    right <- cl
    right$id         <- .new_clip_id(clips, stem = paste0(cl$id, "_split"))
    right$tl_in      <- at_f
    right$tl_out     <- cl$tl_out
    right$source_in  <- cl$source_in + left_dur
    right$source_out <- cl$source_out
    .seq_rebuild(timeline, .seq_tracks_tbl(timeline), rbind(clips, right))
}

# ---- deferred to PR 4 (OTIO effects / per-clip metadata) -----------------

.pr4 <- function(verb) {
    stop(sprintf("%s migrates to OTIO effects in PR 4; not available yet", verb),
         call. = FALSE)
}

#' @rdname clip_add
#' @param ... Deferred-verb arguments (see PR 4).
#' @export
clip_speed <- function(timeline, clip, speed) .pr4("clip_speed")

#' @rdname clip_add
#' @export
clip_transform <- function(timeline, clip, ...) .pr4("clip_transform")

#' @rdname clip_add
#' @export
clip_crop <- function(timeline, clip, ...) .pr4("clip_crop")

#' @rdname clip_add
#' @export
clip_set <- function(timeline, clip, ...) .pr4("clip_set")
