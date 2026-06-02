% tinyrox says don't edit this manually, but it can't stop you!
\name{clip_set}
\alias{clip_set}
\title{Set a clip's mute, blend mode, or label}
\usage{
clip_set(seq, clip, mute = NULL, blend = NULL, label = NULL)
}
\arguments{
\item{seq}{An \code{nle_sequence}.}

\item{clip}{Clip id.}

\item{mute}{Logical; NULL to keep.}

\item{blend}{Blend mode (\code{"normal"}, \code{"alpha_over"}, ...);
NULL to keep.}

\item{label}{Label string; NULL to keep.}
}
\description{
Set a clip's mute, blend mode, or label
}
