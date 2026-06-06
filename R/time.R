# Time value types: OpenTimelineIO RationalTime and TimeRange, pure R.
#
# A RationalTime is a value/rate pair (value in rate's units; for frame-based
# editorial work value is the frame number and rate is the fps). A TimeRange is
# a start_time plus a duration, both RationalTime. These mirror the OTIO names
# and serialize to the canonical OTIO JSON shapes; all math is plain R, no
# compiled code.

# Empty JSON object (serializes as {}, not []).
.empty_obj <- function() stats::setNames(list(), character())

# Normalize a metadata argument to a named list (so it serializes as a JSON
# object). NULL or an empty/unnamed list becomes an empty object.
.as_metadata <- function(m) {
    if (is.null(m) || length(m) == 0L) {
        return(.empty_obj())
    }
    if (is.null(names(m))) {
        stop("metadata must be a named list", call. = FALSE)
    }
    m
}

#' Construct a RationalTime
#'
#' An OpenTimelineIO \code{RationalTime} is a \code{value / rate} pair measured
#' in the rate's units. For frame-based editing \code{value} is the frame number
#' and \code{rate} is the frame rate.
#'
#' @param value Time value (frame number for frame-based work). Coerced to double.
#' @param rate Rate (fps); must be > 0. Default 1.
#' @return A \code{RationalTime} object.
#' @examples
#' RationalTime(180, 30)   # frame 180 at 30 fps
#' @export
RationalTime <- function(value, rate = 1) {
    value <- as.numeric(value)
    rate <- as.numeric(rate)
    if (length(value) != 1L || length(rate) != 1L || anyNA(c(value, rate))) {
        stop("RationalTime: value and rate must be length-1 numbers",
             call. = FALSE)
    }
    if (rate <= 0) {
        stop("RationalTime: rate must be > 0; got ", rate, call. = FALSE)
    }
    structure(list(OTIO_SCHEMA = "RationalTime.1", rate = rate, value = value),
              class = c("RationalTime", "otio_object"))
}

#' Construct a TimeRange
#'
#' An OpenTimelineIO \code{TimeRange} is a \code{start_time} plus a
#' \code{duration}, both \code{\link{RationalTime}}.
#'
#' @param start_time A \code{RationalTime} for the range start.
#' @param duration A \code{RationalTime} for the range length.
#' @return A \code{TimeRange} object.
#' @examples
#' TimeRange(RationalTime(0, 30), RationalTime(180, 30))
#' @export
TimeRange <- function(start_time, duration) {
    if (!is_rational_time(start_time) || !is_rational_time(duration)) {
        stop("TimeRange: start_time and duration must be RationalTime",
             call. = FALSE)
    }
    structure(list(OTIO_SCHEMA = "TimeRange.1", duration = duration,
                   start_time = start_time),
              class = c("TimeRange", "otio_object"))
}

#' Is x a RationalTime / TimeRange?
#' @param x Object to test.
#' @export
is_rational_time <- function(x) inherits(x, "RationalTime")

#' @rdname is_rational_time
#' @export
is_time_range <- function(x) inherits(x, "TimeRange")

#' RationalTime value and rate
#' @param x A \code{RationalTime}.
#' @export
value <- function(x) {
    if (!is_rational_time(x)) {
        stop("value: x must be a RationalTime", call. = FALSE)
    }
    x$value
}

#' @rdname value
#' @export
rate <- function(x) {
    if (!is_rational_time(x)) {
        stop("rate: x must be a RationalTime", call. = FALSE)
    }
    x$rate
}

#' TimeRange start_time and duration
#' @param x A \code{TimeRange}.
#' @export
start_time <- function(x) {
    if (!is_time_range(x)) {
        stop("start_time: x must be a TimeRange", call. = FALSE)
    }
    x$start_time
}

#' @rdname start_time
#' @export
duration <- function(x) {
    if (!is_time_range(x)) {
        stop("duration: x must be a TimeRange", call. = FALSE)
    }
    x$duration
}

#' Convert a RationalTime to seconds
#' @param x A \code{RationalTime}.
#' @export
to_seconds <- function(x) {
    if (!is_rational_time(x)) {
        stop("to_seconds: x must be a RationalTime", call. = FALSE)
    }
    x$value / x$rate
}

#' Construct a RationalTime from seconds at a rate
#' @param seconds Numeric seconds.
#' @param rate Rate (fps).
#' @export
from_seconds <- function(seconds, rate = 1) {
    RationalTime(as.numeric(seconds) * as.numeric(rate), rate)
}

#' Frame number of a RationalTime
#'
#' Returns the integer frame number. With no \code{rate}, rounds the value at the
#' time's own rate; with a \code{rate}, rescales first.
#'
#' @param x A \code{RationalTime}.
#' @param rate Optional target rate to rescale to before taking the frame number.
#' @export
to_frames <- function(x, rate = NULL) {
    if (!is_rational_time(x)) {
        stop("to_frames: x must be a RationalTime", call. = FALSE)
    }
    if (!is.null(rate)) {
        x <- rescaled_to(x, rate)
    }
    as.integer(round(x$value))
}

#' Construct a RationalTime from a frame number at a rate
#' @param frame Integer frame number.
#' @param rate Rate (fps).
#' @export
from_frames <- function(frame, rate) {
    RationalTime(round(as.numeric(frame)), rate)
}

#' Rescale a RationalTime to a new rate
#' @param x A \code{RationalTime}.
#' @param new_rate Target rate (fps).
#' @export
rescaled_to <- function(x, new_rate) {
    if (!is_rational_time(x)) {
        stop("rescaled_to: x must be a RationalTime", call. = FALSE)
    }
    new_rate <- as.numeric(new_rate)
    RationalTime(x$value * new_rate / x$rate, new_rate)
}

#' @export
print.RationalTime <- function(x, ...) {
    cat(sprintf("<RationalTime %g/%g = %.6fs>\n", x$value, x$rate,
                to_seconds(x)))
    invisible(x)
}

#' @export
print.TimeRange <- function(x, ...) {
    cat(sprintf("<TimeRange start %g/%g, dur %g/%g>\n", x$start_time$value,
                x$start_time$rate, x$duration$value, x$duration$rate))
    invisible(x)
}

