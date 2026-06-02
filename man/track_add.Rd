% tinyrox says don't edit this manually, but it can't stop you!
\name{track_add}
\alias{track_add}
\title{Add a track}
\usage{
track_add(seq, kind, label = NULL, id = NULL, idx = NULL)
}
\arguments{
\item{seq}{An \code{nle_sequence}.}

\item{kind}{One of \code{"video"}, \code{"audio"}, \code{"image"},
\code{"subtitle"}.}

\item{label}{Track label; defaults to the track id.}

\item{id}{Explicit track id; auto-generated from \code{kind} if NULL.}

\item{idx}{Lane index; defaults to below the current bottom track.}
}
\value{
The updated sequence.
}
\description{
Add a track
}
\examples{
seq <- new_sequence()
seq <- track_add(seq, "video")
seq <- track_add(seq, "audio")
nrow(seq$tracks)
}
