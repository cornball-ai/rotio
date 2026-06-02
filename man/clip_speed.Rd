% tinyrox says don't edit this manually, but it can't stop you!
\name{clip_speed}
\alias{clip_speed}
\title{Set a clip's playback speed (time-remap)}
\usage{
clip_speed(seq, clip, speed)
}
\arguments{
\item{seq}{An \code{nle_sequence}.}

\item{clip}{Clip id.}

\item{speed}{Playback multiplier (> 0; >1 is faster/shorter).}
}
\description{
Keeps the source span fixed and rescales the timeline duration, so
speeding a clip up shortens it. Re-anchors at the clip's current
\code{tl_in}.
}
