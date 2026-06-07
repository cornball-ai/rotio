% tinyrox says don't edit this manually, but it can't stop you!
\name{to_timecode}
\alias{to_timecode}
\title{SMPTE timecode for a RationalTime}
\usage{
to_timecode(x, rate = NULL, drop_frame = NULL)
}
\arguments{
\item{x}{A \code{RationalTime}.}

\item{rate}{Timecode rate (default \code{x}'s rate).}

\item{drop_frame}{Drop-frame timecode. \code{NULL} (default) infers it from the
rate (on for 30000/1001 and 60000/1001), matching opentime's
\code{InferFromRate}; pass \code{TRUE}/\code{FALSE} to force.}
}
\description{
SMPTE timecode for a RationalTime
}
