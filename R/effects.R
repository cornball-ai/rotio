# OpenTimelineIO effects (environment-backed). A generic Effect is an
# effect_name plus metadata; LinearTimeWarp adds a time_scalar. Effects attach to
# an item/composition's `effects` list (they are not composition children, so
# they carry no parent pointer). Field order/defaults mirror RcppOTIO.

#' Construct an OTIO effect
#'
#' \code{Effect} is a generic \code{effect_name} plus metadata parameters.
#' \code{LinearTimeWarp} is OTIO's linear speed change (\code{time_scalar}).
#'
#' @param name Effect instance name (default empty).
#' @param effect_name Effect kind label (default empty, matching OTIO).
#' @param enabled Whether the effect is active (default \code{TRUE}).
#' @param metadata Named list of parameters.
#' @return An \code{Effect}.
#' @examples
#' Effect("blur", "GaussianBlur", metadata = list(size = 4))
#' @export
Effect <- function(name = "", effect_name = "", enabled = TRUE,
                   metadata = NULL) {
    .new_otio("Effect",
              c("OTIO_SCHEMA", "metadata", "name", "effect_name", "enabled"),
              list(OTIO_SCHEMA = "Effect.1", metadata = .as_metadata(metadata),
                   name = as.character(name),
                   effect_name = as.character(effect_name),
                   enabled = isTRUE(enabled)))
}

#' @rdname Effect
#' @param time_scalar Linear time scale (playback rate multiplier).
#' @return \code{LinearTimeWarp}: a \code{LinearTimeWarp} object.
#' @examples
#' LinearTimeWarp("speed", effect_name = "LinearTimeWarp", time_scalar = 2)
#' @export
LinearTimeWarp <- function(name = "", effect_name = "", time_scalar = 1,
                           enabled = TRUE, metadata = NULL) {
    .new_otio(
              c("LinearTimeWarp", "TimeEffect", "Effect"),
              c("OTIO_SCHEMA", "metadata", "name", "effect_name", "enabled",
                "time_scalar"),
              list(OTIO_SCHEMA = "LinearTimeWarp.1", metadata = .as_metadata(metadata),
                   name = as.character(name), effect_name = as.character(effect_name),
                   enabled = isTRUE(enabled), time_scalar = as.numeric(time_scalar)))
}

#' @rdname Effect
#' @return \code{TimeEffect}: a generic time effect.
#' @export
TimeEffect <- function(name = "", effect_name = "", metadata = NULL) {
    .new_otio(c("TimeEffect", "Effect"),
              c("OTIO_SCHEMA", "metadata", "name", "effect_name", "enabled"),
              list(OTIO_SCHEMA = "TimeEffect.1", metadata = .as_metadata(metadata),
                   name = as.character(name),
                   effect_name = as.character(effect_name), enabled = TRUE))
}

#' @rdname Effect
#' @return \code{FreezeFrame}: a \code{LinearTimeWarp} with \code{time_scalar = 0}.
#' @export
FreezeFrame <- function(name = "", metadata = NULL) {
    .new_otio(
              c("FreezeFrame", "LinearTimeWarp", "TimeEffect", "Effect"),
              c("OTIO_SCHEMA", "metadata", "name", "effect_name", "enabled",
                "time_scalar"),
              list(OTIO_SCHEMA = "FreezeFrame.1", metadata = .as_metadata(metadata),
                   name = as.character(name), effect_name = "FreezeFrame",
                   enabled = TRUE, time_scalar = 0))
}

#' Is x an Effect?
#' @param x Object to test.
#' @export
is_effect <- function(x) inherits(x, "Effect")

#' Append an effect (functional: returns a new object)
#'
#' Returns a clone of \code{x} with \code{effect} appended to its \code{effects}
#' list; the input is unchanged.
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
    if (!is_otio(x) || !("effects" %in% x$.keys)) {
        stop("add_effect: x must have an effects list (item or composition)",
             call. = FALSE)
    }
    if (!is_effect(effect)) {
        stop("add_effect: effect must be an Effect", call. = FALSE)
    }
    out <- clone(x)
    out$effects <- c(out$effects, list(clone(effect)))
    out
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

