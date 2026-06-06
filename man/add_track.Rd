% tinyrox says don't edit this manually, but it can't stop you!
\name{add_track}
\alias{add_track}
\title{Append a track to a timeline}
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
Returns a new timeline with \code{track} appended to its track stack. The
input is unchanged.
}
\examples{
tl <- Timeline("demo")
tl <- add_track(tl, Track("V1", kind = "Video"))
}
