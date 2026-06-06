# Time-model arithmetic and queries on RationalTime / TimeRange (Phase 2).
# Pure R; validated against rotio (see inst/tinytest/test_time_ops.R). Comparisons
# use seconds; the OTIO default epsilon is 1/384000 s.

.EPS <- 1 / 384000

# RationalTime arithmetic in a's rate (rates match in practice).
.rt_add <- function(a, b) RationalTime(a$value + b$value * (a$rate / b$rate),
                                       a$rate)
.rt_sub <- function(a, b) RationalTime(a$value - b$value * (a$rate / b$rate),
                                       a$rate)

#' Are two RationalTimes almost equal?
#'
#' Rescales \code{b} to \code{a}'s rate and compares values within \code{delta}
#' (in \code{a}'s rate units), matching OTIO.
#'
#' @param a,b \code{RationalTime}s.
#' @param delta Tolerance in \code{a}'s rate units (default 0).
#' @export
almost_equal <- function(a, b, delta = 0) {
    abs(a$value - rescaled_to(b, a$rate)$value) <= delta
}

#' Exclusive / inclusive end of a TimeRange
#'
#' \code{end_time_exclusive} = start + duration. \code{end_time_inclusive} is the
#' last whole frame: one frame before the exclusive end, or the floor of the
#' exclusive value when the duration is fractional.
#'
#' @param x A \code{TimeRange}.
#' @return A \code{RationalTime}.
#' @export
end_time_exclusive <- function(x) {
    if (!is_time_range(x)) {
        stop("end_time_exclusive: x must be a TimeRange", call. = FALSE)
    }
    .rt_add(x$start_time, x$duration)
}

#' @rdname end_time_exclusive
#' @export
end_time_inclusive <- function(x) {
    if (!is_time_range(x)) {
        stop("end_time_inclusive: x must be a TimeRange", call. = FALSE)
    }
    ex <- end_time_exclusive(x)
    if (floor(ex$value) != ex$value) {
        RationalTime(floor(ex$value), ex$rate)
    } else {
        .rt_sub(ex, RationalTime(1, ex$rate))
    }
}

#' Construct a TimeRange from start and exclusive end times
#' @param start_time A \code{RationalTime}.
#' @param end_time_exclusive A \code{RationalTime}.
#' @return A \code{TimeRange}.
#' @export
range_from_start_end_time <- function(start_time, end_time_exclusive) {
    TimeRange(start_time, .rt_sub(end_time_exclusive, start_time))
}

#' Does a TimeRange contain a time or range?
#'
#' For a \code{RationalTime}: \code{start <= t < end_exclusive}. For a
#' \code{TimeRange}: the other range lies within (with tolerance \code{epsilon_s}).
#'
#' @param tr A \code{TimeRange}.
#' @param other A \code{RationalTime} or \code{TimeRange}.
#' @param epsilon_s Tolerance in seconds.
#' @export
contains <- function(tr, other, epsilon_s = .EPS) {
    ts <- to_seconds(tr$start_time)
    te <- to_seconds(end_time_exclusive(tr))
    if (is_rational_time(other)) {
        os <- to_seconds(other)
        return(ts <= os && os < te)
    }
    os <- to_seconds(other$start_time)
    oe <- to_seconds(end_time_exclusive(other))
    # OTIO: other strictly inside on BOTH ends (by >= epsilon).
    (os - ts >= epsilon_s) && (te - oe >= epsilon_s)
}

#' Do two TimeRanges intersect?
#' @param tr,other \code{TimeRange}s.
#' @param epsilon_s Tolerance in seconds.
#' @export
intersects <- function(tr, other, epsilon_s = .EPS) {
    ts <- to_seconds(tr$start_time) ; te <- to_seconds(end_time_exclusive(tr))
    os <- to_seconds(other$start_time) ; oe <- to_seconds(end_time_exclusive(other))
    (ts < oe - epsilon_s) && (os < te - epsilon_s)
}

#' Do two TimeRanges overlap (cross without containment)?
#' @param tr,other \code{TimeRange}s.
#' @param epsilon_s Tolerance in seconds.
#' @export
overlaps <- function(tr, other, epsilon_s = .EPS) {
    ts <- to_seconds(tr$start_time) ; te <- to_seconds(end_time_exclusive(tr))
    os <- to_seconds(other$start_time) ; oe <- to_seconds(end_time_exclusive(other))
    (os - ts >= epsilon_s) && (te - os >= epsilon_s) && (oe - te >= epsilon_s)
}

#' Smallest TimeRange covering two ranges
#' @param tr,other \code{TimeRange}s.
#' @return A \code{TimeRange}.
#' @export
extended_by <- function(tr, other) {
    ts <- to_seconds(tr$start_time) ; te <- to_seconds(end_time_exclusive(tr))
    os <- to_seconds(other$start_time) ; oe <- to_seconds(end_time_exclusive(other))
    if (os < ts) {
        new_start <- other$start_time
    } else {
        new_start <- tr$start_time
    }
    if (oe > te) {
        new_end <- end_time_exclusive(other)
    } else {
        new_end <- end_time_exclusive(tr)
    }
    range_from_start_end_time(new_start, new_end)
}

