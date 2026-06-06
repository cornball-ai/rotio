% tinyrox says don't edit this manually, but it can't stop you!
\name{frame_for_time}
\alias{frame_for_time}
\title{Frame for a time in an ImageSequenceReference}
\usage{
frame_for_time(x, time)
}
\arguments{
\item{x}{An \code{\link{ImageSequenceReference}}.}

\item{time}{A \code{\link{RationalTime}}.}
}
\description{
Errors if \code{time} falls outside the available range (matching OTIO).
}
