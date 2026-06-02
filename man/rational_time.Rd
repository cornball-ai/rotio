% tinyrox says don't edit this manually, but it can't stop you!
\name{rational_time}
\alias{rational_time}
\title{Construct a rational time value}
\usage{
rational_time(num, den = 1L)
}
\arguments{
\item{num}{Integer numerator.}

\item{den}{Integer denominator (default 1; must be > 0).}
}
\value{
A list with class \code{rational_time}.
}
\description{
nle.api stores every time value as a rational \code{num/den} in
seconds so that frame-exact round-trips are possible without
floating-point drift. Both components must be integers; \code{den}
must be positive.
}
\examples{
rational_time(4918, 30)             # frame 4918 at 30 fps -> 163.93s
rational_time(60, 1)                # one minute
}
