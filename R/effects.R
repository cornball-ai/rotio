# OpenTimelineIO effects, pure R.
#
# Effects attach to items and compositions (the `effects` list on Clip, Gap,
# Track, Stack). A generic Effect is an effect_name plus metadata; a
# LinearTimeWarp adds a time_scalar (playback rate; >1 is faster). Field order
# and defaults mirror rotio's serializer (effect_name defaults to "", enabled to
# TRUE) so emitted JSON round-trips through real OTIO. Builders are functional:
# add_effect() returns a new object.

#' Construct an OTIO effect
#'
#' A generic \code{Effect} is an \code{effect_name} (the driver-facing label) plus
#' a metadata dictionary of parameters. \code{LinearTimeWarp} is OTIO's linear
#' speed change, carrying a \code{time_scalar} (>1 faster, <1 slower).
#'
#' @param name Effect instance name (default empty).
#' @param effect_name Effect kind label (default empty, matching OTIO). Callers
#'   set this to a driver-recognized name (e.g. \code{"LinearTimeWarp"}).
#' @param enabled Whether the effect is active (default \code{TRUE}).
#' @param metadata Named list of parameters (serialized as a JSON object).
#' @return An \code{Effect} object.
#' @examples
#' Effect("blur", "GaussianBlur", metadata = list(size = 4))
#' @export
Effect <- function(name = "", effect_name = "", enabled = TRUE,
                   metadata = NULL) {
    structure(list(OTIO_SCHEMA = "Effect.1",
                   metadata = .as_metadata(metadata),
                   name = as.character(name),
                   effect_name = as.character(effect_name),
                   enabled = isTRUE(enabled)),
              class = c("Effect", "otio_object"))
}

#' @rdname Effect
#' @param time_scalar Linear time scale (playback rate multiplier).
#' @return \code{LinearTimeWarp}: a \code{LinearTimeWarp} object.
#' @examples
#' LinearTimeWarp("speed", effect_name = "LinearTimeWarp", time_scalar = 2)
#' @export
LinearTimeWarp <- function(name = "", effect_name = "", time_scalar = 1,
                           enabled = TRUE, metadata = NULL) {
    structure(list(OTIO_SCHEMA = "LinearTimeWarp.1",
                   metadata = .as_metadata(metadata),
                   name = as.character(name),
                   effect_name = as.character(effect_name),
                   enabled = isTRUE(enabled),
                   time_scalar = as.numeric(time_scalar)),
              class = c("LinearTimeWarp", "Effect", "otio_object"))
}

#' Is x an Effect?
#' @param x Object to test.
#' @export
is_effect <- function(x) inherits(x, "Effect")

#' Append an effect to an item or composition
#'
#' Returns a new object (clip, gap, track, or stack) with \code{effect} appended
#' to its \code{effects} list. The input is unchanged.
#'
#' @param x An item or composition (anything with an \code{effects} list).
#' @param effect An \code{\link{Effect}}.
#' @return A new object of the same class.
#' @examples
#' clip <- Clip("a", ExternalReference("a.mp4"))
#' clip <- add_effect(clip, LinearTimeWarp(effect_name = "LinearTimeWarp",
#'                                         time_scalar = 2))
#' length(effects(clip))
#' @export
add_effect <- function(x, effect) {
    if (!("effects" %in% names(x))) {
        stop("add_effect: x has no effects list (need an item or composition)",
             call. = FALSE)
    }
    if (!is_effect(effect)) {
        stop("add_effect: effect must be an Effect", call. = FALSE)
    }
    x$effects <- c(x$effects, list(effect))
    x
}

#' Effects of an item or composition
#' @param x An item or composition.
#' @return A list of \code{\link{Effect}} objects.
#' @export
effects <- function(x) x$effects

#' Effect kind label
#' @param x An \code{\link{Effect}}.
#' @param value New effect_name.
#' @export
effect_name <- function(x) x$effect_name

#' @rdname effect_name
#' @export
`effect_name<-` <- function(x, value) {
    x$effect_name <- as.character(value)
    x
}

#' Time scalar of a LinearTimeWarp
#' @param x A \code{\link{LinearTimeWarp}}.
#' @param value New time scalar.
#' @export
time_scalar <- function(x) x$time_scalar

#' @rdname time_scalar
#' @export
`time_scalar<-` <- function(x, value) {
    x$time_scalar <- as.numeric(value)
    x
}

