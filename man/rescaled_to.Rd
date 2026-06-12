% tinyrox says don't edit this manually, but it can't stop you!
\name{rescaled_to}
\alias{rescaled_to}
\title{Rescale a RationalTime to a new rate}
\usage{
rescaled_to(x, new_rate)
}
\arguments{
\item{x}{A \code{RationalTime}.}

\item{new_rate}{Target rate (fps).}
}
\value{
A \code{RationalTime} at \code{new_rate}.
}
\description{
Rescale a RationalTime to a new rate
}
\examples{
rescaled_to(RationalTime(24, 24), 48)
}
