% tinyrox says don't edit this manually, but it can't stop you!
\name{Gap}
\alias{Gap}
\title{Construct a Gap}
\usage{
Gap(duration, name = "", metadata = NULL)
}
\arguments{
\item{duration}{A \code{\link{RationalTime}}.}

\item{name}{Gap name.}

\item{metadata}{Named list of metadata.}
}
\value{
A \code{Gap}.
}
\description{
Empty space on a track of a given duration.
}
\examples{
Gap(RationalTime(15, 30))
}
