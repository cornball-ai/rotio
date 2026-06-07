# Time-model arithmetic and queries on RationalTime / TimeRange (Phase 2).
# Pure R; matched to libopentime and validated against RcppOTIO (test_time_ops.R).
# Rate handling follows opentime exactly: operator +/- keep the higher rate;
# duration_from_start_end_time keeps the start's rate; relations compare seconds.

.EPS <- 1 / 384000

.value_rescaled <- function(rt, new_rate) {
    if (new_rate == rt$rate) {
        rt$value
    } else {
        rt$value * new_rate / rt$rate
    }
}

# opentime operator+ / operator- : result takes the higher of the two rates.
.rt_plus <- function(a, b) {
    if (a$rate < b$rate) {
        RationalTime(b$value + .value_rescaled(a, b$rate), b$rate)
    } else {
        RationalTime(a$value + .value_rescaled(b, a$rate), a$rate)
    }
}
.rt_minus <- function(a, b) {
    if (a$rate < b$rate) {
        RationalTime(.value_rescaled(a, b$rate) - b$value, b$rate)
    } else {
        RationalTime(a$value - .value_rescaled(b, a$rate), a$rate)
    }
}
# duration_from_start_end_time: always in the start's rate.
.dur_from_se <- function(start, end) {
    if (start$rate == end$rate) {
        RationalTime(end$value - start$value, start$rate)
    } else {
        RationalTime(.value_rescaled(end, start$rate) - start$value, start$rate)
    }
}
.rt_lt <- function(a, b) to_seconds(a) < to_seconds(b)
.rt_min <- function(a, b) if (.rt_lt(b, a)) b else a
.rt_max <- function(a, b) if (.rt_lt(a, b)) b else a

#' Are two RationalTimes almost equal?
#'
#' Rescales \code{a} to \code{b}'s rate and compares to \code{b}'s value within
#' \code{delta} (in \code{b}'s rate units), matching opentime.
#'
#' @param a,b \code{RationalTime}s.
#' @param delta Tolerance in \code{b}'s rate units (default 0).
#' @export
almost_equal <- function(a, b, delta = 0) {
    abs(.value_rescaled(a, b$rate) - b$value) <= delta
}

#' Exclusive / inclusive end of a TimeRange
#'
#' \code{end_time_exclusive} = start + duration. \code{end_time_inclusive} is the
#' last whole frame; for a span of one frame or less it is the start time
#' (matching opentime).
#'
#' @param x A \code{TimeRange}.
#' @return A \code{RationalTime}.
#' @export
end_time_exclusive <- function(x) {
    if (!is_time_range(x)) {
        stop("end_time_exclusive: x must be a TimeRange", call. = FALSE)
    }
    # opentime: duration + start.rescaled_to(duration.rate); result at duration's
    # rate (NOT the higher-rate operator+ convention).
    d <- x$duration
    RationalTime(d$value + .value_rescaled(x$start_time, d$rate), d$rate)
}

#' @rdname end_time_exclusive
#' @export
end_time_inclusive <- function(x) {
    if (!is_time_range(x)) {
        stop("end_time_inclusive: x must be a TimeRange", call. = FALSE)
    }
    et <- end_time_exclusive(x)
    span <- .rt_minus(et, rescaled_to(x$start_time, x$duration$rate))
    if (span$value > 1) {
        if (x$duration$value != floor(x$duration$value)) {
            RationalTime(floor(et$value), et$rate)
        } else {
            .rt_minus(et, RationalTime(1, x$duration$rate))
        }
    } else {
        x$start_time
    }
}

#' Construct a TimeRange from start and exclusive end times
#'
#' Duration is computed in the start time's rate (opentime convention).
#'
#' @param start_time A \code{RationalTime}.
#' @param end_time_exclusive A \code{RationalTime}.
#' @return A \code{TimeRange}.
#' @export
range_from_start_end_time <- function(start_time, end_time_exclusive) {
    TimeRange(start_time, .dur_from_se(start_time, end_time_exclusive))
}

#' Does a TimeRange contain a time or range?
#'
#' For a \code{RationalTime}: \code{start <= t < end_exclusive}. For a
#' \code{TimeRange}: the other range lies strictly within on both ends (tolerance
#' \code{epsilon_s}).
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
    new_start <- .rt_min(tr$start_time, other$start_time)
    new_end <- .rt_max(end_time_exclusive(tr), end_time_exclusive(other))
    TimeRange(new_start, .dur_from_se(new_start, new_end))
}

#' Clamp a time or range into a bounding TimeRange
#'
#' \code{tr} is the bounding range; \code{other} is clamped into it (opentime
#' \code{TimeRange::clamped}).
#'
#' @param tr The bounding \code{TimeRange}.
#' @param other A \code{RationalTime} or \code{TimeRange} to clamp.
#' @export
clamped <- function(tr, other) {
    if (!is_time_range(tr)) {
        stop("clamped: tr must be a TimeRange (the bounding range)",
             call. = FALSE)
    }
    if (is_rational_time(other)) {
        return(.rt_min(.rt_max(other, tr$start_time), end_time_inclusive(tr)))
    }
    if (is_time_range(other)) {
        rs <- .rt_max(other$start_time, tr$start_time)
        r_end <- .rt_plus(rs, other$duration)
        end <- .rt_min(r_end, end_time_exclusive(tr))
        return(TimeRange(rs, .rt_minus(end, rs)))
    }
    stop("clamped: other must be a RationalTime or TimeRange", call. = FALSE)
}

