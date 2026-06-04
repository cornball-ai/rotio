# The sequence model, backed by an OpenTimelineIO Timeline.
#
# An nle_sequence wraps an external pointer to a live OTIO Timeline (the single
# source of truth). Tracks, clips, gaps, and source ranges live in OTIO; fps,
# canvas, and sample rate are stored in the Timeline metadata so they survive
# serialization. `seq$clips` / `seq$tracks` materialise fresh data.frame views
# from the C++ side on each read; edits go through the verbs, which read the
# current state, apply the change, and rebuild the Timeline (gap model A: clip
# timeline position is encoded by OTIO Gaps, computed from tl_in).

`%||%` <- function(a, b) if (is.null(a)) b else a

#' Construct an empty sequence
#'
#' The sequence is nle.api's canonical S3 model, backed by an OpenTimelineIO
#' Timeline. Times are integer frame counts at \code{fps}.
#'
#' @param id Sequence id (becomes the OTIO Timeline name).
#' @param fps Frames per second (default 30). For non-integer rates pass a
#'   \code{list(num = 24000, den = 1001)}.
#' @param sample_rate Audio sample rate in Hz (default 48000).
#' @param canvas Length-2 numeric \code{c(width, height)}.
#' @return A \code{nle_sequence} S3 object wrapping a live OTIO Timeline.
#' @examples
#' seq <- new_sequence(id = "demo", fps = 30, canvas = c(1080, 1080))
#' @export
new_sequence <- function(id = "untitled",
                         fps = 30L,
                         sample_rate = 48000L,
                         canvas = c(1080L, 1080L)) {
    if (is.list(fps) && all(c("num", "den") %in% names(fps))) {
        fps_num <- as.double(fps$num); fps_den <- as.double(fps$den)
    } else {
        fps_num <- as.double(fps); fps_den <- 1
    }
    ptr <- otio_build_timeline(
        as.character(id), fps_num, fps_den,
        as.double(canvas[1]), as.double(canvas[2]), as.double(sample_rate),
        character(0), character(0),                       # tracks
        character(0), character(0), character(0),         # clip track/id/asset
        numeric(0), numeric(0), numeric(0), numeric(0))   # clip times
    structure(list(ptr = ptr), class = "nle_sequence")
}

#' Is x an nle_sequence?
#' @param x Object to test.
#' @export
is_sequence <- function(x) inherits(x, "nle_sequence")

# Materialised views and config are read from the OTIO Timeline on access.
#' @export
`$.nle_sequence` <- function(x, name) {
    p <- .subset2(x, "ptr")
    switch(name,
        ptr     = p,
        clips   = otio_timeline_clips_df(p),
        tracks  = .seq_tracks_view(p),
        config  = otio_timeline_config(p),
        id      = otio_get_timeline_name(p),
        fps     = { cf <- otio_timeline_config(p); cf[["fps_num"]] / cf[["fps_den"]] },
        canvas  = { cf <- otio_timeline_config(p)
                    list(width = cf[["canvas_w"]], height = cf[["canvas_h"]]) },
        .subset2(x, name))
}

# Public track view: id, idx, kind, n_clips.
.seq_tracks_view <- function(ptr) {
    tr <- otio_timeline_tracks_df(ptr)
    data.frame(id = tr$name, idx = tr$index + 1L, kind = tr$kind,
               n_clips = tr$n_children, stringsAsFactors = FALSE)
}

#' Sequence frame rate as a single value (frames per second)
#' @param seq An \code{nle_sequence}.
#' @export
seq_fps <- function(seq) {
    cf <- otio_timeline_config(seq$ptr)
    cf[["fps_num"]] / cf[["fps_den"]]
}

#' Total sequence duration in frames (end of the last clip)
#' @param seq An \code{nle_sequence}.
#' @export
seq_duration_frames <- function(seq) {
    cl <- seq$clips
    if (nrow(cl) == 0L) return(0L)
    as.integer(max(cl$tl_out))
}

