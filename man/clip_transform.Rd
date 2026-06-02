% tinyrox says don't edit this manually, but it can't stop you!
\name{clip_transform}
\alias{clip_transform}
\title{Set a clip's compositing transform (position, scale, rotation, opacity)}
\usage{
clip_transform(seq, clip, pos_x = NULL, pos_y = NULL, scale_x = NULL,
               scale_y = NULL, rotation_deg = NULL, opacity = NULL,
               coord = NULL, source_w = NULL, source_h = NULL)
}
\arguments{
\item{seq}{An \code{nle_sequence}.}

\item{clip}{Clip id.}

\item{rotation_deg}{Clockwise degrees, applied around the displayed
bbox centre after positioning; NULL to keep.}

\item{opacity}{Opacity 0-1; NULL to keep.}

\item{coord}{One of \code{"topleft"}, \code{"cartesian"},
\code{"center"}. Defaults to \code{options(nle.coords)} then
\code{"topleft"}.}

\item{pos_x,pos_y}{Position in the chosen coord system; NULL to keep.}

\item{scale_x,scale_y}{Per-axis scale; NULL to keep.}

\item{source_w,source_h}{Source dimensions in pixels, needed for
\code{coord = "cartesian"} or \code{"center"} when scale is set.
Defaults to the canvas size if not given.}
}
\description{
Position is given in the chosen coord system (default \code{"topleft"},
configurable via \code{options(nle.coords)}). Storage is always
canonical top-left + Y down.
}
