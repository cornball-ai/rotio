% tinyrox says don't edit this manually, but it can't stop you!
\name{from_frames}
\alias{from_frames}
\title{Construct a RationalTime from a frame number at a rate}
\usage{
from_frames(frame, rate)
}
\arguments{
\item{frame}{Integer frame number.}

\item{rate}{Rate (fps).}
}
\value{
A \code{RationalTime}.
}
\description{
Construct a RationalTime from a frame number at a rate
}
\examples{
from_frames(48, 24)
}
