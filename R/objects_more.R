# Phase 3: the rest of the OTIO object surface (media-reference subtypes,
# Marker, Transition) and their accessors. Field order/defaults mirror rotio.
# (TimeEffect/FreezeFrame are in effects.R.)

#' Construct a generic MediaReference
#' @param name Reference name.
#' @param available_range Optional \code{\link{TimeRange}}.
#' @param metadata Named list of metadata.
#' @return A \code{MediaReference}.
#' @export
MediaReference <- function(name = "", available_range = NULL, metadata = NULL) {
    .new_otio(c("MediaReference"),
              c("OTIO_SCHEMA", "metadata", "name", "available_range",
                "available_image_bounds"),
              list(OTIO_SCHEMA = "MediaReference.1", metadata = .as_metadata(metadata),
                   name = as.character(name), available_range = available_range,
                   available_image_bounds = NULL))
}

#' Construct a GeneratorReference
#'
#' Procedurally-generated media (color bars, solids, ...).
#'
#' @param name Reference name.
#' @param generator_kind Generator kind (e.g. \code{"SMPTEBars"}).
#' @param available_range Optional \code{\link{TimeRange}}.
#' @param parameters Named list of generator parameters.
#' @param metadata Named list of metadata.
#' @return A \code{GeneratorReference}.
#' @export
GeneratorReference <- function(name = "", generator_kind = "",
                               available_range = NULL, parameters = NULL,
                               metadata = NULL) {
    .new_otio(
              c("GeneratorReference", "MediaReference"),
              c("OTIO_SCHEMA", "metadata", "name", "available_range",
                "available_image_bounds", "generator_kind", "parameters"),
              list(OTIO_SCHEMA = "GeneratorReference.1", metadata = .as_metadata(metadata),
                   name = as.character(name), available_range = available_range,
                   available_image_bounds = NULL,
                   generator_kind = as.character(generator_kind),
                   parameters = .as_metadata(parameters)))
}

#' Construct an ImageSequenceReference
#'
#' A numbered image sequence (e.g. \code{frame.0001.exr}).
#'
#' @param target_url_base Directory URL.
#' @param name_prefix,name_suffix Filename prefix/suffix around the frame number.
#' @param start_frame First frame number (default 1).
#' @param frame_step Frames between images (default 1).
#' @param rate Frame rate (default 1).
#' @param frame_zero_padding Zero-padding width for the frame number (default 0).
#' @param missing_frame_policy One of \code{"error"}, \code{"hold"}, \code{"black"}.
#' @param available_range Optional \code{\link{TimeRange}}.
#' @param metadata Named list of metadata.
#' @return An \code{ImageSequenceReference}.
#' @export
ImageSequenceReference <- function(target_url_base = "", name_prefix = "",
                                   name_suffix = "", start_frame = 1L,
                                   frame_step = 1L, rate = 1,
                                   frame_zero_padding = 0L,
                                   missing_frame_policy = "error",
                                   available_range = NULL, metadata = NULL) {
    .new_otio(
              c("ImageSequenceReference", "MediaReference"),
              c("OTIO_SCHEMA", "metadata", "name", "available_range",
                "available_image_bounds", "target_url_base", "name_prefix",
                "name_suffix", "start_frame", "frame_step", "rate",
                "frame_zero_padding", "missing_frame_policy"),
              list(OTIO_SCHEMA = "ImageSequenceReference.1", metadata = .as_metadata(metadata),
                   name = "", available_range = available_range,
                   available_image_bounds = NULL,
                   target_url_base = as.character(target_url_base),
                   name_prefix = as.character(name_prefix),
                   name_suffix = as.character(name_suffix),
                   start_frame = as.integer(start_frame), frame_step = as.integer(frame_step),
                   rate = as.numeric(rate), frame_zero_padding = as.integer(frame_zero_padding),
                   missing_frame_policy = as.character(missing_frame_policy)))
}

#' Construct a Marker
#'
#' Annotates a time range on an item.
#'
#' @param name Marker name.
#' @param marked_range A \code{\link{TimeRange}}.
#' @param color Marker color (default \code{"GREEN"}).
#' @param comment Free-text comment.
#' @param metadata Named list of metadata.
#' @return A \code{Marker}.
#' @export
Marker <- function(name = "", marked_range = NULL, color = "GREEN",
                   comment = "", metadata = NULL) {
    if (is.null(marked_range)) {
        marked_range <- TimeRange(RationalTime(0, 1), RationalTime(0, 1))
    }
    .new_otio("Marker",
              c("OTIO_SCHEMA", "metadata", "name", "color", "marked_range",
                "comment"),
              list(OTIO_SCHEMA = "Marker.2", metadata = .as_metadata(metadata),
                   name = as.character(name), color = as.character(color),
                   marked_range = marked_range, comment = as.character(comment)))
}

