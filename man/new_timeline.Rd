% tinyrox says don't edit this manually, but it can't stop you!
\name{new_timeline}
\alias{new_timeline}
\title{Construct an empty timeline}
\usage{
new_timeline(id = "untitled", fps = 30L, sample_rate = 48000L,
             canvas = c(1080L, 1080L))
}
\arguments{
\item{id}{Timeline id (becomes the OTIO Timeline name).}

\item{fps}{Frames per second (default 30). For non-integer rates pass a
\code{list(num = 24000, den = 1001)}.}

\item{sample_rate}{Audio sample rate in Hz (default 48000).}

\item{canvas}{Length-2 numeric \code{c(width, height)}.}
}
\value{
A \code{nle_timeline} S3 object wrapping a live OTIO Timeline.
}
\description{
The timeline is nle.api's canonical S3 model, backed by an OpenTimelineIO
Timeline. Times are integer frame counts at \code{fps}.
}
\examples{
timeline <- new_timeline(id = "demo", fps = 30, canvas = c(1080, 1080))
}
