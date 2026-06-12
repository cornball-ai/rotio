% tinyrox says don't edit this manually, but it can't stop you!
\name{contains}
\alias{contains}
\title{Does a TimeRange contain a time or range?}
\usage{
contains(tr, other, epsilon_s = .EPS)
}
\arguments{
\item{tr}{A \code{TimeRange}.}

\item{other}{A \code{RationalTime} or \code{TimeRange}.}

\item{epsilon_s}{Tolerance in seconds.}
}
\value{
Logical scalar.
}
\description{
For a \code{RationalTime}: \code{start <= t < end_exclusive}. For a
\code{TimeRange}: the other range lies strictly within on both ends (tolerance
\code{epsilon_s}).
}
\examples{
tr <- TimeRange(RationalTime(0, 24), RationalTime(48, 24))
contains(tr, RationalTime(12, 24))
}
