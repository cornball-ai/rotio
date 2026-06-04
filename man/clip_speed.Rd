% tinyrox says don't edit this manually, but it can't stop you!
\name{clip_speed}
\alias{clip_speed}
\title{Set a clip's playback speed (time-remap)}
\usage{
clip_speed(timeline, clip, speed)
}
\arguments{
\item{timeline}{An \code{nle_timeline}.}

\item{clip}{Clip id.}

\item{speed}{Playback multiplier (> 0).}
}
\value{
The updated timeline.
}
\description{
Records the speed as an OTIO \code{LinearTimeWarp} on the clip
(\code{time_scalar = speed}; >1 is faster). Modelled on OTIO: the warp is an
annotation, so it does not change the clip's timeline footprint — the source
range still defines what is shown, and a player / driver applies the rate.
Pass \code{speed = 1} to clear the warp.
}
