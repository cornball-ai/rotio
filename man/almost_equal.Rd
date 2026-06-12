% tinyrox says don't edit this manually, but it can't stop you!
\name{almost_equal}
\alias{almost_equal}
\title{Are two RationalTimes almost equal?}
\usage{
almost_equal(a, b, delta = 0)
}
\arguments{
\item{delta}{Tolerance in \code{b}'s rate units (default 0).}

\item{a,b}{\code{RationalTime}s.}
}
\value{
Logical scalar.
}
\description{
Rescales \code{a} to \code{b}'s rate and compares to \code{b}'s value within
\code{delta} (in \code{b}'s rate units), matching opentime.
}
\examples{
almost_equal(RationalTime(24, 24), RationalTime(48, 48))
}
