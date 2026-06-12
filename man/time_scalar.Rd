% tinyrox says don't edit this manually, but it can't stop you!
\name{time_scalar}
\alias{time_scalar}
\alias{time_scalar<-}
\title{Time scalar of a LinearTimeWarp}
\usage{
time_scalar(x)

time_scalar(x) <- value
}
\arguments{
\item{x}{A \code{\link{LinearTimeWarp}}.}

\item{value}{New time scalar.}
}
\value{
The numeric time scalar; the setter returns \code{x}.
}
\description{
Time scalar of a LinearTimeWarp
}
\examples{
w <- LinearTimeWarp(effect_name = "LinearTimeWarp", time_scalar = 2)
time_scalar(w)
}
