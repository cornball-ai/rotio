% tinyrox says don't edit this manually, but it can't stop you!
\name{clip_move}
\alias{clip_move}
\title{Move a clip in time and/or to another track}
\usage{
clip_move(timeline, clip, tl_in = NULL, track = NULL)
}
\arguments{
\item{timeline}{An \code{nle_timeline}.}

\item{clip}{Clip id.}

\item{tl_in}{New timeline in-point; NULL to keep.}

\item{track}{New track id (must exist); NULL to keep.}
}
\description{
Move a clip in time and/or to another track
}
