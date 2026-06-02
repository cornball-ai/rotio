% tinyrox says don't edit this manually, but it can't stop you!
\name{clip_crop}
\alias{clip_crop}
\title{Set a clip's crop (normalized 0-1 from each edge)}
\usage{
clip_crop(seq, clip, left = NULL, right = NULL, top = NULL, bottom = NULL)
}
\arguments{
\item{seq}{An \code{nle_sequence}.}

\item{clip}{Clip id.}

\item{left,right,top,bottom}{Normalized [0, 1] crop from each edge;
NULL to keep.}
}
\description{
Set a clip's crop (normalized 0-1 from each edge)
}
