# Time value types: OpenTimelineIO RationalTime and TimeRange (environment-backed
# like all OTIO objects, though they carry no parent/children). value/rate are in
# the rate's units; for frame-based work value is the frame number. Math is plain
# R. (.empty_obj / .as_metadata live in objects.R.)

#' Construct a RationalTime
#'
#' A \code{value / rate} pair measured in the rate's units (frame number / fps
#' for frame-based work).
#'
#' @param value Time value. Coerced to double.
#' @param rate Rate (fps); must be > 0. Default 1.
#' @return A \code{RationalTime}.
#' @examples
#' RationalTime(180, 30)
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
    .new_otio("RationalTime", c("OTIO_SCHEMA", "rate", "value"),
              list(OTIO_SCHEMA = "RationalTime.1", rate = rate, value = value))
}

#' Construct a TimeRange
#'
#' A \code{start_time} plus a \code{duration}, both \code{\link{RationalTime}}.
#'
#' @param start_time A \code{RationalTime}.
#' @param duration A \code{RationalTime}.
#' @return A \code{TimeRange}.
#' @examples
#' TimeRange(RationalTime(0, 30), RationalTime(180, 30))
#' @export
TimeRange <- function(start_time, duration) {
    if (!is_rational_time(start_time) || !is_rational_time(duration)) {
        stop("TimeRange: start_time and duration must be RationalTime",
             call. = FALSE)
    }
    .new_otio("TimeRange", c("OTIO_SCHEMA", "duration", "start_time"),
              list(OTIO_SCHEMA = "TimeRange.1", duration = duration,
                   start_time = start_time))
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
    # A Transition's duration is in_offset + out_offset (opentime).
    if (inherits(x, "Transition")) {
        return(.rt_plus(x$in_offset, x$out_offset))
    }
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
#' Integer frame number. With no \code{rate}, truncates at the time's own rate;
#' with a \code{rate}, rescales first. Truncates toward zero (opentime
#' \code{int(value_rescaled_to(rate))}).
#'
#' @param x A \code{RationalTime}.
#' @param rate Optional target rate to rescale to first.
#' @export
to_frames <- function(x, rate = NULL) {
    if (!is_rational_time(x)) {
        stop("to_frames: x must be a RationalTime", call. = FALSE)
    }
    if (!is.null(rate)) {
        x <- rescaled_to(x, rate)
    }
    as.integer(trunc(x$value))
}

#' Construct a RationalTime from a frame number at a rate
#' @param frame Integer frame number.
#' @param rate Rate (fps).
#' @export
from_frames <- function(frame, rate) {
    RationalTime(trunc(as.numeric(frame)), rate)
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
    if (new_rate == x$rate) {
        return(RationalTime(x$value, new_rate))
    }
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

