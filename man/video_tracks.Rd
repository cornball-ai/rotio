% tinyrox says don't edit this manually, but it can't stop you!
\name{video_tracks}
\alias{video_tracks}
\alias{audio_tracks}
\title{Video / audio tracks of a timeline}
\usage{
video_tracks(x)

audio_tracks(x)
}
\arguments{
\item{x}{A \code{\link{Timeline}}.}
}
\value{
A list of \code{\link{Track}}s of the matching kind.
}
\description{
Video / audio tracks of a timeline
}
\examples{
tl <- add_track(Timeline("demo"), Track("V1", kind = "Video"))
video_tracks(tl)
audio_tracks(tl)
}
