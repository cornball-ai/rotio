% tinyrox says don't edit this manually, but it can't stop you!
\name{end_frame}
\alias{end_frame}
\title{Last frame number of an ImageSequenceReference}
\usage{
end_frame(x)
}
\arguments{
\item{x}{An \code{\link{ImageSequenceReference}}.}
}
\value{
Integer frame number of the last image in the sequence.
}
\description{
Last frame number of an ImageSequenceReference
}
\examples{
isr <- ImageSequenceReference("file:///frames", "frame.", ".exr", rate = 24,
    available_range = TimeRange(RationalTime(0, 24), RationalTime(48, 24)))
end_frame(isr)
}
