# Phase 5: OTIO edit algorithms, ported from
# OpenTimelineIO/src/opentimelineio/algo/editAlgorithm.cpp and validated against
# rotio. These mutate the composition/item in place (reference semantics) like
# the C++ void functions. Indices here are 1-based (R) vs the source's 0-based.

# opentime's epsilon for "is this duration effectively zero" checks.
.EDIT_EPS <- 5.82077e-11
.is_zero <- function(rt) abs(rt$value) <= .EDIT_EPS
.rt_neg <- function(rt) RationalTime(-rt$value, rt$rate)

# available_range() of an item, or NULL when none is set (the C++ treats a
# zero/absent available range as "no clamp").
.avail_or_null <- function(item) {
    tryCatch(available_range(item), error = function(e) NULL)
}
.has_avail <- function(ar) !is.null(ar) && !.is_zero(ar$duration)

#' Slip an item's source range
#'
#' Shifts the item's \code{source_range} start by \code{delta} without changing
#' its duration or any surrounding item; clamps to the media available range when
#' present. Mutates \code{item} in place.
#'
#' @param item An item (usually a clip).
#' @param delta A \code{\link{RationalTime}} to slip by.
#' @return \code{item}, invisibly.
#' @export
slip <- function(item, delta) {
    range <- trimmed_range(item)
    start_time <- .rt_plus(range$start_time, delta)
    ar <- .avail_or_null(item)
    if (.has_avail(ar)) {
        if (.rt_lt(start_time, ar$start_time)) {
            start_time <- ar$start_time
        } else if (.rt_lt(end_time_exclusive(ar),
                          .rt_plus(start_time, range$duration))) {
            end_diff <- .rt_minus(.rt_plus(start_time, range$duration),
                                  end_time_exclusive(ar))
            start_time <- .rt_minus(start_time, end_diff)
        }
    }
    source_range(item) <- TimeRange(start_time, range$duration)
    invisible(item)
}

#' Ripple an item's source range
#'
#' Adjusts the item's \code{source_range} start by \code{delta_in} and exclusive
#' end by \code{delta_out} without moving any other item. Mutates in place.
#'
#' @param item An item (usually a clip).
#' @param delta_in,delta_out \code{\link{RationalTime}} adjustments to the start
#'   and exclusive end.
#' @return \code{item}, invisibly.
#' @export
ripple <- function(item, delta_in, delta_out) {
    range <- trimmed_range(item)
    start_time <- range$start_time
    ete <- end_time_exclusive(range)
    if (delta_in$value != 0) {
        in_offset <- delta_in
        if (.rt_lt(delta_in, start_time)) {
            in_offset <- .rt_neg(start_time)
        } else if (.rt_lt(ete, .rt_plus(start_time, delta_in))) {
            in_offset <- .rt_minus(delta_in, ete)
        }
        start_time <- .rt_plus(start_time, in_offset)
    }
    if (delta_out$value != 0) {
        out_offset <- delta_out
        if (delta_out$value > 0) {
            ar <- .avail_or_null(item)
            if (.has_avail(ar) &&
                .rt_lt(ar$duration, .rt_plus(range$duration, delta_out))) {
                out_offset <- .rt_minus(ar$duration, range$duration)
            }
        }
        ete <- .rt_plus(ete, out_offset)
    }
    source_range(item) <- range_from_start_end_time(start_time, ete)
    invisible(item)
}

#' Slide an item, adjusting the previous item's duration
#'
#' Moves the item's start by \code{delta} by changing the previous item's
#' duration; the item's own source range is unchanged. No-op for the first item.
#' Mutates in place.
#'
#' @param item An item (usually a clip).
#' @param delta A \code{\link{RationalTime}} to slide by.
#' @return \code{item}, invisibly.
#' @export
slide <- function(item, delta) {
    comp <- parent(item)
    if (is.null(comp)) {
        return(invisible(item))
    }
    index <- index_of_child(comp, item)
    if (is.na(index) || index <= 1L || delta$value == 0) {
        return(invisible(item))
    }
    kids <- children(comp)
    previous <- kids[[index - 1L]]
    range <- trimmed_range(previous)
    offset <- delta
    if (delta$value < 0) {
        if (!.rt_lt(.rt_neg(delta), range$duration)) {
            return(invisible(item)) # range.duration <= -delta
        }
    } else {
        ar <- .avail_or_null(previous)
        if (.has_avail(ar) &&
            .rt_lt(ar$duration, .rt_plus(range$duration, delta))) {
            offset <- .rt_minus(ar$duration, range$duration)
        }
    }
    source_range(previous) <- TimeRange(range$start_time,
                                        .rt_plus(range$duration, offset))
    invisible(item)
}

