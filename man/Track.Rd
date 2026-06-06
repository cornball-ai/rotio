% tinyrox says don't edit this manually, but it can't stop you!
\name{Track}
\alias{Track}
\title{Construct a Track}
\usage{
Track(name, kind = "Video", source_range = NULL, metadata = NULL)
}
\arguments{
\item{name}{Track name.}

\item{kind}{\code{"Video"} (default) or \code{"Audio"}.}

\item{source_range}{Optional \code{\link{TimeRange}}.}

\item{metadata}{Named list of metadata.}
}
\value{
A \code{Track}.
}
\description{
An ordered sequence of items. Add children with \code{\link{add_child}} (or
the mutating \code{\link{append_child}}).
}
\examples{
Track("V1", kind = "Video")
}
