% tinyrox says don't edit this manually, but it can't stop you!
\name{clip_trim}
\alias{clip_trim}
\title{Trim a clip's visible range}
\usage{
clip_trim(timeline, clip, tl_in = NULL, tl_out = NULL)
}
\arguments{
\item{timeline}{An \code{nle_timeline}.}

\item{clip}{Clip id.}

\item{tl_in,tl_out}{New edge times; NULL to keep.}
}
\description{
Moving \code{tl_in} (left edge) shifts the source in-point so the picture
stays put. Moving \code{tl_out} (right edge) changes the duration.
}
