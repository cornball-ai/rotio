% tinyrox says don't edit this manually, but it can't stop you!
\name{Stack}
\alias{Stack}
\title{Construct a Stack}
\usage{
Stack(name = "tracks", source_range = NULL, metadata = NULL)
}
\arguments{
\item{name}{Stack name (default \code{"tracks"}).}

\item{source_range}{Optional \code{\link{TimeRange}}.}

\item{metadata}{Named list of metadata.}
}
\value{
A \code{Stack} object.
}
\description{
An OTIO \code{Stack} holds parallel tracks (the timeline's \code{tracks} is a
Stack). Add tracks with \code{\link{add_child}}.
}
