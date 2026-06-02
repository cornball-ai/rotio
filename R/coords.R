#' Resolve the coords argument
#'
#' Most user-facing verbs accept a \code{coord} argument. When NULL, the
#' value falls back to \code{options(nle.coords)} and then to the
#' canonical \code{"topleft"}.
#'
#' @param coord Optional character: \code{"topleft"}, \code{"cartesian"},
#'   or \code{"center"}.
#' @return One of the three valid values.
#' @export
resolve_coords <- function(coord = NULL) {
    if (is.null(coord)) {
        coord <- getOption("nle.coords", "topleft")
    }
    coord <- match.arg(coord, c("topleft", "cartesian", "center"))
    coord
}

#' Convert (pos_x, pos_y) from a user coord system to canonical top-left
#'
#' Canonical storage is \code{"topleft"}: pos_x/pos_y is the top-left
#' corner of the displayed unrotated bounding box in canvas pixels, with
#' Y growing downward. This helper converts user input given in any of
#' the three supported coord systems to canonical form.
#'
#' \code{displayed_w} and \code{displayed_h} are the post-scale clip
#' dimensions in pixels; they're required for \code{"cartesian"} and
#' \code{"center"} so we can position the displayed bounding box rather
#' than an abstract anchor point.
#'
#' @param pos_x,pos_y Numeric. Position in user's coord system.
#' @param coord User coord system: \code{"topleft"}, \code{"cartesian"},
#'   or \code{"center"}.
#' @param canvas_w,canvas_h Canvas size in pixels.
#' @param displayed_w,displayed_h Displayed clip size in pixels.
#' @return Length-2 named numeric vector \code{c(pos_x, pos_y)} in canonical
#'   top-left.
#' @export
to_topleft <- function(pos_x, pos_y, coord,
                       canvas_w, canvas_h,
                       displayed_w, displayed_h) {
    coord <- resolve_coords(coord)
    switch(coord,
        topleft = c(pos_x = pos_x, pos_y = pos_y),
        cartesian = c(pos_x = pos_x,
                      pos_y = canvas_h - pos_y - displayed_h),
        center    = c(pos_x = canvas_w / 2 + pos_x - displayed_w / 2,
                      pos_y = canvas_h / 2 - pos_y - displayed_h / 2)
    )
}

#' Convert canonical top-left (pos_x, pos_y) to a user coord system
#'
#' Inverse of \code{\link{to_topleft}}.
#'
#' @inheritParams to_topleft
#' @export
from_topleft <- function(pos_x, pos_y, coord,
                         canvas_w, canvas_h,
                         displayed_w, displayed_h) {
    coord <- resolve_coords(coord)
    switch(coord,
        topleft = c(pos_x = pos_x, pos_y = pos_y),
        cartesian = c(pos_x = pos_x,
                      pos_y = canvas_h - pos_y - displayed_h),
        center    = c(pos_x = pos_x + displayed_w / 2 - canvas_w / 2,
                      pos_y = canvas_h / 2 - pos_y - displayed_h / 2)
    )
}
