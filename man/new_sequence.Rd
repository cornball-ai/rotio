% tinyrox says don't edit this manually, but it can't stop you!
\name{new_sequence}
\alias{new_sequence}
\alias{empty_tracks}
\alias{empty_clips}
\title{Construct an empty sequence}
\usage{
new_sequence(id = "untitled", fps = 30L, sample_rate = 48000L,
             canvas = c(1080L, 1080L), meta = list())

empty_tracks()

empty_clips()
}
\arguments{
\item{id}{Sequence id (string).}

\item{fps}{Integer frames per second (default 30). For non-integer
rates (23.976 etc.) pass a \code{\link{rational_time}}-style list
\code{list(num = 24000, den = 1001)}.}

\item{sample_rate}{Audio sample rate in Hz (default 48000).}

\item{canvas}{Length-2 integer vector \code{c(width, height)}.}

\item{meta}{Optional named list of metadata (title, notes, ...).}
}
\value{
A \code{nle_sequence} S3 object.
}
\description{
The sequence is nle.api's canonical S3 model: tracks, clips, timebase
(rational fps + sample rate), canvas (output dimensions), meta (title,
notes), and extensions (driver-specific lossless reservoirs).
Times on \code{clips} are integer frame counts at \code{timebase$fps}.
The JSON wire format expands each to a rational \code{\{num, den\}};
R-level math stays integer.
}
\examples{
seq <- new_sequence(id = "demo", fps = 30, canvas = c(1080, 1080))
}
