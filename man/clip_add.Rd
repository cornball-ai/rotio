% tinyrox says don't edit this manually, but it can't stop you!
\name{clip_add}
\alias{clip_add}
\title{Add a clip to a track}
\usage{
clip_add(seq, track, tl_in, tl_out, asset, kind = NULL, source_in = 0L,
         source_out = NULL, speed = 1, label = NULL, id = NULL)
}
\arguments{
\item{seq}{An \code{nle_sequence}.}

\item{track}{Target track id (must exist).}

\item{tl_in}{Timeline in-point.}

\item{tl_out}{Timeline out-point.}

\item{asset}{Source path or cornductor asset id.}

\item{kind}{Clip kind; defaults to the track's kind.}

\item{source_in}{Source media in-point (default 0).}

\item{source_out}{Source media out-point (default = source_in + (tl_out - tl_in) * speed).}

\item{speed}{Playback multiplier (default 1).}

\item{label}{Clip label; defaults to the clip id.}

\item{id}{Explicit clip id; auto-generated if NULL.}
}
\value{
The updated sequence.
}
\description{
Time inputs accept either integer frames at the sequence fps, numeric
seconds, or a \code{\link{rational_time}}.
}
