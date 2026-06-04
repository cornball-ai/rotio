% tinyrox says don't edit this manually, but it can't stop you!
\name{track_move}
\alias{track_move}
\title{Move a track to a new position (compositing order)}
\usage{
track_move(timeline, track, to)
}
\arguments{
\item{timeline}{An \code{nle_timeline}.}

\item{track}{Track id to move (must exist).}

\item{to}{New 1-based position among the tracks.}
}
\value{
The updated timeline.
}
\description{
Track order is compositing order: position 1 is the first track in the
stack. \code{to} is the 1-based destination index.
}
