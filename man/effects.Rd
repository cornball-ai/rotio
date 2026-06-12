% tinyrox says don't edit this manually, but it can't stop you!
\name{effects}
\alias{effects}
\title{Effects of an item or composition}
\usage{
effects(x)
}
\arguments{
\item{x}{An item or composition.}
}
\value{
A list of \code{\link{Effect}} objects.
}
\description{
Effects of an item or composition
}
\examples{
clip <- add_effect(Clip("a"), FreezeFrame())
effects(clip)
}
