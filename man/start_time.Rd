% tinyrox says don't edit this manually, but it can't stop you!
\name{start_time}
\alias{start_time}
\alias{duration}
\title{TimeRange start_time and duration}
\usage{
start_time(x)

duration(x)
}
\arguments{
\item{x}{A \code{TimeRange}.}
}
\value{
A \code{RationalTime}.
}
\description{
TimeRange start_time and duration
}
\examples{
tr <- TimeRange(RationalTime(0, 24), RationalTime(48, 24))
start_time(tr)
duration(tr)
}
