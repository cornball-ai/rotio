% tinyrox says don't edit this manually, but it can't stop you!
\name{source_range}
\alias{source_range}
\alias{source_range<-}
\title{Get or set an item's source range}
\usage{
source_range(x)

source_range(x) <- value
}
\arguments{
\item{x}{An item (clip, gap, track).}

\item{value}{A \code{\link{TimeRange}}.}
}
\value{
The item's \code{\link{TimeRange}}, or \code{NULL} if unset.
}
\description{
Get or set an item's source range
}
\examples{
cl <- Clip("a")
source_range(cl) <- TimeRange(RationalTime(0, 24), RationalTime(48, 24))
source_range(cl)
}
