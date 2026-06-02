% tinyrox says don't edit this manually, but it can't stop you!
\name{clip_trim}
\alias{clip_trim}
\title{Trim a clip's visible range}
\usage{
clip_trim(seq, clip, tl_in = NULL, tl_out = NULL)
}
\arguments{
\item{seq}{An \code{nle_sequence}.}

\item{clip}{Clip id.}

\item{tl_in}{New left-edge timeline time; NULL to keep.}

\item{tl_out}{New right-edge timeline time; NULL to keep.}
}
\description{
Moving \code{tl_in} (left edge) shifts the source in-point so the
picture stays put. Moving \code{tl_out} (right edge) changes the
duration.
}
