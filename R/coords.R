# Phase 4: the composition coordinate model. Positions are computed from child
# order + durations (gaps included); ranges, track filters, flatten, and trims.
# Validated against rotio. Frame math assumes a uniform rate (the common case).

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
    dur <- trimmed_range(x)$duration
    start <- RationalTime(0, dur$rate)
    for (ch in p$children) {
        if (identical(ch, x)) {
            break
        }
        start <- .rt_plus(start, trimmed_range(ch)$duration)
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
    cl <- clamped(psr, ri)
    range_from_start_end_time(.rt_minus(cl$start_time, psr$start_time),
                              .rt_minus(end_time_exclusive(cl), psr$start_time))
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
        start <- .rt_minus(start, kids[[i - 1L]]$out_offset)
        dur <- .rt_plus(dur, kids[[i - 1L]]$out_offset)
    }
    if (i < length(kids) && inherits(kids[[i + 1L]], "Transition")) {
        dur <- .rt_plus(dur, kids[[i + 1L]]$in_offset)
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

#' Is an item visible (enabled)?
#' @param x An item.
#' @export
visible <- function(x) isTRUE(x$enabled)

#' Do any items in a composition overlap?
#'
#' Always \code{FALSE} for a Track (items are sequential).
#'
#' @param x A composition.
#' @export
overlapping <- function(x) {
    if (!.is_container(x)) {
        return(FALSE)
    }
    rngs <- lapply(x$children,
                   function(ch) tryCatch(range_in_parent(ch), error = function(e) NULL))
    rngs <- Filter(Negate(is.null), rngs)
    if (length(rngs) < 2L) {
        return(FALSE)
    }
    for (i in seq_len(length(rngs) - 1L)) {
        for (j in (i + 1L):length(rngs)) {
            if (intersects(rngs[[i]], rngs[[j]])) {
                return(TRUE)
            }
        }
    }
    FALSE
}

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
    rate <- .first_rate(list(in_track))
    ts <- to_frames(trim_range$start_time, rate)
    te <- ts + to_frames(trim_range$duration, rate)
    out <- Track(in_track$name, kind = in_track$kind %||% "Video")
    for (ch in children(in_track)) {
        rip <- range_in_parent(ch)
        cs <- to_frames(rip$start_time, rate)
        ce <- cs + to_frames(rip$duration, rate)
        if (ce <= ts || cs >= te) {
            next
        }
        left <- max(0L, ts - cs)
        new_dur <- min(ce, te) - max(cs, ts)
        sr <- trimmed_range(ch)
        nc <- clone(ch)
        source_range(nc) <- TimeRange(
                                      .rt_plus(sr$start_time, RationalTime(left, sr$start_time$rate)),
                                      RationalTime(new_dur, sr$duration$rate))
        append_child(out, nc)
    }
    out
}

#' Flatten a stack of tracks into a single track
#'
#' Composites top-down: the topmost track with a non-gap clip wins each segment;
#' gaps expose the tracks below. Returns a single \code{\link{Track}} of trimmed
#' clips and gaps.
#'
#' @param x A \code{\link{Stack}} or a list of \code{\link{Track}}s
#'   (bottom-to-top).
#' @return A flattened \code{\link{Track}}.
#' @export
flatten_stack <- function(x) {
    if (inherits(x, "Stack")) {
        tracks <- children(x)
    } else {
        tracks <- x
    }
    out <- Track("Flattened")
    if (length(tracks) == 0L) {
        return(out)
    }
    rate <- .first_rate(tracks)

    # Per track: segments (start, end frames, child, is_gap).
    segs <- lapply(tracks, function(trk) {
        pos <- 0L
        lapply(children(trk), function(ch) {
            d <- to_frames(trimmed_range(ch)$duration, rate)
            s <- pos
            pos <<- pos + d
            list(s = s, e = s + d, ch = ch, gap = inherits(ch, "Gap"))
        })
    })
    total <- max(vapply(segs, function(ss) if (length(ss)) {
                ss[[length(ss)]]$e
            } else {
                0L
            }, 0L))
    if (total == 0L) {
        return(out)
    }

    # Topmost non-gap clip covering each frame (0-based), with source offset.
    winner <- vector("list", total)
    for (f in seq_len(total)) {
        fi <- f - 1L
        w <- NULL
        for (ti in seq_along(tracks)) { # bottom..top; later overrides
            for (sg in segs[[ti]]) {
                if (fi >= sg$s && fi < sg$e && !sg$gap) {
                    w <- list(ch = sg$ch, off = fi - sg$s)
                }
            }
        }
        winner[[f]] <- w
    }

    # Group consecutive frames into trimmed clips / gaps.
    i <- 1L
    while (i <= total) {
        w <- winner[[i]]
        if (is.null(w)) {
            j <- i
            while (j <= total && is.null(winner[[j]])) {
                j <- j + 1L
            }
            append_child(out, Gap(RationalTime(j - i, rate)))
            i <- j
        } else {
            j <- i
            while (j <= total && !is.null(winner[[j]]) &&
                identical(winner[[j]]$ch, w$ch) &&
                winner[[j]]$off == w$off + (j - i)) {
                j <- j + 1L
            }
            n <- j - i
            sr <- trimmed_range(w$ch)
            nc <- clone(w$ch)
            source_range(nc) <- TimeRange(
                .rt_plus(sr$start_time, RationalTime(w$off, rate)),
                RationalTime(n, sr$duration$rate))
            append_child(out, nc)
            i <- j
        }
    }
    out
}

