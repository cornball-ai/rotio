% tinyrox says don't edit this manually, but it can't stop you!
\name{from_timecode}
\alias{from_timecode}
\title{RationalTime from a SMPTE timecode}
\usage{
from_timecode(timecode, rate)
}
\arguments{
\item{timecode}{A \code{"HH:MM:SS:FF"} (or \code{";FF"} for drop-frame) string.}

\item{rate}{Timecode rate.}
}
\description{
A \code{;} frame separator is treated as drop-frame.
}
