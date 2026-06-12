% tinyrox says don't edit this manually, but it can't stop you!
\name{from_time_string}
\alias{from_time_string}
\title{RationalTime from a time string ("HH:MM:SS.sss") at a rate}
\usage{
from_time_string(time_string, rate)
}
\arguments{
\item{time_string}{A time string.}

\item{rate}{Rate (fps).}
}
\value{
A \code{RationalTime}.
}
\description{
Preserves the fractional value (no rounding to a frame boundary).
}
\examples{
from_time_string("00:00:03.75", 24)
}