#' Concise human summary of a sequence
#' @param seq An \code{nle_sequence}.
#' @export
sequence_summary <- function(seq) {
    fps <- seq_fps(seq)
    dur_f <- seq_duration_frames(seq)
    tracks <- seq$tracks
    clips <- seq$clips
    cv <- seq$canvas
    cat(sprintf("nle_sequence '%s'\n", seq$id))
    cat(sprintf("  canvas %gx%g @ %g fps, %d tracks, %d clips, dur %.2fs (%d frames)\n",
                cv$width, cv$height, fps, nrow(tracks), nrow(clips),
                dur_f / fps, dur_f))
    if (nrow(tracks) > 0L) {
        cat("  tracks:\n")
        for (i in seq_len(nrow(tracks))) {
            tr <- tracks[i, ]
            cat(sprintf("    %s [%s, idx=%d] %d clip(s)\n",
                        tr$id, tr$kind, tr$idx, tr$n_clips))
        }
    }
    if (nrow(clips) > 0L) {
        cat("  clips:\n")
        for (i in seq_len(nrow(clips))) {
            cl <- clips[i, ]
            cat(sprintf("    %s [%s on %s] tl %g-%g, src %g-%g\n",
                        cl$id, cl$kind, cl$track,
                        cl$tl_in, cl$tl_out, cl$source_in, cl$source_out))
        }
    }
    invisible(seq)
}

#' @export
print.nle_sequence <- function(x, ...) sequence_summary(x)

# ---- internal edit helpers ----------------------------------------------

# Current track table (id, kind) in track order, for rebuilding.
.seq_tracks_tbl <- function(seq) {
    tr <- otio_timeline_tracks_df(seq$ptr)
    data.frame(id = tr$name, kind = tr$kind, stringsAsFactors = FALSE)
}

# Rebuild the Timeline from edited track and clip tables; return a new
# nle_sequence. Tracks are given in order; clips are placed by tl_in.
.seq_rebuild <- function(seq, tracks_tbl, clips_tbl) {
    cf <- otio_timeline_config(seq$ptr)
    ptr <- otio_build_timeline(
        otio_get_timeline_name(seq$ptr),
        cf[["fps_num"]], cf[["fps_den"]], cf[["canvas_w"]], cf[["canvas_h"]],
        cf[["sample_rate"]],
        as.character(tracks_tbl$id), as.character(tracks_tbl$kind),
        as.character(clips_tbl$track), as.character(clips_tbl$id),
        as.character(clips_tbl$asset),
        as.double(clips_tbl$tl_in), as.double(clips_tbl$tl_out),
        as.double(clips_tbl$source_in), as.double(clips_tbl$rate))
    structure(list(ptr = ptr), class = "nle_sequence")
}

# Index of a clip by id in the materialised table, error if missing.
.clip_idx <- function(clips, clip_id) {
    i <- match(clip_id, clips$id)
    if (is.na(i)) stop(sprintf("no clip with id '%s'", clip_id), call. = FALSE)
    i
}

# Error if a track id does not exist.
.track_exists <- function(seq, track_id) {
    if (!track_id %in% otio_timeline_tracks_df(seq$ptr)$name) {
        stop(sprintf("no track with id '%s'", track_id), call. = FALSE)
    }
    invisible(TRUE)
}

# Unused clip id derived from a stem.
.new_clip_id <- function(clips, stem = "clip") {
    existing <- clips$id
    i <- 1L
    repeat {
        cand <- if (i == 1L) stem else sprintf("%s_%d", stem, i)
        if (!cand %in% existing) return(cand)
        i <- i + 1L
    }
}

# Convert a time argument to integer frames at the sequence fps. Accepts an
# integer frame count, numeric seconds, or a rational_time / otio_time.
.to_frames_at_seq <- function(x, seq) {
    fps <- seq_fps(seq)
    if (is_rational_time(x)) return(to_frames(x, as.integer(round(fps))))
    if (is_otio_time(x))     return(otio_to_frames(x, fps))
    if (is.numeric(x))       return(as.integer(round(x * fps)))
    stop(".to_frames_at_seq: cannot interpret value as time", call. = FALSE)
}
