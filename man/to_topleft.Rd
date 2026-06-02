% tinyrox says don't edit this manually, but it can't stop you!
\name{to_topleft}
\alias{to_topleft}
\title{Convert (pos_x, pos_y) from a user coord system to canonical top-left}
\usage{
to_topleft(pos_x, pos_y, coord, canvas_w, canvas_h, displayed_w, displayed_h)
}
\arguments{
\item{coord}{User coord system: \code{"topleft"}, \code{"cartesian"},
or \code{"center"}.}

\item{pos_x,pos_y}{Numeric. Position in user's coord system.}

\item{canvas_w,canvas_h}{Canvas size in pixels.}

\item{displayed_w,displayed_h}{Displayed clip size in pixels.}
}
\value{
Length-2 named numeric vector \code{c(pos_x, pos_y)} in canonical
  top-left.
}
\description{
Canonical storage is \code{"topleft"}: pos_x/pos_y is the top-left
corner of the displayed unrotated bounding box in canvas pixels, with
Y growing downward. This helper converts user input given in any of
the three supported coord systems to canonical form.
\code{displayed_w} and \code{displayed_h} are the post-scale clip
dimensions in pixels; they're required for \code{"cartesian"} and
\code{"center"} so we can position the displayed bounding box rather
than an abstract anchor point.
}
