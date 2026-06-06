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
\description{
\code{tr} is the bounding range; \code{other} is clamped into it (opentime
\code{TimeRange::clamped}).
}
