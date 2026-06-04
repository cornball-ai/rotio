# The timeline model, backed by an OpenTimelineIO Timeline.
#
# An nle_timeline wraps an external pointer to a live OTIO Timeline (the single
# source of truth). Tracks, clips, gaps, and source ranges live in OTIO; fps,
# canvas, and sample rate are stored in the Timeline metadata so they survive
# serialization. `timeline$clips` / `timeline$tracks` materialise fresh data.frame views
# from the C++ side on each read; edits go through the verbs, which read the
# current state, apply the change, and rebuild the Timeline (gap model A: clip
# timeline position is encoded by OTIO Gaps, computed from tl_in).

`%||%` <- function(a, b) if (is.null(a)) b else a

#' Construct an empty timeline
#'
#' The timeline is nle.api's canonical S3 model, backed by an OpenTimelineIO
#' Timeline. Times are integer frame counts at \code{fps}.
#'
#' @param id Timeline id (becomes the OTIO Timeline name).
#' @param fps Frames per second (default 30). For non-integer rates pass a
#'   \code{list(num = 24000, den = 1001)}.
#' @param sample_rate Audio sample rate in Hz (default 48000).
#' @param canvas Length-2 numeric \code{c(width, height)}.
#' @return A \code{nle_timeline} S3 object wrapping a live OTIO Timeline.
#' @examples
#' timeline <- new_timeline(id = "demo", fps = 30, canvas = c(1080, 1080))
#' @export
new_timeline <- function(id = "untitled",
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
        numeric(0), numeric(0), numeric(0), numeric(0),   # clip times
        numeric(0))                                       # clip speed
    structure(list(ptr = ptr), class = "nle_timeline")
}

#' Is x an nle_timeline?
#' @param x Object to test.
#' @export
is_timeline <- function(x) inherits(x, "nle_timeline")

# Materialised views and config are read from the OTIO Timeline on access.
#' @export
`$.nle_timeline` <- function(x, name) {
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

#' Timeline frame rate as a single value (frames per second)
#' @param timeline An \code{nle_timeline}.
#' @export
timeline_fps <- function(timeline) {
    cf <- otio_timeline_config(timeline$ptr)
    cf[["fps_num"]] / cf[["fps_den"]]
}

#' Total timeline duration in frames (end of the last clip)
#' @param timeline An \code{nle_timeline}.
#' @export
timeline_duration_frames <- function(timeline) {
    cl <- timeline$clips
    if (nrow(cl) == 0L) return(0L)
    as.integer(max(cl$tl_out))
}

#' Concise human summary of a timeline
#' @param timeline An \code{nle_timeline}.
#' @export
timeline_summary <- function(timeline) {
    fps <- timeline_fps(timeline)
    dur_f <- timeline_duration_frames(timeline)
    tracks <- timeline$tracks
    clips <- timeline$clips
    cv <- timeline$canvas
    cat(sprintf("nle_timeline '%s'\n", timeline$id))
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
    invisible(timeline)
}

#' @export
print.nle_timeline <- function(x, ...) timeline_summary(x)

# ---- internal edit helpers ----------------------------------------------

# Current track table (id, kind) in track order, for rebuilding.
.seq_tracks_tbl <- function(timeline) {
    tr <- otio_timeline_tracks_df(timeline$ptr)
    data.frame(id = tr$name, kind = tr$kind, stringsAsFactors = FALSE)
}

# Rebuild the Timeline from edited track and clip tables; return a new
# nle_timeline. Tracks are given in order; clips are placed by tl_in.
.seq_rebuild <- function(timeline, tracks_tbl, clips_tbl) {
    cf <- otio_timeline_config(timeline$ptr)
    ptr <- otio_build_timeline(
        otio_get_timeline_name(timeline$ptr),
        cf[["fps_num"]], cf[["fps_den"]], cf[["canvas_w"]], cf[["canvas_h"]],
        cf[["sample_rate"]],
        as.character(tracks_tbl$id), as.character(tracks_tbl$kind),
        as.character(clips_tbl$track), as.character(clips_tbl$id),
        as.character(clips_tbl$asset),
        as.double(clips_tbl$tl_in), as.double(clips_tbl$tl_out),
        as.double(clips_tbl$source_in), as.double(clips_tbl$rate),
        as.double(clips_tbl$speed %||% rep(1, nrow(clips_tbl))))
    structure(list(ptr = ptr), class = "nle_timeline")
}

# Index of a clip by id in the materialised table, error if missing.
.clip_idx <- function(clips, clip_id) {
    i <- match(clip_id, clips$id)
    if (is.na(i)) stop(sprintf("no clip with id '%s'", clip_id), call. = FALSE)
    i
}

# Error if a track id does not exist.
.track_exists <- function(timeline, track_id) {
    if (!track_id %in% otio_timeline_tracks_df(timeline$ptr)$name) {
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

# Convert a time argument to integer frames at the timeline fps. Accepts an
# integer frame count, numeric seconds, or a rational_time / otio_time.
.to_frames_at_seq <- function(x, timeline) {
    fps <- timeline_fps(timeline)
    if (is_rational_time(x)) return(to_frames(x, as.integer(round(fps))))
    if (is_otio_time(x))     return(otio_to_frames(x, fps))
    if (is.numeric(x))       return(as.integer(round(x * fps)))
    stop(".to_frames_at_seq: cannot interpret value as time", call. = FALSE)
}
