% tinyrox says don't edit this manually, but it can't stop you!
\name{RationalTime}
\alias{RationalTime}
\title{Construct a RationalTime}
\usage{
RationalTime(value, rate = 1)
}
\arguments{
\item{value}{Time value (frame number for frame-based work). Coerced to double.}

\item{rate}{Rate (fps); must be > 0. Default 1.}
}
\value{
A \code{RationalTime} object.
}
\description{
An OpenTimelineIO \code{RationalTime} is a \code{value / rate} pair measured
in the rate's units. For frame-based editing \code{value} is the frame number
and \code{rate} is the frame rate.
}
\examples{
RationalTime(180, 30)   # frame 180 at 30 fps
}
