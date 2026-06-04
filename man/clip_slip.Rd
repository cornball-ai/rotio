% tinyrox says don't edit this manually, but it can't stop you!
\name{clip_slip}
\alias{clip_slip}
\title{Slip a clip's source content without moving it}
\usage{
clip_slip(timeline, clip, by)
}
\arguments{
\item{timeline}{An \code{nle_timeline}.}

\item{clip}{Clip id.}

\item{by}{Amount to shift the source in-point (positive = later in source).}
}
\value{
The updated timeline.
}
\description{
Shifts the clip's source in/out points by \code{by} while leaving its
timeline position and duration unchanged — the clip shows different source
content in the same slot. \code{by} accepts frames / seconds /
\code{rational_time}.
}
