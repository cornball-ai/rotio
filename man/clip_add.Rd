% tinyrox says don't edit this manually, but it can't stop you!
\name{clip_add}
\alias{clip_add}
\title{Add a clip to a track}
\usage{
clip_add(timeline, track, tl_in, tl_out, asset, kind = NULL, source_in = 0L,
         source_out = NULL, speed = 1, label = NULL, id = NULL)
}
\arguments{
\item{timeline}{An \code{nle_timeline}.}

\item{track}{Target track id (must exist).}

\item{asset}{Source path or media url.}

\item{kind}{Unused (clip kind follows its track).}

\item{source_in}{Source media in-point (default 0).}

\item{source_out}{Source media out-point; default keeps clip duration.}

\item{speed}{Must be 1 in this release; time-remap arrives in PR 4.}

\item{tl_in,tl_out}{Timeline in/out points.}

\item{label,id}{Optional; \code{id} auto-generated if NULL.}
}
\value{
The updated timeline.
}
\description{
Time inputs accept integer frames at the timeline fps, numeric seconds, or a
\code{rational_time} / \code{otio_time}.
}
