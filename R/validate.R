# Optional validation against the real OpenTimelineIO library via RcppOTIO.
#
# rotio emits OTIO JSON without any compiled code. When the optional RcppOTIO
# package (the faithful Rcpp/libopentimelineio binding) is installed, this
# round-trips our JSON through the real library to confirm it parses and
# survives a serialize cycle. Without RcppOTIO, validation is unverified.

#' Validate an OTIO object against the real OpenTimelineIO library
#'
#' Serializes \code{x} to OTIO JSON, parses it with \code{RcppOTIO} (the exact
#' libopentimelineio binding), and re-serializes through RcppOTIO. Confirms the
#' emitted JSON is accepted by real OTIO. Requires the optional \code{RcppOTIO}
#' package.
#'
#' @param x An OTIO object (typically a \code{\link{Timeline}}).
#' @return Invisibly, a list with \code{status} (\code{"valid"} or
#'   \code{"unverified"}) and, when validated, the RcppOTIO-normalized JSON.
#' @examples
#' \donttest{validate_with_RcppOTIO(Timeline("demo"))}
#' @export
validate_with_RcppOTIO <- function(x) {
    if (!is_otio(x)) {
        stop("validate_with_RcppOTIO: x must be an OTIO object", call. = FALSE)
    }
    if (!requireNamespace("RcppOTIO", quietly = TRUE)) {
        message("RcppOTIO not installed; validation unverified")
        return(invisible(list(status = "unverified", json = NULL)))
    }
    json <- to_json_string(x)
    obj <- RcppOTIO::from_json_string(json)
    normalized <- RcppOTIO::to_json_string(obj)
    invisible(list(status = "valid", json = normalized))
}