#' Trim an item, filling the freed time with gap
#'
#' Adjusts the item's start by \code{delta_in} (also extending the previous
#' item) and its exclusive end by \code{delta_out}, filling now-empty time with a
#' gap (or \code{fill_template}); an adjacent gap is grown instead. Mutates in
#' place.
#'
#' @param item An item (usually a clip).
#' @param delta_in,delta_out \code{\link{RationalTime}} adjustments.
#' @param fill_template Optional item to fill freed time with (default a gap).
#' @return \code{item}, invisibly.
#' @export
trim <- function(item, delta_in, delta_out, fill_template = NULL) {
    comp <- parent(item)
    if (is.null(comp)) {
        stop("trim: item has no parent", call. = FALSE)
    }
    kids <- children(comp)
    index <- index_of_child(comp, item)
    if (is.na(index)) {
        stop("trim: item is not a child of its parent", call. = FALSE)
    }
    range <- trimmed_range(item)
    start_time <- range$start_time
    ete <- end_time_exclusive(range)
    if (delta_in$value != 0) {
        start_time <- .rt_plus(start_time, delta_in)
        if (index > 1L) {
            previous <- kids[[index - 1L]]
            prev_range <- trimmed_range(previous)
            source_range(previous) <- TimeRange(prev_range$start_time,
                .rt_plus(prev_range$duration, delta_in))
        }
    }
    if (delta_out$value != 0) {
        next_index <- index + 1L
        if (next_index <= length(kids)) {
            nxt <- kids[[next_index]]
            is_gap <- inherits(nxt, "Gap")
            if (is_gap && delta_out$value > 0) {
                ete <- .rt_plus(ete, delta_out)
            } else if (delta_out$value < 0) {
                ete <- .rt_plus(ete, delta_out)
                if (is_gap) {
                    gap_range <- trimmed_range(nxt)
                    source_range(nxt) <- TimeRange(.rt_minus(gap_range$start_time, delta_out),
                        .rt_plus(gap_range$duration, delta_out))
                } else {
                    fill_duration <- .rt_neg(delta_out)
                    if (fill_duration$value > 0) {
                        if (is.null(fill_template)) {
                            fill_template <- Gap(fill_duration) # source_range [0, fill_duration)
                        }
                        insert_child(comp, next_index, fill_template)
                    }
                }
            }
        }
    }
    source_range(item) <- range_from_start_end_time(start_time, ete)
    invisible(item)
}

#' Roll an item, adjusting adjacent items to fit
#'
#' Adjusts the item's start by \code{delta_in} and exclusive end by
#' \code{delta_out}, absorbing the change into the neighbouring items' source
#' ranges (no new items are created); clamps to media available ranges. Mutates
#' in place.
#'
#' @param item An item (usually a clip).
#' @param delta_in,delta_out \code{\link{RationalTime}} adjustments.
#' @return \code{item}, invisibly.
#' @export
roll <- function(item, delta_in, delta_out) {
    comp <- parent(item)
    if (is.null(comp)) {
        stop("roll: item has no parent", call. = FALSE)
    }
    kids <- children(comp)
    index <- index_of_child(comp, item)
    if (is.na(index)) {
        stop("roll: item is not a child of its parent", call. = FALSE)
    }
    range <- trimmed_range(item)
    ar <- .avail_or_null(item)
    start_time <- range$start_time
    ete <- end_time_exclusive(range)
    if (delta_in$value != 0) {
        in_offset <- delta_in
        if (.rt_lt(start_time, .rt_neg(in_offset))) {
            in_offset <- .rt_neg(start_time) # -in_offset > start_time
        }
        if (index > 1L) {
            previous <- kids[[index - 1L]]
            prev_range <- trimmed_range(previous)
            dur <- prev_range$duration
            if (.rt_lt(dur, .rt_neg(in_offset))) { # clamp to previous clip's range
                dur <- .rt_minus(dur, RationalTime(1, dur$rate))
                in_offset <- .rt_minus(in_offset, dur)
            }
            source_range(previous) <- TimeRange(prev_range$start_time,
                .rt_plus(prev_range$duration, in_offset))
        }
        start_time <- .rt_plus(start_time, in_offset)
        if (.has_avail(ar) && .rt_lt(start_time, ar$start_time)) {
            start_time <- ar$start_time
        }
    }
    if (delta_out$value != 0) {
        next_index <- index + 1L
        if (next_index <= length(kids)) {
            nxt <- kids[[next_index]]
            next_range <- trimmed_range(nxt)
            next_ar <- .avail_or_null(nxt)
            next_start <- next_range$start_time
            out_offset <- delta_out
            if (.has_avail(ar)) {
                avail_start <- if (!is.null(next_ar)) {
                    next_ar$start_time
                } else {
                    RationalTime(0, next_start$rate)
                }
                if (.rt_lt(avail_start, .rt_neg(out_offset))) {
                    out_offset <- .rt_neg(avail_start)
                }
            } else if (.rt_lt(next_start, .rt_neg(out_offset))) {
                out_offset <- .rt_neg(next_start)
            }
            ete <- .rt_plus(ete, out_offset)
            next_start <- .rt_plus(next_start, out_offset)
            source_range(nxt) <- TimeRange(next_start, next_range$duration)
        }
    }
    source_range(item) <- range_from_start_end_time(start_time, ete)
    invisible(item)
}

