% tinyrox says don't edit this manually, but it can't stop you!
\name{Gap}
\alias{Gap}
\title{Construct a Gap}
\usage{
Gap(duration, name = "", metadata = NULL)
}
\arguments{
\item{duration}{A \code{\link{RationalTime}} for the gap length.}

\item{name}{Gap name.}

\item{metadata}{Named list of metadata.}
}
\value{
A \code{Gap} object.
}
\description{
A \code{Gap} is empty space on a track of a given duration.
}
\examples{
Gap(RationalTime(15, 30))
}
