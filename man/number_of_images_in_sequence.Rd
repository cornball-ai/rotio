% tinyrox says don't edit this manually, but it can't stop you!
\name{number_of_images_in_sequence}
\alias{number_of_images_in_sequence}
\title{Number of images in an ImageSequenceReference}
\usage{
number_of_images_in_sequence(x)
}
\arguments{
\item{x}{An \code{\link{ImageSequenceReference}}.}
}
\value{
Integer count of images (0 if no available range is set).
}
\description{
Number of images in an ImageSequenceReference
}
\examples{
isr <- ImageSequenceReference("file:///frames", "frame.", ".exr", rate = 24,
    available_range = TimeRange(RationalTime(0, 24), RationalTime(48, 24)))
number_of_images_in_sequence(isr)
}
