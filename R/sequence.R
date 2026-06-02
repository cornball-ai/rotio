# The neutral sequence model: tracks + clips + timebase + canvas + meta.
#
# Ported and refactored from kerNLE/R/timeline.R:
#   - asset-cache fields (asset_id, source_row, assets list) removed; those
#     are cornductor's concern.
#   - times stored as integer frame counts at the sequence's fps; rational
#     {num, den} appears only at the JSON wire boundary.
#   - clip transform stored canonically (top-left + Y down); the verb layer
#     accepts cartesian / center via a `coord` argument.

`%||%` <- function(a, b) if (is.null(a)) b else a

#' Construct an empty sequence
#'
#' The sequence is nle.api's canonical S3 model: tracks, clips, timebase
#' (rational fps + sample rate), canvas (output dimensions), meta (title,
#' notes), and extensions (driver-specific lossless reservoirs).
#'
#' Times on \code{clips} are integer frame counts at \code{timebase$fps}.
#' The JSON wire format expands each to a rational \code{\{num, den\}};
#' R-level math stays integer.
#'
#' @param id Sequence id (string).
#' @param fps Integer frames per second (default 30). For non-integer
#'   rates (23.976 etc.) pass a \code{\link{rational_time}}-style list
#'   \code{list(num = 24000, den = 1001)}.
#' @param sample_rate Audio sample rate in Hz (default 48000).
#' @param canvas Length-2 integer vector \code{c(width, height)}.
#' @param meta Optional named list of metadata (title, notes, ...).
#' @return A \code{nle_sequence} S3 object.
#' @examples
#' seq <- new_sequence(id = "demo", fps = 30, canvas = c(1080, 1080))
#' @export
new_sequence <- function(id = "untitled",
                         fps = 30L,
                         sample_rate = 48000L,
                         canvas = c(1080L, 1080L),
                         meta = list()) {
    if (is.list(fps) && all(c("num", "den") %in% names(fps))) {
        timebase <- list(fps_num = as.integer(fps$num),
                         fps_den = as.integer(fps$den),
                         sample_rate = as.integer(sample_rate))
    } else {
        timebase <- list(fps_num = as.integer(fps),
                         fps_den = 1L,
                         sample_rate = as.integer(sample_rate))
    }
    structure(
        list(
            schema  = "cornball.sequence.v1",
            id      = id,
            meta    = meta,
            timebase = timebase,
            canvas  = list(width = as.integer(canvas[1]),
                           height = as.integer(canvas[2])),
            tracks  = empty_tracks(),
            clips   = empty_clips(),
            extensions = list()
        ),
        class = "nle_sequence"
    )
}

#' @rdname new_sequence
#' @export
empty_tracks <- function() {
    data.frame(
        id    = character(0),
        idx   = integer(0),
        kind  = character(0),     # video | audio | image | subtitle
        label = character(0),
        stringsAsFactors = FALSE
    )
}

#' @rdname new_sequence
#' @export
empty_clips <- function() {
    data.frame(
        id          = character(0),
        track       = character(0),
        kind        = character(0),     # video | audio | image | subtitle
        asset       = character(0),     # path or cornductor asset id
        tl_in       = integer(0),       # frames at sequence$timebase$fps
        tl_out      = integer(0),
        source_in   = integer(0),
        source_out  = integer(0),
        speed       = numeric(0),
        pos_x       = numeric(0),       # canonical: top-left of displayed bbox
        pos_y       = numeric(0),
        scale_x     = numeric(0),
        scale_y     = numeric(0),
        rotation_deg = numeric(0),
        crop_left   = numeric(0),       # normalized 0-1
        crop_right  = numeric(0),
        crop_top    = numeric(0),
        crop_bottom = numeric(0),
        blend       = character(0),     # alpha_over | normal | add | ...
        opacity     = numeric(0),
        mute        = logical(0),
        label       = character(0),
        notes       = I(list()),        # list-column of character vectors
        stringsAsFactors = FALSE
    )
}

#' Is x an nle_sequence?
#' @param x Object to test.
#' @export
is_sequence <- function(x) inherits(x, "nle_sequence")

#' Sequence frame rate as a single value (frames per second)
#' @param seq An \code{nle_sequence}.
#' @export
seq_fps <- function(seq) {
    seq$timebase$fps_num / seq$timebase$fps_den
}

#' Total sequence duration in frames (end of the last clip)
#' @param seq An \code{nle_sequence}.
#' @export
seq_duration_frames <- function(seq) {
    if (nrow(seq$clips) == 0L) return(0L)
    as.integer(max(seq$clips$tl_out))
}

#' Concise human summary of a sequence
#'
#' Prints a one-line per track + per clip overview. Useful for LLM agents
#' that need to "look at" a sequence without parsing the JSON.
#'
#' @param seq An \code{nle_sequence}.
#' @export
sequence_summary <- function(seq) {
    fps <- seq_fps(seq)
    dur_f <- seq_duration_frames(seq)
    cat(sprintf("nle_sequence '%s'\n", seq$id))
    cat(sprintf("  canvas %dx%d @ %g fps, %d tracks, %d clips, dur %.2fs (%d frames)\n",
                seq$canvas$width, seq$canvas$height, fps,
                nrow(seq$tracks), nrow(seq$clips),
                dur_f / fps, dur_f))
    if (nrow(seq$tracks) > 0L) {
        cat("  tracks:\n")
        for (i in seq_len(nrow(seq$tracks))) {
            tr <- seq$tracks[i, ]
            cat(sprintf("    %s [%s, idx=%d] %s\n", tr$id, tr$kind, tr$idx,
                        tr$label %||% ""))
        }
    }
    if (nrow(seq$clips) > 0L) {
        cat("  clips:\n")
        for (i in seq_len(nrow(seq$clips))) {
            cl <- seq$clips[i, ]
            cat(sprintf("    %s [%s on %s] tl %d-%d, src %d-%d, speed %.3fx\n",
                        cl$id, cl$kind, cl$track,
                        cl$tl_in, cl$tl_out, cl$source_in, cl$source_out,
                        cl$speed))
        }
    }
    invisible(seq)
}

#' @export
print.nle_sequence <- function(x, ...) {
    sequence_summary(x)
}

# Internal: find a clip row by id, error if missing
.clip_idx <- function(seq, clip_id) {
    i <- match(clip_id, seq$clips$id)
    if (is.na(i)) {
        stop(sprintf("no clip with id '%s'", clip_id), call. = FALSE)
    }
    i
}

# Internal: find a track by id, error if missing
.track_exists <- function(seq, track_id) {
    if (!track_id %in% seq$tracks$id) {
        stop(sprintf("no track with id '%s'", track_id), call. = FALSE)
    }
    invisible(TRUE)
}

# Internal: unused clip id derived from a stem
.new_clip_id <- function(seq, stem = "clip") {
    existing <- seq$clips$id
    i <- 1L
    repeat {
        cand <- if (i == 1L) stem else sprintf("%s_%d", stem, i)
        if (!cand %in% existing) return(cand)
        i <- i + 1L
    }
}

# Internal: convert a time-typed argument to integer frames at the
# sequence's fps. Accepts:
#   - integer frame count (returned as-is)
#   - numeric seconds (converted via fps)
#   - rational_time (converted via to_frames)
.to_frames_at_seq <- function(x, seq) {
    fps <- seq_fps(seq)
    if (is_rational_time(x)) return(to_frames(x, as.integer(round(fps))))
    if (is.numeric(x))       return(as.integer(round(x * fps)))
    stop(".to_frames_at_seq: cannot interpret value as time", call. = FALSE)
}
