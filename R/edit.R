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

# --- composition helpers (ported from composition.cpp / track.cpp) ---

# First child whose range_in_parent contains `time` (start <= t < end_exclusive),
# matching Composition::child_at_time over range_of_all_children.
.child_at_time <- function(comp, time) {
    for (ch in children(comp)) {
        r <- tryCatch(range_in_parent(ch), error = function(e) NULL)
        if (!is.null(r) && contains(r, time)) {
            return(ch)
        }
    }
    NULL
}

# Previous / next siblings (Track::neighbors_of, default NeighborGapPolicy).
.neighbors_of <- function(comp, item) {
    idx <- index_of_child(comp, item)
    kids <- children(comp)
    list(first = if (idx > 1L) kids[[idx - 1L]] else NULL,
         second = if (idx < length(kids)) kids[[idx + 1L]] else NULL)
}

# Direct-child transitions whose range_in_parent intersects `range`
# (find_children<Transition>(range, shallow = TRUE)).
.transitions_in_range <- function(comp, range) {
    out <- list()
    for (ch in children(comp)) {
        if (inherits(ch, "Transition")) {
            r <- tryCatch(range_in_parent(ch), error = function(e) NULL)
            if (!is.null(r) && intersects(range, r)) {
                out <- c(out, list(ch))
            }
        }
    }
    out
}

#' Slice an item in two at a time
#'
#' Splits the item covering \code{time} into two adjacent items at that point.
#' Mutates \code{composition} in place. A slice exactly at an item boundary is a
#' no-op; slicing through a transition removes it (or errors if
#' \code{remove_transitions} is \code{FALSE}).
#'
#' @param composition A \code{\link{Track}} (or composition).
#' @param time A \code{\link{RationalTime}} to slice at.
#' @param remove_transitions Remove transitions at \code{time} (default TRUE).
#' @return \code{composition}, invisibly.
#' @export
slice <- function(composition, time, remove_transitions = TRUE) {
    item <- .child_at_time(composition, time)
    if (is.null(item) || !inherits(item, "Item")) {
        stop("slice: no item at the given time", call. = FALSE)
    }
    index <- index_of_child(composition, item)
    range <- trimmed_range_in_parent(item)
    duration <- .rt_minus(time, range$start_time)
    if (.is_zero(duration)) {
        return(invisible(composition)) # slice at a clip boundary
    }
    transitions <- list()
    if (inherits(composition, "Track")) {
        nb <- .neighbors_of(composition, item)
        for (tn in list(nb$second, nb$first)) {
            if (!is.null(tn) && inherits(tn, "Transition")) {
                if (contains(trimmed_range_in_parent(tn), time)) {
                    transitions <- c(transitions, list(tn))
                }
            }
        }
    }
    if (length(transitions)) {
        if (remove_transitions) {
            for (tn in transitions) {
                remove_child(composition, index_of_child(composition, tn))
            }
        } else {
            stop("slice: cannot slice in the middle of a transition",
                 call. = FALSE)
        }
    }
    first_src <- TimeRange(trimmed_range(item)$start_time, duration)
    source_range(item) <- first_src
    second_item <- clone(item)
    second_src <- TimeRange(.rt_plus(first_src$start_time, first_src$duration),
                            .rt_minus(range$duration, first_src$duration))
    if (!.is_zero(second_src$duration)) {
        source_range(second_item) <- second_src
        insert_child(composition, index + 1L, second_item)
    }
    invisible(composition)
}

#' Remove the item at a time, optionally leaving a gap
#'
#' Removes the item covering \code{time}; if \code{fill}, replaces it with a gap
#' (or \code{fill_template}) of the same range, otherwise the neighbours
#' concatenate. Mutates \code{composition} in place.
#'
#' @param composition A \code{\link{Track}} (or composition).
#' @param time A \code{\link{RationalTime}} within the item to remove.
#' @param fill Fill the hole with a gap/template (default TRUE).
#' @param fill_template Optional item to fill with (default a gap).
#' @return \code{composition}, invisibly.
#' @export
remove <- function(composition, time, fill = TRUE, fill_template = NULL) {
    item <- .child_at_time(composition, time)
    if (is.null(item) || !inherits(item, "Item")) {
        stop("remove: no item at the given time", call. = FALSE)
    }
    index <- index_of_child(composition, item)
    item_range <- trimmed_range(item)
    remove_child(composition, index)
    if (fill) {
        if (is.null(fill_template)) {
            fill_template <- Gap(item_range$duration) # OTIO: Gap(item_range)
            source_range(fill_template) <- item_range
        }
        insert_child(composition, index, fill_template)
    }
    invisible(composition)
}

