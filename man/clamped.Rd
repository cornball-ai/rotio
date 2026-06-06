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
\code{tr} is the bounding range; \code{other} is clamped into it (matching
OTIO's \code{TimeRange::clamped}). For a \code{RationalTime} \code{other}:
clamp into \code{[tr.start, tr.end_inclusive]}. For a \code{TimeRange}
\code{other}: \code{start = max(other.start, tr.start)},
\code{duration = other.duration}, end capped to \code{tr}'s exclusive end.
}
