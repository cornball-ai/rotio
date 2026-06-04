% tinyrox says don't edit this manually, but it can't stop you!
\name{track_add}
\alias{track_add}
\title{Add a track}
\usage{
track_add(timeline, kind, label = NULL, id = NULL, idx = NULL)
}
\arguments{
\item{timeline}{An \code{nle_timeline}.}

\item{kind}{One of \code{"video"}, \code{"audio"}, \code{"image"},
\code{"subtitle"}.}

\item{label}{Ignored for now (track labels return with metadata in PR 4).}

\item{id}{Explicit track id; auto-generated from \code{kind} if NULL.}

\item{idx}{Ignored for now; tracks append in order.}
}
\value{
The updated timeline.
}
\description{
Add a track
}
\examples{
timeline <- new_timeline()
timeline <- track_add(timeline, "video")
nrow(timeline$tracks)
}