#' Construct a Transition
#'
#' A transition (e.g. a dissolve) between adjacent items on a track.
#'
#' @param name Transition name.
#' @param transition_type Transition type (e.g. \code{"SMPTE_Dissolve"}).
#' @param in_offset,out_offset \code{\link{RationalTime}} offsets into the
#'   neighbouring clips.
#' @param metadata Named list of metadata.
#' @return A \code{Transition}.
#' @export
Transition <- function(name = "", transition_type = "",
                       in_offset = RationalTime(0, 1),
                       out_offset = RationalTime(0, 1), metadata = NULL) {
    .new_otio("Transition",
              c("OTIO_SCHEMA", "metadata", "name", "in_offset", "out_offset",
                "transition_type"),
              list(OTIO_SCHEMA = "Transition.1", metadata = .as_metadata(metadata),
                   name = as.character(name), in_offset = in_offset,
                   out_offset = out_offset,
                   transition_type = as.character(transition_type)))
}

# ---- predicates -----------------------------------------------------------

#' Is x a MissingReference?
#' @param x Object to test.
#' @export
is_missing_reference <- function(x) inherits(x, "MissingReference")

# ---- accessors ------------------------------------------------------------

#' Available range of a media reference
#' @param x A media reference.
#' @param value A \code{\link{TimeRange}} or \code{NULL}.
#' @export
available_range <- function(x) x$available_range

#' @rdname available_range
#' @export
`available_range<-` <- function(x, value) {
    x$available_range <- value
    x
}

#' Generator kind of a GeneratorReference
#' @param x A \code{\link{GeneratorReference}}.
#' @param value New generator kind.
#' @export
generator_kind <- function(x) x$generator_kind

#' @rdname generator_kind
#' @export
`generator_kind<-` <- function(x, value) {
    x$generator_kind <- as.character(value)
    x
}

#' Parameters of a GeneratorReference
#' @param x A \code{\link{GeneratorReference}}.
#' @param value A named list of parameters.
#' @export
parameters <- function(x) x$parameters

#' @rdname parameters
#' @export
`parameters<-` <- function(x, value) {
    x$parameters <- .as_metadata(value)
    x
}

#' Marked range of a Marker
#' @param x A \code{\link{Marker}}.
#' @param value A \code{\link{TimeRange}}.
#' @export
marked_range <- function(x) x$marked_range

#' @rdname marked_range
#' @export
`marked_range<-` <- function(x, value) {
    x$marked_range <- value
    x
}

#' Comment of a Marker
#' @param x A \code{\link{Marker}}.
#' @param value New comment.
#' @export
comment <- function(x) x$comment

#' @rdname comment
#' @export
`comment<-` <- function(x, value) {
    x$comment <- as.character(value)
    x
}

#' Transition type / offsets
#' @param x A \code{\link{Transition}}.
#' @param value New value.
#' @export
transition_type <- function(x) x$transition_type

#' @rdname transition_type
#' @export
`transition_type<-` <- function(x, value) {
    x$transition_type <- as.character(value)
    x
}

#' @rdname transition_type
#' @export
in_offset <- function(x) x$in_offset

#' @rdname transition_type
#' @export
`in_offset<-` <- function(x, value) {
    x$in_offset <- value
    x
}

#' @rdname transition_type
#' @export
out_offset <- function(x) x$out_offset

#' @rdname transition_type
#' @export
`out_offset<-` <- function(x, value) {
    x$out_offset <- value
    x
}

# ---- ImageSequenceReference accessors and computed values -----------------

#' ImageSequenceReference fields
#' @param x An \code{\link{ImageSequenceReference}}.
#' @param value New value.
#' @export
target_url_base <- function(x) x$target_url_base

#' @rdname target_url_base
#' @export
`target_url_base<-` <- function(x, value) {
    x$target_url_base <- as.character(value)
    x
}

#' @rdname target_url_base
#' @export
name_prefix <- function(x) x$name_prefix

#' @rdname target_url_base
#' @export
name_suffix <- function(x) x$name_suffix

#' @rdname target_url_base
#' @export
start_frame <- function(x) x$start_frame

#' @rdname target_url_base
#' @export
frame_step <- function(x) x$frame_step

#' @rdname target_url_base
#' @export
frame_zero_padding <- function(x) x$frame_zero_padding

#' Number of images in an ImageSequenceReference
#' @param x An \code{\link{ImageSequenceReference}}.
#' @export
number_of_images_in_sequence <- function(x) {
    ar <- x$available_range
    if (is.null(ar)) {
        return(0L)
    }
    as.integer(floor(to_frames(duration(ar), x$rate) / x$frame_step))
}

#' Last frame number of an ImageSequenceReference
#' @param x An \code{\link{ImageSequenceReference}}.
#' @export
end_frame <- function(x) {
    x$start_frame + (number_of_images_in_sequence(x) - 1L) * x$frame_step
}

#' Presentation time of the nth image (1-based)
#' @param x An \code{\link{ImageSequenceReference}}.
#' @param image_number 1-based image index.
#' @export
presentation_time_for_image_number <- function(x, image_number) {
    .rt_add(x$available_range$start_time,
            RationalTime((image_number - 1L) * x$frame_step, x$rate))
}

#' Target URL of the nth image (1-based)
#' @param x An \code{\link{ImageSequenceReference}}.
#' @param image_number 1-based image index.
#' @export
target_url_for_image_number <- function(x, image_number) {
    frame <- x$start_frame + (image_number - 1L) * x$frame_step
    num <- formatC(frame, width = x$frame_zero_padding, flag = "0",
                   format = "d")
    paste0(x$target_url_base, x$name_prefix, num, x$name_suffix)
}

