% tinyrox says don't edit this manually, but it can't stop you!
\name{value}
\alias{value}
\alias{rate}
\title{RationalTime value and rate}
\usage{
value(x)

rate(x)
}
\arguments{
\item{x}{A \code{RationalTime}.}
}
\value{
Numeric scalar, the time's value or rate.
}
\description{
RationalTime value and rate
}
\examples{
value(RationalTime(180, 30))
rate(RationalTime(180, 30))
}
