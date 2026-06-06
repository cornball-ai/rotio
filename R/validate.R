# Optional validation against the real OpenTimelineIO library via rotio.
#
# nle.api emits OTIO JSON without any compiled code. When the optional rotio
# package (the faithful Rcpp/libopentimelineio binding) is installed, this
# round-trips our JSON through the real library to confirm it parses and
# survives a serialize cycle. Without rotio, validation is unverified.

#' Validate an OTIO object against the real OpenTimelineIO library
#'
#' Serializes \code{x} to OTIO JSON, parses it with \code{rotio} (the exact
#' libopentimelineio binding), and re-serializes through rotio. Confirms the
#' emitted JSON is accepted by real OTIO. Requires the optional \code{rotio}
#' package.
#'
#' @param x An OTIO object (typically a \code{\link{Timeline}}).
#' @return Invisibly, a list with \code{status} (\code{"valid"} or
#'   \code{"unverified"}) and, when validated, the rotio-normalized JSON.
#' @examples
#' \donttest{validate_with_rotio(Timeline("demo"))}
#' @export
validate_with_rotio <- function(x) {
    if (!is_otio(x)) {
        stop("validate_with_rotio: x must be an OTIO object", call. = FALSE)
    }
    if (!requireNamespace("rotio", quietly = TRUE)) {
        message("rotio not installed; validation unverified")
        return(invisible(list(status = "unverified", json = NULL)))
    }
    json <- to_json_string(x)
    obj <- rotio::from_json_string(json)
    normalized <- rotio::to_json_string(obj)
    invisible(list(status = "valid", json = normalized))
}

