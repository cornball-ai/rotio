% tinyrox says don't edit this manually, but it can't stop you!
\name{almost_equal}
\alias{almost_equal}
\title{Are two RationalTimes almost equal?}
\usage{
almost_equal(a, b, delta = 0)
}
\arguments{
\item{delta}{Tolerance in \code{a}'s rate units (default 0).}

\item{a,b}{\code{RationalTime}s.}
}
\description{
Rescales \code{b} to \code{a}'s rate and compares values within \code{delta}
(in \code{a}'s rate units), matching OTIO.
}
