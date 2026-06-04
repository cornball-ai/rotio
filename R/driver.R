# Driver registry: nle.api knows driver names as strings. Drivers register
# themselves at load time (typically in .onLoad), supplying dump / apply /
# capabilities function references. nle.api never imports or suggests any
# driver package; the dependency arrow is driver -> nle.api only.

# Internal registry environment. Drivers store under .nle_registry[[name]].
.nle_registry <- new.env(parent = emptyenv())

#' Register a driver with nle.api
#'
#' Drivers call this from \code{.onLoad()} (or any other entry point) to
#' make themselves discoverable. The supplied functions are stored by
#' reference; they're called by \code{\link{dump_sequence}} /
#' \code{\link{apply_sequence}} / \code{\link{driver_capabilities}}.
#'
#' @param name Driver name (string). Used by callers as
#'   \code{dump_sequence(driver = name, ...)}.
#' @param dump Function: \code{function(...) -> nle_sequence}. NULL if
#'   the driver does not implement read-back.
#' @param apply Function: \code{function(seq, ...) -> invisible(...)}. NULL
#'   if the driver does not implement write-through.
#' @param capabilities Function: \code{function() -> list}. Should return
#'   a list with at least \code{formats}, \code{coords}, \code{time},
#'   \code{fields_preserved}, \code{metadata} (see SEQUENCE_SCHEMA.md).
#'
#' @return Invisible TRUE.
#' @export
nle_register_driver <- function(name, dump = NULL, apply = NULL,
                                capabilities = NULL) {
    if (!is.character(name) || length(name) != 1L || !nzchar(name)) {
        stop("nle_register_driver: name must be a non-empty string",
             call. = FALSE)
    }
    if (!is.null(dump) && !is.function(dump)) {
        stop("nle_register_driver: dump must be NULL or a function",
             call. = FALSE)
    }
    if (!is.null(apply) && !is.function(apply)) {
        stop("nle_register_driver: apply must be NULL or a function",
             call. = FALSE)
    }
    if (!is.null(capabilities) && !is.function(capabilities)) {
        stop("nle_register_driver: capabilities must be NULL or a function",
             call. = FALSE)
    }
    assign(name, list(dump = dump, apply = apply, capabilities = capabilities),
           envir = .nle_registry)
    invisible(TRUE)
}

#' Names of all registered drivers
#' @export
nle_drivers <- function() {
    ls(envir = .nle_registry)
}

#' Is a driver registered?
#' @param name Driver name.
#' @export
nle_driver_registered <- function(name) {
    exists(name, envir = .nle_registry, inherits = FALSE)
}

# Internal: fetch a driver record, error if missing or capability not provided
.get_driver <- function(name, capability = NULL) {
    if (!nle_driver_registered(name)) {
        stop(sprintf("nle.api: no driver named '%s' is registered. ", name),
             "Load the corresponding driver package (e.g. blendR) first.",
             call. = FALSE)
    }
    d <- get(name, envir = .nle_registry, inherits = FALSE)
    if (!is.null(capability)) {
        if (is.null(d[[capability]])) {
            stop(sprintf("driver '%s' does not implement '%s'", name, capability),
                 call. = FALSE)
        }
    }
    d
}

#' Read a sequence in from a driver's backing store
#'
#' Dispatches to the registered driver's \code{dump} function.
#'
#' @param driver Driver name (string).
#' @param ... Driver-specific arguments (e.g. \code{file = "scene.blend"}).
#' @return An \code{nle_sequence}.
#' @examples
#' \dontrun{
#' library(blendR)  # registers "blender"
#' seq <- dump_sequence("blender")
#' }
#' @export
dump_sequence <- function(driver, ...) {
    d <- .get_driver(driver, capability = "dump")
    res <- d$dump(...)
    if (!is_sequence(res)) {
        stop(sprintf("driver '%s' dump did not return an nle_sequence", driver),
             call. = FALSE)
    }
    res
}

#' Push a sequence into a driver's backing store
#'
#' Dispatches to the registered driver's \code{apply} function.
#'
#' @param driver Driver name (string).
#' @param seq An \code{nle_sequence}.
#' @param ... Driver-specific arguments.
#' @return Invisibly whatever the driver returns.
#' @examples
#' \dontrun{
#' library(blendR)
#' seq <- read_sequence("sequence.md")
#' apply_sequence("blender", seq)
#' }
#' @export
apply_sequence <- function(driver, seq, ...) {
    if (!is_sequence(seq)) {
        stop("apply_sequence: seq must be an nle_sequence", call. = FALSE)
    }
    d <- .get_driver(driver, capability = "apply")
    invisible(d$apply(seq, ...))
}

#' A driver's capability report
#'
#' Returns whatever the driver's \code{capabilities()} function returns.
#' Conventionally a list with \code{formats}, \code{coords}, \code{time},
#' \code{fields_preserved}, \code{metadata}.
#'
#' @param driver Driver name (string).
#' @export
driver_capabilities <- function(driver) {
    d <- .get_driver(driver, capability = "capabilities")
    d$capabilities()
}
