% tinyrox says don't edit this manually, but it can't stop you!
\name{to_frames}
\alias{to_frames}
\title{Convert a rational_time to an integer frame count at a given fps}
\usage{
to_frames(x, fps)
}
\arguments{
\item{x}{A rational_time.}

\item{fps}{Integer frames per second.}
}
\description{
If \code{fps == x$den}, returns \code{x$num} exactly. Otherwise
rescales: \code{round(x$num * fps / x$den)}.
}
