% tinyrox says don't edit this manually, but it can't stop you!
\name{add_track}
\alias{add_track}
\title{Append a track to a timeline, functionally}
\usage{
add_track(timeline, track)
}
\arguments{
\item{timeline}{A \code{\link{Timeline}}.}

\item{track}{A \code{\link{Track}}.}
}
\value{
A new timeline.
}
\description{
Returns a new timeline (clone) with a clone of \code{track} appended to its
stack. Neither input is mutated.
}
\examples{
tl <- add_track(Timeline("demo"), Track("V1", kind = "Video"))
}
