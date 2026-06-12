% tinyrox says don't edit this manually, but it can't stop you!
\name{trimmed_range_in_parent}
\alias{trimmed_range_in_parent}
\title{Range of an item within its parent, trimmed by the parent's source range}
\usage{
trimmed_range_in_parent(x)
}
\arguments{
\item{x}{An item with a parent.}
}
\value{
A \code{\link{TimeRange}}.
}
\description{
Range of an item within its parent, trimmed by the parent's source range
}
\examples{
trk <- Track("V1",
    source_range = TimeRange(RationalTime(12, 24), RationalTime(24, 24)))
cl <- Clip("a",
    source_range = TimeRange(RationalTime(0, 24), RationalTime(48, 24)))
append_child(trk, cl)
trimmed_range_in_parent(cl)
}
