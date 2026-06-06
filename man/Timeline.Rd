% tinyrox says don't edit this manually, but it can't stop you!
\name{Timeline}
\alias{Timeline}
\title{Construct a Timeline}
\usage{
Timeline(name = "", global_start_time = NULL, metadata = NULL)
}
\arguments{
\item{name}{Timeline name.}

\item{global_start_time}{Optional \code{\link{RationalTime}}.}

\item{metadata}{Named list of metadata.}
}
\value{
A \code{Timeline}.
}
\description{
Wraps a \code{\link{Stack}} of tracks. Add tracks with \code{\link{add_track}}.
}
\examples{
Timeline("demo")
}
