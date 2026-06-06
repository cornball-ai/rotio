% tinyrox says don't edit this manually, but it can't stop you!
\name{TimeRange}
\alias{TimeRange}
\title{Construct a TimeRange}
\usage{
TimeRange(start_time, duration)
}
\arguments{
\item{start_time}{A \code{RationalTime}.}

\item{duration}{A \code{RationalTime}.}
}
\value{
A \code{TimeRange}.
}
\description{
A \code{start_time} plus a \code{duration}, both \code{\link{RationalTime}}.
}
\examples{
TimeRange(RationalTime(0, 30), RationalTime(180, 30))
}
