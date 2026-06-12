% tinyrox says don't edit this manually, but it can't stop you!
\name{overlaps}
\alias{overlaps}
\title{Do two TimeRanges overlap (cross without containment)?}
\usage{
overlaps(tr, other, epsilon_s = .EPS)
}
\arguments{
\item{epsilon_s}{Tolerance in seconds.}

\item{tr,other}{\code{TimeRange}s.}
}
\value{
Logical scalar.
}
\description{
Do two TimeRanges overlap (cross without containment)?
}
\examples{
a <- TimeRange(RationalTime(0, 24), RationalTime(48, 24))
b <- TimeRange(RationalTime(24, 24), RationalTime(48, 24))
overlaps(a, b)
}
