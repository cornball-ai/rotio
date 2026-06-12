% tinyrox says don't edit this manually, but it can't stop you!
\name{global_start_time}
\alias{global_start_time}
\alias{global_start_time<-}
\title{Global start time of a timeline}
\usage{
global_start_time(x)

global_start_time(x) <- value
}
\arguments{
\item{x}{A \code{\link{Timeline}}.}

\item{value}{A \code{\link{RationalTime}} or \code{NULL}.}
}
\value{
The timeline's global start time (a \code{\link{RationalTime}} or
  \code{NULL}); the setter returns \code{x}.
}
\description{
Global start time of a timeline
}
\examples{
tl <- Timeline("demo")
global_start_time(tl) <- RationalTime(0, 24)
global_start_time(tl)
}
