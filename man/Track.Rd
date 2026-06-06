% tinyrox says don't edit this manually, but it can't stop you!
\name{Track}
\alias{Track}
\title{Construct a Track}
\usage{
Track(name, kind = "Video", source_range = NULL, metadata = NULL)
}
\arguments{
\item{name}{Track name.}

\item{kind}{Track kind, \code{"Video"} (default) or \code{"Audio"}.}

\item{source_range}{Optional \code{\link{TimeRange}}.}

\item{metadata}{Named list of metadata.}
}
\value{
A \code{Track} object.
}
\description{
An OTIO \code{Track} is an ordered sequence of items (clips, gaps). Add
children with \code{\link{add_child}}.
}
\examples{
Track("V1", kind = "Video")
}