# Frame number of a time at a timecode rate (truncated to a frame boundary).
.tc_frames <- function(x, rate) floor(.value_rescaled(x, rate) + 1e-6)

#' SMPTE timecode for a RationalTime
#' @param x A \code{RationalTime}.
#' @param rate Timecode rate (default \code{x}'s rate).
#' @param drop_frame Drop-frame timecode. \code{NULL} (default) infers it from the
#'   rate (on for 30000/1001 and 60000/1001), matching opentime's
#'   \code{InferFromRate}; pass \code{TRUE}/\code{FALSE} to force.
#' @export
to_timecode <- function(x, rate = NULL, drop_frame = NULL) {
    if (is.null(rate)) {
        rate <- x$rate
    }
    if (is.null(drop_frame)) {
        drop_frame <- isTRUE(all.equal(rate, 30000 / 1001)) ||
        isTRUE(all.equal(rate, 60000 / 1001))
    }
    fps <- as.integer(round(rate))
    total <- .tc_frames(x, rate)
    if (isTRUE(drop_frame)) {
        dropf <- round(rate * 0.066666)
        per10 <- round(rate * 60 * 10)
        per24 <- round(rate * 60 * 60) * 24
        permin <- fps * 60 - dropf
        fn <- total %% per24
        d <- fn %/% per10
        m <- fn %% per10
        if (m > dropf) {
            fn <- fn + dropf * 9 * d + dropf * ((m - dropf) %/% permin)
        } else {
            fn <- fn + dropf * 9 * d
        }
        sep <- ";"
    } else {
        fn <- total
        sep <- ":"
    }
    ff <- fn %% fps
    ss <- (fn %/% fps) %% 60
    mm <- ((fn %/% fps) %/% 60) %% 60
    hh <- (((fn %/% fps) %/% 60) %/% 60)
    sprintf("%02d:%02d:%02d%s%02d", as.integer(hh), as.integer(mm),
            as.integer(ss), sep, as.integer(ff))
}

#' RationalTime from a SMPTE timecode
#'
#' A \code{;} frame separator is treated as drop-frame.
#'
#' @param timecode A \code{"HH:MM:SS:FF"} (or \code{";FF"} for drop-frame) string.
#' @param rate Timecode rate.
#' @export
from_timecode <- function(timecode, rate) {
    drop <- grepl(";", timecode)
    p <- as.numeric(strsplit(timecode, "[:;]")[[1]])
    fps <- as.integer(round(rate))
    fn <- ((p[1] * 60 + p[2]) * 60 + p[3]) * fps + p[4]
    if (drop) {
        dropf <- round(rate * 0.066666)
        total_min <- 60 * p[1] + p[2]
        fn <- fn - dropf * (total_min - total_min %/% 10)
    }
    RationalTime(fn, rate)
}

#' Time string ("HH:MM:SS.sss") for a RationalTime
#' @param x A \code{RationalTime}.
#' @export
to_time_string <- function(x) {
    s <- to_seconds(x)
    sign <- if (s < 0) "-" else "" # opentime works on fabs, prepends sign
    s <- abs(s)
    hh <- floor(s / 3600)
    s2 <- s - hh * 3600
    mm <- floor(s2 / 60)
    s3 <- s2 - mm * 60
    ss <- floor(s3)
    micros <- floor((s3 - ss) * 1e6) # truncate to microseconds (opentime)
    fs <- sub("0+$", "", sprintf("%06d", as.integer(micros)))
    if (!nzchar(fs)) {
        fs <- "0"
    }
    sprintf("%s%02d:%02d:%02d.%s", sign, as.integer(hh), as.integer(mm),
            as.integer(ss), fs)
}

#' RationalTime from a time string ("HH:MM:SS.sss") at a rate
#'
#' Preserves the fractional value (no rounding to a frame boundary).
#'
#' @param time_string A time string.
#' @param rate Rate (fps).
#' @export
from_time_string <- function(time_string, rate) {
    parts <- strsplit(time_string, ":")[[1]]
    n <- length(parts)
    secs <- as.numeric(parts[n]) +
    (if (n >= 2) as.numeric(parts[n - 1]) * 60 else 0) +
    (if (n >= 3) as.numeric(parts[n - 2]) * 3600 else 0)
    RationalTime(secs * rate, rate)
}

#' Construct a TimeTransform
#'
#' An offset/scale/rate transform (OTIO \code{TimeTransform}). Note: in RcppOTIO
#' \code{TimeTransform} is a plain opentime value type that does not serialize to
#' JSON; rotio gives it an \code{OTIO_SCHEMA} for its own (de)serialization,
#' which is not verified against RcppOTIO JSON.
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

