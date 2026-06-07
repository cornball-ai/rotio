# Phase 4: the composition coordinate model. Positions are computed from child
# order + durations (gaps included); ranges, track filters, flatten, and trims.
# Validated against RcppOTIO. Frame math assumes a uniform rate (the common case).

# Rate of the first clip/gap duration found in a list of tracks (else 24).
.first_rate <- function(tracks) {
    for (trk in tracks) {
        for (ch in children(trk)) {
            tr <- trimmed_range(ch)
            if (!is.null(tr)) {
                return(tr$duration$rate)
            }
        }
    }
    24
}

#' Trimmed range of an item
#'
#' The item's \code{source_range} if set, else (for a clip) the active media
#' reference's available range.
#'
#' @param x An item (clip, gap).
#' @return A \code{\link{TimeRange}}.
#' @export
trimmed_range <- function(x) {
    if (!is.null(x$source_range)) {
        return(x$source_range)
    }
    available_range(x)
}

#' Range of an item within its parent composition
#'
#' Computed from the durations of the preceding siblings (gaps included). The
#' duration is the item's trimmed duration.
#'
#' @param x An item with a parent.
#' @return A \code{\link{TimeRange}} in the parent's coordinates.
#' @export
range_in_parent <- function(x) {
    p <- parent(x)
    if (is.null(p) || !.is_container(p)) {
        stop("range_in_parent: item has no parent composition", call. = FALSE)
    }
    # Stack children are parallel: each starts at 0.
    if (!inherits(p, "Track")) {
        dur <- trimmed_range(x)$duration
        return(TimeRange(RationalTime(0, dur$rate), dur))
    }
    # Track: cumulative position; transitions do not advance the timeline.
    cum <- NULL
    for (ch in p$children) {
        if (identical(ch, x)) {
            break
        }
        if (inherits(ch, "Transition")) {
            next
        }
        d <- trimmed_range(ch)$duration
        if (is.null(cum)) {
            cum <- RationalTime(0, d$rate)
        }
        cum <- .rt_plus(cum, d)
    }
    if (inherits(x, "Transition")) {
        # Centred on the cut: [cut - in_offset, in_offset + out_offset).
        if (is.null(cum)) {
            cut <- RationalTime(0, x$in_offset$rate)
        } else {
            cut <- cum
        }
        return(TimeRange(.rt_minus(cut, x$in_offset),
                         .rt_plus(x$in_offset, x$out_offset)))
    }
    dur <- trimmed_range(x)$duration
    if (is.null(cum)) {
        start <- RationalTime(0, dur$rate)
    } else {
        start <- cum
    }
    TimeRange(start, dur)
}

#' Range of an item within its parent, trimmed by the parent's source range
#' @param x An item with a parent.
#' @return A \code{\link{TimeRange}}.
#' @export
trimmed_range_in_parent <- function(x) {
    ri <- range_in_parent(x)
    p <- parent(x)
    psr <- p$source_range
    if (is.null(psr)) {
        return(ri)
    }
    # opentime trim_child_range: no overlap (error) when the parent source range
    # is entirely past or before the child, using >= / <= so exact boundary
    # contact also counts as no overlap. Otherwise clamp, keeping parent coords.
    ri_end <- end_time_exclusive(ri)
    psr_end <- end_time_exclusive(psr)
    past_end <- !.rt_lt(psr$start_time, ri_end) # psr.start >= ri.end_exclusive
    before_start <- !.rt_lt(ri$start_time, psr_end) # psr.end_exclusive <= ri.start
    if (past_end || before_start) {
        stop("trimmed_range_in_parent: child falls outside the parent source range",
             call. = FALSE)
    }
    range_from_start_end_time(.rt_max(psr$start_time, ri$start_time),
                              .rt_min(ri_end, psr_end))
}

#' Visible range of an item (including adjacent transitions)
#' @param x An item with a parent.
#' @return A \code{\link{TimeRange}}.
#' @export
visible_range <- function(x) {
    vr <- trimmed_range(x)
    p <- parent(x)
    if (is.null(p)) {
        return(vr)
    }
    i <- index_of_child(p, x)
    kids <- p$children
    start <- vr$start_time
    dur <- vr$duration
    if (i > 1L && inherits(kids[[i - 1L]], "Transition")) {
        start <- .rt_minus(start, kids[[i - 1L]]$in_offset)
        dur <- .rt_plus(dur, kids[[i - 1L]]$in_offset)
    }
    if (i < length(kids) && inherits(kids[[i + 1L]], "Transition")) {
        dur <- .rt_plus(dur, kids[[i + 1L]]$out_offset)
    }
    TimeRange(start, dur)
}

#' Video / audio tracks of a timeline
#' @param x A \code{\link{Timeline}}.
#' @return A list of \code{\link{Track}}s of the matching kind.
#' @export
video_tracks <- function(x) {
    Filter(function(t) identical(kind(t), "Video"), children(tracks(x)))
}

#' @rdname video_tracks
#' @export
audio_tracks <- function(x) {
    Filter(function(t) identical(kind(t), "Audio"), children(tracks(x)))
}

#' Global start time of a timeline
#' @param x A \code{\link{Timeline}}.
#' @param value A \code{\link{RationalTime}} or \code{NULL}.
#' @export
global_start_time <- function(x) x$global_start_time

#' @rdname global_start_time
#' @export
`global_start_time<-` <- function(x, value) {
    x$global_start_time <- value
    x
}

#' Are two OTIO objects equivalent?
#'
#' Structural equality, compared via canonical OTIO JSON.
#'
#' @param x,other OTIO objects.
#' @export
is_equivalent_to <- function(x, other) {
    is_otio(other) && identical(to_json_string(x), to_json_string(other))
}

