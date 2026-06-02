#' Construct a rational time value
#'
#' nle.api stores every time value as a rational \code{num/den} in
#' seconds so that frame-exact round-trips are possible without
#' floating-point drift. Both components must be integers; \code{den}
#' must be positive.
#'
#' @param num Integer numerator.
#' @param den Integer denominator (default 1; must be > 0).
#'
#' @return A list with class \code{rational_time}.
#' @examples
#' rational_time(4918, 30)             # frame 4918 at 30 fps -> 163.93s
#' rational_time(60, 1)                # one minute
#' @export
rational_time <- function(num, den = 1L) {
    num <- as.integer(num)
    den <- as.integer(den)
    if (length(num) != 1L || length(den) != 1L || is.na(num) || is.na(den)) {
        stop("rational_time: num and den must be length-1 integers", call. = FALSE)
    }
    if (den <= 0L) {
        stop("rational_time: den must be > 0; got ", den, call. = FALSE)
    }
    structure(list(num = num, den = den), class = "rational_time")
}

#' Is x a rational_time?
#' @param x Object to test.
#' @export
is_rational_time <- function(x) inherits(x, "rational_time")

#' Convert rational_time to seconds (double)
#' @param x A rational_time.
#' @export
to_seconds <- function(x) {
    if (!is_rational_time(x)) {
        stop("to_seconds: x must be a rational_time", call. = FALSE)
    }
    x$num / x$den
}

#' Convert a seconds value to a rational_time at a given denominator
#'
#' Useful for converting a frame count or wall-clock seconds to the
#' canonical rational form. Rounds to the nearest \code{num}.
#'
#' @param seconds Numeric seconds.
#' @param den Integer denominator (typically the project fps).
#' @export
to_rational <- function(seconds, den) {
    den <- as.integer(den)
    if (den <= 0L) {
        stop("to_rational: den must be > 0", call. = FALSE)
    }
    rational_time(as.integer(round(seconds * den)), den)
}

#' Convert a rational_time to an integer frame count at a given fps
#'
#' If \code{fps == x$den}, returns \code{x$num} exactly. Otherwise
#' rescales: \code{round(x$num * fps / x$den)}.
#'
#' @param x A rational_time.
#' @param fps Integer frames per second.
#' @export
to_frames <- function(x, fps) {
    if (!is_rational_time(x)) {
        stop("to_frames: x must be a rational_time", call. = FALSE)
    }
    fps <- as.integer(fps)
    if (fps <= 0L) {
        stop("to_frames: fps must be > 0", call. = FALSE)
    }
    if (fps == x$den) {
        return(as.integer(x$num))
    }
    as.integer(round(x$num * fps / x$den))
}

#' @export
print.rational_time <- function(x, ...) {
    cat(sprintf("<rational_time %d/%d = %.6fs>\n", x$num, x$den, to_seconds(x)))
    invisible(x)
}

#' @export
format.rational_time <- function(x, ...) {
    sprintf("%d/%d", x$num, x$den)
}

# Internal: parse a JSON-decoded value into a rational_time. Accepts
# either a list/dict with $num/$den or a length-2 named vector.
.parse_rational <- function(x) {
    if (is_rational_time(x)) return(x)
    if (is.list(x) && all(c("num", "den") %in% names(x))) {
        return(rational_time(x$num, x$den))
    }
    stop(".parse_rational: cannot interpret value as rational_time",
         call. = FALSE)
}
