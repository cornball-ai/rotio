% tinyrox says don't edit this manually, but it can't stop you!
\name{to_frames}
\alias{to_frames}
\title{Frame number of a RationalTime}
\usage{
to_frames(x, rate = NULL)
}
\arguments{
\item{x}{A \code{RationalTime}.}

\item{rate}{Optional target rate to rescale to first.}
}
\description{
Integer frame number. With no \code{rate}, rounds at the time's own rate; with
a \code{rate}, rescales first.
}
