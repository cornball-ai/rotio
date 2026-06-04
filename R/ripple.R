#' Ripple-shift clips after a timeline frame
#'
#' Adds \code{delta} to the \code{tl_in} and \code{tl_out} of every clip
#' whose \code{tl_in} is at-or-after (or strictly after, see
#' \code{inclusive}) the given \code{after} frame. Source in/out points
#' are NOT touched: clips keep showing the same source content, just at
#' a shifted timeline position.
#'
#' This is the canonical "close a gap" / "open a gap" operation. Pass
#' a negative \code{delta} to pull strips earlier (close); positive to
#' push them later (open).
#'
#' Both \code{after} and \code{delta} accept any time form: integer
#' frames at the timeline fps, numeric seconds, or a
#' \code{\link{rational_time}}.
#'
#' @param timeline An \code{nle_timeline}.
#' @param after Timeline boundary; clips at or after this frame shift.
#' @param delta Shift amount in frames at the timeline fps (or seconds /
#'   \code{rational_time} — converted at the boundary).
#' @param inclusive When \code{TRUE} (the default), clips with
#'   \code{tl_in == after} shift too. Set \code{FALSE} to keep clips
#'   that start exactly at the boundary in place (useful when an edit
#'   anchors at \code{after}).
#'
#' @return The updated timeline.
#' @examples
#' timeline <- new_timeline(fps = 30L)
#' timeline <- track_add(timeline, "video", id = "v1")
#' timeline <- clip_add(timeline, "v1", tl_in = rational_time(0, 30),
#'                 tl_out = rational_time(90, 30), asset = "a.mp4", id = "a")
#' timeline <- clip_add(timeline, "v1", tl_in = rational_time(90, 30),
#'                 tl_out = rational_time(180, 30), asset = "b.mp4", id = "b")
#' timeline <- shift_after(timeline, after = rational_time(90, 30), delta = -30)
#' timeline$clips$tl_in
#' @export
shift_after <- function(timeline, after, delta, inclusive = TRUE) {
    if (!is_timeline(timeline)) {
        stop("shift_after: timeline must be an nle_timeline", call. = FALSE)
    }
    after_f <- .to_frames_at_seq(after, timeline)
    delta_f <- .to_frames_at_seq(delta, timeline)
    clips <- timeline$clips
    if (delta_f == 0L || nrow(clips) == 0L) return(timeline)

    mask <- if (isTRUE(inclusive)) clips$tl_in >= after_f
            else                   clips$tl_in >  after_f
    if (!any(mask)) return(timeline)

    clips$tl_in[mask]  <- clips$tl_in[mask]  + delta_f
    clips$tl_out[mask] <- clips$tl_out[mask] + delta_f
    if (any(clips$tl_in < 0)) {
        stop("shift_after: delta would push a clip before frame 0", call. = FALSE)
    }
    .seq_rebuild(timeline, .seq_tracks_tbl(timeline), clips)
}
