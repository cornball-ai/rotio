% tinyrox says don't edit this manually, but it can't stop you!
\name{MediaReference}
\alias{MediaReference}
\title{Construct a generic MediaReference}
\usage{
MediaReference(name = "", available_range = NULL, metadata = NULL)
}
\arguments{
\item{name}{Reference name.}

\item{available_range}{Optional \code{\link{TimeRange}}.}

\item{metadata}{Named list of metadata.}
}
\value{
A \code{MediaReference}.
}
\description{
Construct a generic MediaReference
}
\examples{
MediaReference("ref")
}
