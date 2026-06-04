% tinyrox says don't edit this manually, but it can't stop you!
\name{track_delete}
\alias{track_delete}
\title{Delete a track and all its clips}
\usage{
track_delete(timeline, track)
}
\arguments{
\item{timeline}{An \code{nle_timeline}.}

\item{track}{Track id to remove (must exist).}
}
\value{
The updated timeline.
}
\description{
Delete a track and all its clips
}
\examples{
tl <- new_timeline()
tl <- track_add(tl, "video", id = "v1")
tl <- track_delete(tl, "v1")
}
