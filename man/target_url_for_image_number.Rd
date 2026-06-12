% tinyrox says don't edit this manually, but it can't stop you!
\name{target_url_for_image_number}
\alias{target_url_for_image_number}
\title{Target URL of the nth image (1-based)}
\usage{
target_url_for_image_number(x, image_number)
}
\arguments{
\item{x}{An \code{\link{ImageSequenceReference}}.}

\item{image_number}{1-based image index.}
}
\value{
The image URL as a string.
}
\description{
Target URL of the nth image (1-based)
}
\examples{
isr <- ImageSequenceReference("file:///frames", "frame.", ".exr",
    frame_zero_padding = 4, rate = 24,
    available_range = TimeRange(RationalTime(0, 24), RationalTime(48, 24)))
target_url_for_image_number(isr, 1)
}
