% tinyrox says don't edit this manually, but it can't stop you!
\name{clip_duplicate}
\alias{clip_duplicate}
\title{Duplicate a clip}
\usage{
clip_duplicate(timeline, clip, tl_in = NULL, track = NULL, id = NULL)
}
\arguments{
\item{timeline}{An \code{nle_timeline}.}

\item{clip}{Clip id to copy.}

\item{tl_in}{New timeline in-point; NULL places it right after the original.}

\item{track}{Destination track id; NULL keeps the original's track.}

\item{id}{New clip id; auto-generated if NULL.}
}
\value{
The updated timeline.
}
\description{
Copies a clip (same source range) to a new timeline position. By default the
copy lands immediately after the original on the same track with an
auto-generated id.
}
