% tinyrox says don't edit this manually, but it can't stop you!
\name{visible}
\alias{visible}
\title{Is an item visible?}
\usage{
visible(x)
}
\arguments{
\item{x}{An item.}
}
\value{
Logical scalar.
}
\description{
A Gap is never visible; a Transition always is; any other item is visible
when enabled (matching OTIO).
}
\examples{
visible(Gap(RationalTime(24, 24)))
visible(Clip("a", ExternalReference("a.mp4")))
}
