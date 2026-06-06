# OTIOD bundle I/O.
#
# An OTIOD ("OTIO directory") bundle is a directory holding a content.otio file
# plus a media/ subdirectory, with media references kept relative to the bundle.
# This is the artifact compost renders and the cornyverse pipeline produces one
# per track.

#' Read an OTIOD bundle
#'
#' Reads \code{<dir>/content.otio} into the object model. Media references stay
#' relative to the bundle directory.
#'
#' @param dir Bundle directory.
#' @return The bundle's OTIO object (typically a \code{\link{Timeline}}).
#' @export
read_otiod <- function(dir) {
    otio <- file.path(dir, "content.otio")
    if (!file.exists(otio)) {
        stop("read_otiod: no content.otio in ", dir, call. = FALSE)
    }
    from_json_file(otio)
}

#' Write an OTIOD bundle
#'
#' Writes \code{timeline} to \code{<dir>/content.otio} and ensures a
#' \code{media/} subdirectory exists. Optionally copies \code{media} files into
#' it. Media references inside \code{timeline} should already be relative paths
#' (e.g. \code{"media/clip01.mp4"}); this writer does not rewrite them.
#'
#' @param timeline A \code{\link{Timeline}}.
#' @param dir Bundle directory (created if needed).
#' @param media Optional character vector of media files to copy into
#'   \code{<dir>/media/}.
#' @param indent Indent width for content.otio (default 2).
#' @return The path to the written \code{content.otio}, invisibly.
#' @export
write_otiod <- function(timeline, dir, media = NULL, indent = 2) {
    if (!is_timeline(timeline)) {
        stop("write_otiod: timeline must be a Timeline", call. = FALSE)
    }
    media_dir <- file.path(dir, "media")
    dir.create(media_dir, showWarnings = FALSE, recursive = TRUE)
    if (length(media)) {
        file.copy(media, media_dir, overwrite = TRUE)
    }
    to_json_file(timeline, file.path(dir, "content.otio"), indent = indent)
}

