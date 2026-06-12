# Parse OTIO JSON back into the environment-backed object model.
#
# jsonlite gives plain nested lists; we rebuild an environment per node carrying
# an OTIO_SCHEMA, in the parsed key order, then rewire `.parent` pointers
# top-down so a parsed tree satisfies the same invariants as a built one.
# Unknown schemas are preserved field-for-field and tagged generically.

# Map an OTIO_SCHEMA string ("Clip.2") to this package's S3 class vector.
.schema_class <- function(schema) {
    type <- sub("\\.[0-9]+$", "", schema)
    switch(type,
           RationalTime = "RationalTime",
           TimeRange = "TimeRange",
           MediaReference = "MediaReference",
           ExternalReference = c("ExternalReference", "MediaReference"),
           MissingReference = c("MissingReference", "MediaReference"),
           GeneratorReference = c("GeneratorReference", "MediaReference"),
           ImageSequenceReference = c("ImageSequenceReference", "MediaReference"),
           Clip = c("Clip", "Item"),
           Gap = c("Gap", "Item"),
           Marker = "Marker",
           Transition = "Transition",
           Effect = "Effect",
           TimeEffect = c("TimeEffect", "Effect"),
           LinearTimeWarp = c("LinearTimeWarp", "TimeEffect", "Effect"),
           FreezeFrame = c("FreezeFrame", "LinearTimeWarp", "TimeEffect",
                           "Effect"),
           Track = c("Track", "Composition"),
           Stack = c("Stack", "Composition"),
           Timeline = "Timeline",
           SerializableCollection = "SerializableCollection",
           type)
}

# Recursively rebuild objects from a parsed plain list (no parent wiring yet).
.parse_node <- function(x) {
    if (!is.list(x)) {
        return(x)
    }
    schema <- x[["OTIO_SCHEMA"]]
    if (is.null(schema)) {
        return(lapply(x, .parse_node))
    }
    x <- .apply_upgrades(x) # migrate older schema versions (Phase 6)
    type <- .schema_type(x[["OTIO_SCHEMA"]])
    if (type %in% names(.TYPE_VERSION_MAP)) {
        x <- .fill_schema_defaults(x, type) # materialize current-schema defaults
    }
    schema <- x[["OTIO_SCHEMA"]]
    keys <- names(x)
    e <- new.env(parent = emptyenv())
    for (k in keys) {
        assign(k, .parse_node(x[[k]]), envir = e)
    }
    if ("metadata" %in% keys) {
        e$metadata <- .as_metadata(e$metadata)
    }
    e$.keys <- keys
    e$.parent <- NULL
    class(e) <- c(.schema_class(schema), "otio_object")
    e
}

#' Parse an OTIO JSON string into the object model
#'
#' @param input An OTIO JSON string.
#' @return The reconstructed OTIO object (typically a \code{\link{Timeline}}),
#'   with parent pointers wired.
#' @examples
#' tl <- Timeline("demo")
#' identical(name(from_json_string(to_json_string(tl))), "demo")
#' @export
from_json_string <- function(input) {
    obj <- .parse_node(jsonlite::fromJSON(input, simplifyVector = FALSE))
    if (is_otio(obj)) {
        .rewire_parents(obj)
    }
    obj
}

#' Read an OTIO JSON file into the object model
#'
#' @param file_name Path to a \code{.otio} JSON file.
#' @return The reconstructed OTIO object, with parent pointers wired.
#' @examples
#' f <- tempfile(fileext = ".otio")
#' to_json_file(Timeline("demo"), f)
#' name(from_json_file(f))
#' unlink(f)
#' @export
from_json_file <- function(file_name) {
    obj <- .parse_node(jsonlite::fromJSON(file_name, simplifyVector = FALSE))
    if (is_otio(obj)) {
        .rewire_parents(obj)
    }
    obj
}