#' Insert an item at a time, splitting the item it lands in
#'
#' Inserts \code{item} at \code{time}, splitting whatever item spans that point;
#' before the start it prepends, past the end it appends (filling any gap).
#' Mutates \code{composition} in place.
#'
#' @param item The item to insert (usually a clip).
#' @param composition A \code{\link{Track}} (or composition).
#' @param time A \code{\link{RationalTime}} to insert at.
#' @param remove_transitions Remove transitions at \code{time} (default TRUE).
#' @param fill_template Optional gap template when appending past the end.
#' @return \code{composition}, invisibly.
#' @export
insert <- function(item, composition, time, remove_transitions = TRUE,
                   fill_template = NULL) {
    if (remove_transitions) {
        rng <- TimeRange(time, RationalTime(1, time$rate))
        for (tn in .transitions_in_range(composition, rng)) {
            .remove_child_obj(composition, tn)
        }
    }
    comp_range <- trimmed_range(composition)
    target <- .child_at_time(composition, time)
    if (!is.null(target) && !inherits(target, "Item")) {
        target <- NULL
    }
    if (is.null(target)) {
        if (!.rt_lt(time, end_time_exclusive(comp_range))) {
            # time >= end_exclusive: append with optional fill gap
            fill_duration <- .rt_minus(time, end_time_exclusive(comp_range))
            if (!.is_zero(fill_duration)) {
                if (is.null(fill_template)) {
                    fill_template <- Gap(fill_duration)
                }
                append_child(composition, fill_template)
            }
            append_child(composition, item)
        } else if (.rt_lt(time, comp_range$start_time)) {
            insert_child(composition, 1L, item)
        } else {
            stop("insert: internal error locating insertion point",
                 call. = FALSE)
        }
        return(invisible(composition))
    }
    index <- index_of_child(composition, target)
    range <- range_in_parent(target)
    ins <- index
    split <- FALSE
    first_src <- TimeRange(trimmed_range(target)$start_time,
                           .rt_minus(time, range$start_time))
    if (!.is_zero(first_src$duration)) {
        split <- TRUE
        source_range(target) <- first_src
        ins <- ins + 1L
    }
    insert_child(composition, ins, item)
    insert_range <- range_in_parent(item)
    if (split) {
        second_src <- TimeRange(
                                .rt_plus(.rt_plus(first_src$start_time, insert_range$start_time),
                insert_range$duration),
                                .rt_minus(end_time_exclusive(range), time))
        if (!.is_zero(second_src$duration)) {
            second_item <- clone(target)
            source_range(second_item) <- second_src
            insert_child(composition, ins + 1L, second_item)
        }
    }
    invisible(composition)
}

# Remove a specific child (by its current index). NOTE: OTIO 0.18.1's
# overwrite()/insert() call remove_child(<Composable*>) here, but Composition only
# defines remove_child(int), so the pointer converts to bool(TRUE)->int(1) and the
# WRONG child (index 1, or the last when size==1) is removed. nle.api removes the
# intended child instead (the correct behaviour); see OpenTimelineIO upstream fix.
.remove_child_obj <- function(comp, child) {
    idx <- index_of_child(comp, child)
    if (!is.na(idx)) {
        remove_child(comp, idx)
    }
}

# Direct-child Items (clips/gaps, not transitions) whose range_in_parent
# intersects `range`, in child order (find_children<Item>(range, shallow=TRUE)).
.items_in_range <- function(comp, range) {
    out <- list()
    for (ch in children(comp)) {
        if (inherits(ch, "Item")) {
            r <- tryCatch(range_in_parent(ch), error = function(e) NULL)
            if (!is.null(r) && intersects(range, r)) {
                out <- c(out, list(ch))
            }
        }
    }
    out
}

