% tinyrox says don't edit this manually, but it can't stop you!
\name{presentation_time_for_image_number}
\alias{presentation_time_for_image_number}
\title{Presentation time of the nth image (1-based)}
\usage{
presentation_time_for_image_number(x, image_number)
}
\arguments{
\item{x}{An \code{\link{ImageSequenceReference}}.}

\item{image_number}{1-based image index.}
}
\value{
A \code{\link{RationalTime}} at the reference's rate.
}
\description{
Presentation time of the nth image (1-based)
}
\examples{
isr <- ImageSequenceReference("file:///frames", "frame.", ".exr", rate = 24,
    available_range = TimeRange(RationalTime(0, 24), RationalTime(48, 24)))
presentation_time_for_image_number(isr, 2)
}
