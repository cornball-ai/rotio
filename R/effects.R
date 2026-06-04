# Generic clip effects, modelled on OTIO's Effect schema.
#
# An effect is an `effect_name` plus a free metadata dictionary -- exactly what
# OTIO codes. Spatial operations (transform, crop, colour, ...) are generic
# effects; a driver maps the effect_name + parameters to its native engine
# (e.g. Kdenlive/MLT filters such as qtblend or scale0tilt). Speed/time-remap
# has its own verb, clip_speed (an OTIO LinearTimeWarp).
#
# These verbs are clone-based: each deep-clones the timeline, mutates the target
# clip in the clone, and returns it (the input is untouched). Effects added this
# way survive subsequent structural edits, because the structural rebuild clones
# non-time effects forward by clip id.

#' Add, list, inspect, or remove a clip effect
#'
#' nle.api models effects on OpenTimelineIO's own \code{Effect}: an
#' \code{effect_name} plus a metadata dictionary of parameters. This is the
#' OTIO-native way to attach transform / crop / colour / arbitrary effects; a
#' driver maps the name and parameters to its engine. For speed, use
#' \code{\link{clip_speed}} (an OTIO \code{LinearTimeWarp}).
#'
#' @param timeline An \code{nle_timeline}.
#' @param clip Clip id.
#' @param effect_name OTIO effect name, e.g. \code{"transform"}, \code{"crop"}.
#' @param params Named list of effect parameters (length-1 numbers or strings).
#' @param enabled Whether the effect is active (default \code{TRUE}).
#' @return \code{clip_effect_add} / \code{clip_effect_remove}: the updated
#'   timeline. \code{clip_effects}: a data.frame of the clip's effects.
#'   \code{clip_effect_params}: a named list.
#' @examples
#' tl <- new_timeline()
#' tl <- track_add(tl, "video", id = "v1")
#' tl <- clip_add(tl, "v1", tl_in = rational_time(0, 30),
#'                tl_out = rational_time(90, 30), asset = "a.mp4", id = "a")
#' tl <- clip_effect_add(tl, "a", "transform", list(x = 100, y = 50, scale = 0.5))
#' clip_effects(tl, "a")
#' @export
clip_effect_add <- function(timeline, clip, effect_name, params = list(),
                            enabled = TRUE) {
    stopifnot(is_timeline(timeline))
    structure(
        list(ptr = otio_clip_effect_add(timeline$ptr, as.character(clip),
                                        as.character(effect_name),
                                        as.list(params), isTRUE(enabled))),
        class = "nle_timeline")
}

#' @rdname clip_effect_add
#' @export
clip_effects <- function(timeline, clip) {
    stopifnot(is_timeline(timeline))
    df <- otio_clip_effects_df(timeline$ptr, as.character(clip))
    df$index <- df$index + 1L   # present a 1-based index to R callers
    df
}

#' @rdname clip_effect_add
#' @param i 1-based effect index (as listed by \code{clip_effects}).
#' @export
clip_effect_params <- function(timeline, clip, i) {
    stopifnot(is_timeline(timeline))
    otio_clip_effect_params(timeline$ptr, as.character(clip), as.integer(i) - 1L)
}

#' @rdname clip_effect_add
#' @export
clip_effect_remove <- function(timeline, clip, i) {
    stopifnot(is_timeline(timeline))
    structure(
        list(ptr = otio_clip_effect_remove(timeline$ptr, as.character(clip),
                                           as.integer(i) - 1L)),
        class = "nle_timeline")
}