#' Overwrite a span of a composition with an item
#'
#' Places \code{item} over \code{range} (in composition coordinates), partitioning
#' or removing the items it covers and filling any hole before/after with a gap
#' (or \code{fill_template}). Mutates \code{composition} in place.
#'
#' @param item The item to place (usually a clip).
#' @param composition A \code{\link{Track}} (or composition).
#' @param range A \code{\link{TimeRange}} to overwrite.
#' @param remove_transitions Remove transitions within \code{range} (default TRUE).
#' @param fill_template Optional gap template for holes.
#' @return \code{composition}, invisibly.
#' @export
overwrite <- function(item, composition, range, remove_transitions = TRUE,
                      fill_template = NULL) {
    comp_range <- trimmed_range(composition)
    start_time <- range$start_time
    if (!.rt_lt(start_time, end_time_exclusive(comp_range))) {
        # start at/after the end: append item, with a fill gap for the hole.
        fill_duration <- .rt_minus(range$start_time,
                                   end_time_exclusive(comp_range))
        if (!.is_zero(fill_duration)) {
            if (is.null(fill_template)) {
                fill_template <- Gap(fill_duration)
            }
            append_child(composition, fill_template)
        }
        append_child(composition, item)
        return(invisible(composition))
    }
    if (.rt_lt(start_time, comp_range$start_time) &&
        .rt_lt(end_time_exclusive(range), comp_range$start_time)) {
        # entirely before the start: prepend item, with a fill gap.
        fill_duration <- .rt_minus(.rt_minus(comp_range$start_time, start_time),
                                   range$duration)
        if (!.is_zero(fill_duration)) {
            if (is.null(fill_template)) {
                fill_template <- Gap(fill_duration)
            }
            insert_child(composition, 1L, fill_template)
        }
        insert_child(composition, 1L, item)
        return(invisible(composition))
    }
    if (remove_transitions) {
        for (tn in .transitions_in_range(composition, range)) {
            .remove_child_obj(composition, tn)
        }
    }
    items <- .items_in_range(composition, range)
    if (length(items) == 0L) {
        stop("overwrite: no item in the given range", call. = FALSE)
    }
    item_range <- trimmed_range_in_parent(items[[1]])
    if (length(items) == 1L && contains(item_range, range, epsilon_s = 0)) {
        # range falls strictly inside a single item: split into first / second.
        first_item <- items[[1]]
        is_fill_fit <- FALSE
        if (inherits(first_item, "Gap")) {
            for (eff in effects(item)) {
                if (inherits(eff, "LinearTimeWarp")) {
                    is_fill_fit <- TRUE
                    break
                }
            }
        }
        first_duration <- .rt_minus(range$start_time, item_range$start_time)
        second_duration <- .rt_minus(.rt_minus(item_range$duration, range$duration),
                                     first_duration)
        first_index <- index_of_child(composition, first_item)
        ins <- first_index
        orig_trimmed <- trimmed_range(first_item)
        if (.is_zero(first_duration)) {
            remove_child(composition, first_index)
        } else {
            source_range(first_item) <- TimeRange(orig_trimmed$start_time, first_duration)
            ins <- ins + 1L
        }
        item_own <- trimmed_range(item)
        if (.rt_lt(range$duration, item_own$duration) && !is_fill_fit) {
            source_range(item) <- TimeRange(orig_trimmed$start_time, range$duration)
        }
        insert_child(composition, ins, item)
        if (!.is_zero(second_duration)) {
            second_item <- clone(first_item)
            second_trimmed <- trimmed_range(second_item)
            ins <- ins + 1L
            source_range(second_item) <- TimeRange(
                .rt_plus(.rt_plus(second_trimmed$start_time, first_duration), range$duration),
                second_duration)
            insert_child(composition, ins, second_item)
        }
    } else {
        # range spans item boundaries: partition first/last, drop the middle.
        r_first <- index_of_child(composition, items[[1]])
        first_partial <- FALSE
        first_source <- NULL
        if (.rt_lt(item_range$start_time, range$start_time)) {
            first_partial <- TRUE
            trm <- trimmed_range(items[[1]])
            first_source <- TimeRange(trm$start_time,
                                      .rt_minus(range$start_time, item_range$start_time))
        }
        if (first_partial) {
            r_ins <- r_first + 1L
        } else {
            r_ins <- r_first
        }
        last_partial <- FALSE
        last_source <- NULL
        item_range_last <- trimmed_range_in_parent(items[[length(items)]])
        if (.rt_lt(end_time_inclusive(range), end_time_inclusive(item_range_last))) {
            last_partial <- TRUE
            trm <- trimmed_range(items[[length(items)]])
            duration <- .rt_minus(end_time_inclusive(item_range_last),
                                  end_time_inclusive(range))
            if (length(items) == 1L) {
                duration <- .rt_plus(duration, range$start_time)
                last_source <- TimeRange(.rt_plus(trm$start_time, range$duration), duration)
            } else {
                last_source <- TimeRange(.rt_plus(trm$start_time, duration),
                    .rt_minus(trm$duration, duration))
            }
        }
        remove_list <- items
        if (first_partial) {
            source_range(items[[1]]) <- first_source
            remove_list <- remove_list[-1L]
        }
        if (last_partial) {
            source_range(items[[length(items)]]) <- last_source
            remove_list <- remove_list[-length(remove_list)]
        }
        for (rm in remove_list) {
            .remove_child_obj(composition, rm)
        }
        trm <- trimmed_range(item)
        source_range(item) <- TimeRange(trm$start_time, range$duration)
        r_ins <- min(r_ins, length(children(composition)) + 1L)
        insert_child(composition, r_ins, item)
    }
    invisible(composition)
}

