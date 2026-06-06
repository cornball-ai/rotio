% tinyrox says don't edit this manually, but it can't stop you!
\name{RationalTime}
\alias{RationalTime}
\title{Construct a RationalTime}
\usage{
RationalTime(value, rate = 1)
}
\arguments{
\item{value}{Time value. Coerced to double.}

\item{rate}{Rate (fps); must be > 0. Default 1.}
}
\value{
A \code{RationalTime}.
}
\description{
A \code{value / rate} pair measured in the rate's units (frame number / fps
for frame-based work).
}
\examples{
RationalTime(180, 30)
}