#' Clamp a time or range into a bounding TimeRange
#'
#' \code{tr} is the bounding range; \code{other} is clamped into it (matching
#' OTIO's \code{TimeRange::clamped}). For a \code{RationalTime} \code{other}:
#' clamp into \code{[tr.start, tr.end_inclusive]}. For a \code{TimeRange}
#' \code{other}: \code{start = max(other.start, tr.start)},
#' \code{duration = other.duration}, end capped to \code{tr}'s exclusive end.
#'
#' @param tr The bounding \code{TimeRange}.
#' @param other A \code{RationalTime} or \code{TimeRange} to clamp.
#' @export
clamped <- function(tr, other) {
    if (!is_time_range(tr)) {
        stop("clamped: tr must be a TimeRange (the bounding range)", call. = FALSE)
    }
    if (is_rational_time(other)) {
        lo <- tr$start_time
        hi <- end_time_inclusive(tr)
        if (to_seconds(other) < to_seconds(lo)) return(lo)
        if (to_seconds(other) > to_seconds(hi)) return(hi)
        return(other)
    }
    if (is_time_range(other)) {
        rs <- if (to_seconds(other$start_time) > to_seconds(tr$start_time)) {
            other$start_time
        } else {
            tr$start_time
        }
        r_end <- .rt_add(rs, other$duration)
        te <- end_time_exclusive(tr)
        end <- if (to_seconds(r_end) < to_seconds(te)) r_end else te
        return(range_from_start_end_time(rs, end))
    }
    stop("clamped: other must be a RationalTime or TimeRange", call. = FALSE)
}

#' SMPTE timecode for a RationalTime
#' @param x A \code{RationalTime}.
#' @param rate Timecode rate (default \code{x}'s rate).
#' @param drop_frame Logical; drop-frame timecode (default FALSE).
#' @export
to_timecode <- function(x, rate = NULL, drop_frame = FALSE) {
    if (is.null(rate)) {
        rate <- x$rate
    }
    if (isTRUE(drop_frame)) {
        stop("to_timecode: drop_frame not yet supported", call. = FALSE)
    }
    fps <- as.integer(round(rate))
    f <- as.integer(round(to_seconds(x) * rate))
    hh <- f %/% (fps * 3600L)
    mm <- (f %/% (fps * 60L)) %% 60L
    ss <- (f %/% fps) %% 60L
    ff <- f %% fps
    sprintf("%02d:%02d:%02d:%02d", hh, mm, ss, ff)
}

#' RationalTime from a SMPTE timecode
#' @param timecode A \code{"HH:MM:SS:FF"} string.
#' @param rate Timecode rate.
#' @export
from_timecode <- function(timecode, rate) {
    parts <- as.integer(strsplit(timecode, "[:;]")[[1]])
    fps <- as.integer(round(rate))
    frames <- ((parts[1] * 60L + parts[2]) * 60L + parts[3]) * fps + parts[4]
    RationalTime(frames, rate)
}

#' Time string ("HH:MM:SS.sss") for a RationalTime
#' @param x A \code{RationalTime}.
#' @export
to_time_string <- function(x) {
    s <- to_seconds(x)
    hh <- floor(s / 3600)
    s2 <- s - hh * 3600
    mm <- floor(s2 / 60)
    s3 <- s2 - mm * 60
    ss <- floor(s3)
    micros <- floor((s3 - ss) * 1e6)        # truncate to microseconds (OTIO)
    fs <- sub("0+$", "", sprintf("%06d", as.integer(micros)))
    if (!nzchar(fs)) fs <- "0"              # always at least one fractional digit
    sprintf("%02d:%02d:%02d.%s", as.integer(hh), as.integer(mm),
            as.integer(ss), fs)
}

#' RationalTime from a time string ("HH:MM:SS.sss") at a rate
#' @param time_string A time string.
#' @param rate Rate (fps).
#' @export
from_time_string <- function(time_string, rate) {
    parts <- strsplit(time_string, ":")[[1]]
    n <- length(parts)
    secs <- as.numeric(parts[n]) +
    (if (n >= 2) as.numeric(parts[n - 1]) * 60 else 0) +
    (if (n >= 3) as.numeric(parts[n - 2]) * 3600 else 0)
    RationalTime(round(secs * rate), rate)
}

#' Construct a TimeTransform
#'
#' An offset/scale/rate transform applied to times (OTIO \code{TimeTransform}).
#'
#' @param offset A \code{RationalTime} offset (default 0).
#' @param scale Time scale (default 1).
#' @param rate Target rate, or -1 to preserve (default -1).
#' @return A \code{TimeTransform}.
#' @export
TimeTransform <- function(offset = RationalTime(0, 1), scale = 1, rate = -1) {
    if (!is_rational_time(offset)) {
        stop("TimeTransform: offset must be a RationalTime", call. = FALSE)
    }
    .new_otio("TimeTransform", c("OTIO_SCHEMA", "offset", "scale", "rate"),
              list(OTIO_SCHEMA = "TimeTransform.1", offset = offset,
                   scale = as.numeric(scale), rate = as.numeric(rate)))
}

