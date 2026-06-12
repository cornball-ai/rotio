% tinyrox says don't edit this manually, but it can't stop you!
\name{clamped}
\alias{clamped}
\title{Clamp a time or range into a bounding TimeRange}
\usage{
clamped(tr, other)
}
\arguments{
\item{tr}{The bounding \code{TimeRange}.}

\item{other}{A \code{RationalTime} or \code{TimeRange} to clamp.}
}
\value{
A clamped \code{RationalTime} or \code{TimeRange}, matching
  \code{other}.
}
\description{
\code{tr} is the bounding range; \code{other} is clamped into it (opentime
\code{TimeRange::clamped}).
}
\examples{
tr <- TimeRange(RationalTime(0, 24), RationalTime(48, 24))
clamped(tr, RationalTime(96, 24))
}
