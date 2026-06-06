# Serialize the OTIO object model to canonical OTIO JSON via jsonlite.
#
# Objects carry their fields in OTIO key order already (see objects.R), so
# serialization is: recursively strip S3 classes to plain lists, then hand the
# tree to jsonlite. NULL fields become JSON null; empty metadata is a named
# empty list so it emits {} (not []); effects/markers/children are plain lists
# so they emit [].

# Recursively drop S3 classes so jsonlite sees plain lists (it errors on unknown
# S3 classes otherwise). NULL elements and names are preserved by lapply.
.to_plain <- function(x) {
    if (is.list(x)) {
        return(lapply(unclass(x), .to_plain))
    }
    x
}

#' Serialize an OTIO object to a JSON string
#'
#' Emits canonical OpenTimelineIO JSON. Each object carries its own
#' \code{OTIO_SCHEMA}, so the output is the standard \code{.otio} format and
#' parses in any OTIO reader (verify with \code{\link{validate_with_rotio}}).
#'
#' @param x An OTIO object (typically a \code{\link{Timeline}}).
#' @param indent Indent width for pretty-printing (default 2). Use 0 for compact.
#' @return A JSON string.
#' @examples
#' to_json_string(Timeline("demo"))
#' @export
to_json_string <- function(x, indent = 2) {
    if (!is_otio(x)) {
        stop("to_json_string: x must be an OTIO object", call. = FALSE)
    }
    json <- jsonlite::toJSON(.to_plain(x), auto_unbox = TRUE, null = "null",
                             digits = NA)
    if (is.null(indent) || indent <= 0) {
        return(as.character(json))
    }
    as.character(jsonlite::prettify(json, indent = indent))
}

#' Write an OTIO object to a JSON file
#'
#' @param x An OTIO object (typically a \code{\link{Timeline}}).
#' @param file_name Output path (conventionally \code{content.otio}).
#' @param indent Indent width (default 2).
#' @return \code{file_name}, invisibly.
#' @examples
#' f <- tempfile(fileext = ".otio")
#' to_json_file(Timeline("demo"), f)
#' unlink(f)
#' @export
to_json_file <- function(x, file_name, indent = 2) {
    writeLines(to_json_string(x, indent = indent), file_name)
    invisible(file_name)
}