#' Fill a gap with an item (3/4-point edit)
#'
#' Replaces the gap covering \code{track_time} with \code{item}. The
#' \code{reference_point} controls the transform: \code{"Source"} uses the clip's
#' own duration, \code{"Sequence"} clamps to the gap, \code{"Fit"} time-warps the
#' clip to fill the gap exactly. Mutates \code{track} in place.
#'
#' @param item The item to place (usually a clip).
#' @param track A \code{\link{Track}}.
#' @param track_time A \code{\link{RationalTime}} inside the gap to fill.
#' @param reference_point One of \code{"Source"}, \code{"Sequence"}, \code{"Fit"}.
#' @return \code{track}, invisibly.
#' @export
fill <- function(item, track, track_time, reference_point = "Source") {
    gap <- .child_at_time(track, track_time)
    if (is.null(gap) || !inherits(gap, "Gap")) {
        stop("fill: no gap at track_time", call. = FALSE)
    }
    clip_range <- trimmed_range(item)
    gap_range <- trimmed_range(gap)
    gap_track_range <- trimmed_range_in_parent(gap)
    duration <- clip_range$duration
    if (reference_point == "Sequence") {
        start_time <- clip_range$start_time
        gap_start <- gap_range$start_time
        track_item <- clone(item)
        if (.rt_lt(start_time, gap_start)) {
            duration <- .rt_minus(duration, .rt_minus(gap_start, start_time))
            start_time <- gap_start
        }
        if (.rt_lt(end_time_exclusive(gap_range),
                   end_time_exclusive(clip_range))) {
            duration <- .rt_minus(end_time_exclusive(gap_range), start_time)
        }
        source_range(track_item) <- TimeRange(start_time, duration)
        if (.rt_lt(.rt_minus(end_time_exclusive(gap_track_range), track_time), duration)) {
            duration <- .rt_minus(end_time_exclusive(gap_track_range), track_time)
        }
        overwrite(track_item, track, TimeRange(track_time, duration))
    } else if (reference_point == "Fit") {
        pct <- to_seconds(gap_range$duration) / to_seconds(duration)
        nm <- name(item)
        tw <- LinearTimeWarp(nm, paste0(nm, "_timeWarp"), time_scalar = pct)
        new_item <- clone(item)
        source_range(new_item) <- clip_range
        new_item$effects <- c(effects(item), list(tw))
        overwrite(new_item, track,
                  TimeRange(track_time, .rt_minus(end_time_exclusive(gap_track_range), track_time)))
    } else {
        overwrite(item, track, TimeRange(track_time, duration))
    }
    invisible(track)
}