#' Is an item visible?
#'
#' A Gap is never visible; a Transition always is; any other item is visible
#' when enabled (matching OTIO).
#'
#' @param x An item.
#' @export
visible <- function(x) {
    if (inherits(x, "Gap")) {
        return(FALSE)
    }
    if (inherits(x, "Transition")) {
        return(TRUE)
    }
    isTRUE(x$enabled)
}

#' Does an item overlap its neighbours?
#'
#' Only transitions overlap (they span a cut); everything else returns
#' \code{FALSE}.
#'
#' @param x An item.
#' @export
overlapping <- function(x) inherits(x, "Transition")

#' Trim a track to a time range
#'
#' Returns a new track containing each child trimmed to the portion that falls
#' within \code{trim_range} (in track coordinates); children fully outside are
#' dropped.
#'
#' @param in_track A \code{\link{Track}}.
#' @param trim_range A \code{\link{TimeRange}} in track coordinates.
#' @return A new \code{\link{Track}}.
#' @export
track_trimmed_to_range <- function(in_track, trim_range) {
    # Work in seconds so the child source rate is honoured (no truncation).
    ts <- to_seconds(trim_range$start_time)
    te <- to_seconds(end_time_exclusive(trim_range))
    out <- Track(in_track$name, kind = in_track$kind %||% "Video")
    for (ch in children(in_track)) {
        rip <- range_in_parent(ch)
        if (inherits(ch, "Transition")) {
            # Mirror OTIO trackAlgorithm.cpp: drop when clear, keep when fully
            # contained, error when the window cuts the transition.
            if (!intersects(trim_range, rip)) {
                next
            }
            if (contains(trim_range, rip)) {
                append_child(out, clone(ch))
                next
            }
            stop("Cannot trim in the middle of a transition", call. = FALSE)
        }
        cs <- to_seconds(rip$start_time)
        ce <- to_seconds(end_time_exclusive(rip))
        if (ce <= ts || cs >= te) {
            next
        }
        ostart <- max(cs, ts)
        oend <- min(ce, te)
        left_s <- ostart - cs # seconds trimmed off the front
        dur_s <- oend - ostart
        sr <- trimmed_range(ch)
        srate <- sr$start_time$rate
        nc <- clone(ch)
        source_range(nc) <- TimeRange(
                                      RationalTime(sr$start_time$value + left_s * srate, srate),
                                      RationalTime(dur_s * sr$duration$rate, sr$duration$rate))
        append_child(out, nc)
    }
    out
}

# An item shows lower tracks through it: a Gap, or a disabled (invisible) item.
.is_hole <- function(ch) {
    inherits(ch, "Gap") || (!inherits(ch, "Transition") && !isTRUE(ch$enabled))
}

# Content of `lower` over the frame span [s, e), padded with a trailing gap if
# the lower track runs out before the span ends.
.lower_segment <- function(lower, s, e, rate) {
    width <- e - s
    tt <- track_trimmed_to_range(lower,
                                 TimeRange(RationalTime(s, rate), RationalTime(width, rate)))
    items <- lapply(children(tt), clone)
    covered <- 0L
    for (it in items) {
        if (inherits(it, "Transition")) {
            next
        }
        covered <- covered + to_frames(trimmed_range(it)$duration, rate)
    }
    if (covered < width) {
        items <- c(items, list(Gap(RationalTime(width - covered, rate))))
    }
    items
}

# Replace each hole in `flat` with the corresponding content from `lower`.
.fill_holes <- function(flat, lower, rate) {
    res <- list()
    pos <- 0L
    for (ch in flat) {
        if (inherits(ch, "Transition")) {
            res[[length(res) + 1L]] <- ch
            next
        }
        d <- to_frames(trimmed_range(ch)$duration, rate)
        if (.is_hole(ch)) {
            res <- c(res, .lower_segment(lower, pos, pos + d, rate))
        } else {
            res[[length(res) + 1L]] <- ch
        }
        pos <- pos + d
    }
    res
}

#' Flatten a stack of tracks into a single track
#'
#' Composites top-down: starts from the topmost track and fills its holes (gaps
#' and disabled items) with content from the tracks below, recursing downward.
#' Transitions are preserved; a lower transition cut by a hole boundary errors
#' with "Cannot trim in the middle of a transition" (matching OTIO).
#'
#' @param x A \code{\link{Stack}} or a list of \code{\link{Track}}s
#'   (bottom-to-top).
#' @return A flattened \code{\link{Track}}.
#' @export
flatten_stack <- function(x) {
    if (inherits(x, "Stack")) {
        # opentime drops disabled tracks only for the Stack overload, not for a
        # plain list of tracks.
        tracks <- Filter(function(t) isTRUE(t$enabled), children(x))
    } else {
        tracks <- x
    }
    out <- Track("Flattened")
    if (length(tracks) == 0L) {
        return(out)
    }
    rate <- .first_rate(tracks)
    # Normalize lengths (OTIO _normalize_tracks_lengths): a shorter top track is
    # padded so the longer tracks below show through past its end.
    maxf <- max(vapply(tracks,
                       function(t) to_frames(available_range(t)$duration, rate), 0))
    ordered <- rev(tracks) # topmost first
    flat <- lapply(children(ordered[[1L]]), clone)
    flatf <- sum(vapply(flat, function(c) {
        if (inherits(c, "Transition")) 0L else to_frames(trimmed_range(c)$duration,
            rate)
    }, 0L))
    if (flatf < maxf) {
        flat <- c(flat, list(Gap(RationalTime(maxf - flatf, rate))))
    }
    for (k in seq_along(ordered)[-1L]) {
        flat <- .fill_holes(flat, ordered[[k]], rate)
    }
    for (ch in flat) {
        append_child(out, ch)
    }
    out
}

