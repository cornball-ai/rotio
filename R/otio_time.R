#' OpenTimelineIO-backed rational time
#'
#' \code{otio_time()} constructs a time value backed by OpenTimelineIO's
#' \code{opentime::RationalTime} (wrapped as an external pointer into the
#' linked C++ library). A \code{RationalTime} is a \code{value / rate} pair in
#' the rate's units; for frame-based editorial work \code{value} is the frame
#' number and \code{rate} is the fps. This mirrors nle.api's existing
#' \code{(num, den)} naming: \code{num} is \code{value}, \code{den} is
#' \code{rate}.
#'
#' This is the OTIO-native counterpart to \code{\link{rational_time}}. The
#' pure-R \code{rational_time()} remains in place; \code{otio_time()} is the
#' path the sequence model migrates onto as the C++ wrap grows (see PLAN.md).
#'
#' All conversions (\code{to_seconds}, \code{to_frames}, timecode) are computed
#' by the OTIO library, not reimplemented in R, so they match the canonical
#' implementation byte for byte.
#'
#' @param num Frame number / time value (\code{value}). Coerced to double.
#' @param den Rate / fps (\code{rate}); must be > 0 (default 1).
#'
#' @return An \code{otio_time} object wrapping a live \code{RationalTime}.
#' @examples
#' t <- otio_time(4918, 30)   # frame 4918 at 30 fps
#' otio_to_seconds(t)         # 163.933...
#' otio_to_frames(t, 24)      # rescaled to 24 fps
#' @seealso \code{\link{rational_time}} for the pure-R value type.
#' @export
otio_time <- function(num, den = 1) {
    structure(
        list(ptr = otio_rt_create(as.double(num), as.double(den))),
        class = "otio_time")
}

#' Is x an otio_time?
#' @param x Object to test.
#' @export
is_otio_time <- function(x) inherits(x, "otio_time")

#' @rdname otio_time
#' @param x An \code{otio_time}.
#' @export
otio_value <- function(x) {
    stopifnot(is_otio_time(x))
    otio_rt_value(x$ptr)
}

#' @rdname otio_time
#' @export
otio_rate <- function(x) {
    stopifnot(is_otio_time(x))
    otio_rt_rate(x$ptr)
}

#' @rdname otio_time
#' @export
otio_to_seconds <- function(x) {
    stopifnot(is_otio_time(x))
    otio_rt_to_seconds(x$ptr)
}

#' @rdname otio_time
#' @param rate Rate (fps) to convert to.
#' @export
otio_to_frames <- function(x, rate) {
    stopifnot(is_otio_time(x))
    otio_rt_to_frames(x$ptr, as.double(rate))
}

#' @rdname otio_time
#' @export
otio_rescaled_to <- function(x, rate) {
    stopifnot(is_otio_time(x))
    structure(list(ptr = otio_rt_rescaled_to(x$ptr, as.double(rate))),
              class = "otio_time")
}

#' @rdname otio_time
#' @export
otio_timecode <- function(x, rate = otio_rate(x)) {
    stopifnot(is_otio_time(x))
    otio_rt_to_timecode(x$ptr, as.double(rate))
}

#' @export
print.otio_time <- function(x, ...) {
    cat(sprintf("<otio_time %g/%g = %.6fs>\n",
                otio_value(x), otio_rate(x), otio_to_seconds(x)))
    invisible(x)
}

#' @export
format.otio_time <- function(x, ...) {
    sprintf("%g/%g", otio_value(x), otio_rate(x))
}

#' Version of the linked OpenTimelineIO (opentime) library
#'
#' Reports the OTIO version this build of nle.api was compiled and linked
#' against, useful for diagnosing which schema set is available.
#'
#' @return A version string such as \code{"0.18.1"}.
#' @examples
#' otio_version()
#' @export
otio_version <- function() {
    otio_opentime_version()
}
