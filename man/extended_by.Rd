% tinyrox says don't edit this manually, but it can't stop you!
\name{extended_by}
\alias{extended_by}
\title{Smallest TimeRange covering two ranges}
\usage{
extended_by(tr, other)
}
\arguments{
\item{tr,other}{\code{TimeRange}s.}
}
\value{
A \code{TimeRange}.
}
\description{
Smallest TimeRange covering two ranges
}
\examples{
a <- TimeRange(RationalTime(0, 24), RationalTime(48, 24))
b <- TimeRange(RationalTime(24, 24), RationalTime(48, 24))
extended_by(a, b)
}
