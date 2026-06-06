# Parse OTIO JSON back into the object model.
#
# jsonlite gives us plain nested lists; we walk the tree and re-attach the S3
# class for every node that carries an OTIO_SCHEMA, keyed on the schema name.
# Unknown schemas are preserved field-for-field and tagged generically, so
# objects this package does not model structurally (effects, markers, ...) still
# round-trip.

# Map an OTIO_SCHEMA string ("Clip.2") to this package's S3 class vector.
.schema_class <- function(schema) {
    type <- sub("\\.[0-9]+$", "", schema)
    switch(type,
           RationalTime = c("RationalTime", "otio_object"),
           TimeRange = c("TimeRange", "otio_object"),
           ExternalReference = c("ExternalReference", "MediaReference",
                                 "otio_object"),
           MissingReference = c("MissingReference", "MediaReference", "otio_object"),
           GeneratorReference = c("GeneratorReference", "MediaReference", "otio_object"),
           ImageSequenceReference = c("ImageSequenceReference", "MediaReference", "otio_object"),
           Clip = c("Clip", "Item", "otio_object"),
           Gap = c("Gap", "Item", "otio_object"),
           Effect = c("Effect", "otio_object"),
           LinearTimeWarp = c("LinearTimeWarp", "Effect", "otio_object"),
           Track = c("Track", "Composition", "otio_object"),
           Stack = c("Stack", "Composition", "otio_object"),
           Timeline = c("Timeline", "otio_object"),
           c(type, "otio_object"))
}

# Recursively rebuild classed objects from a parsed plain list.
.parse_node <- function(x) {
    if (!is.list(x)) {
        return(x)
    }
    schema <- x[["OTIO_SCHEMA"]]
    out <- lapply(x, .parse_node)
    if (!is.null(schema)) {
        if ("metadata" %in% names(out)) {
            out$metadata <- .as_metadata(out$metadata)
        }
        class(out) <- .schema_class(schema)
    }
    out
}

#' Parse an OTIO JSON string into the object model
#'
#' @param input An OTIO JSON string.
#' @return The reconstructed OTIO object (typically a \code{\link{Timeline}}).
#' @examples
#' tl <- Timeline("demo")
#' identical(name(from_json_string(to_json_string(tl))), "demo")
#' @export
from_json_string <- function(input) {
    .parse_node(jsonlite::fromJSON(input, simplifyVector = FALSE))
}

#' Read an OTIO JSON file into the object model
#'
#' @param file_name Path to a \code{.otio} JSON file.
#' @return The reconstructed OTIO object.
#' @export
from_json_file <- function(file_name) {
    .parse_node(jsonlite::fromJSON(file_name, simplifyVector = FALSE))
}

