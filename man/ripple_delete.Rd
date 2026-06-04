% tinyrox says don't edit this manually, but it can't stop you!
\name{ripple_delete}
\alias{ripple_delete}
\title{Ripple-delete a clip (delete and close the gap)}
\usage{
ripple_delete(timeline, clip)
}
\arguments{
\item{timeline}{An \code{nle_timeline}.}

\item{clip}{Clip id.}
}
\value{
The updated timeline.
}
\description{
Removes the clip and pulls every later clip on the same track earlier by the
deleted clip's duration, so no gap is left. Contrast \code{clip_delete},
which leaves a gap.
}
