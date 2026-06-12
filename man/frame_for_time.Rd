% tinyrox says don't edit this manually, but it can't stop you!
\name{frame_for_time}
\alias{frame_for_time}
\title{Frame for a time in an ImageSequenceReference}
\usage{
frame_for_time(x, time)
}
\arguments{
\item{x}{An \code{\link{ImageSequenceReference}}.}

\item{time}{A \code{\link{RationalTime}}.}
}
\value{
Integer frame number for \code{time}.
}
\description{
Errors if \code{time} falls outside the available range (matching OTIO).
}
\examples{
isr <- ImageSequenceReference("file:///frames", "frame.", ".exr", rate = 24,
    available_range = TimeRange(RationalTime(0, 24), RationalTime(48, 24)))
frame_for_time(isr, RationalTime(10, 24))
}
