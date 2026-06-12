% tinyrox says don't edit this manually, but it can't stop you!
\name{visible_range}
\alias{visible_range}
\title{Visible range of an item (including adjacent transitions)}
\usage{
visible_range(x)
}
\arguments{
\item{x}{An item with a parent.}
}
\value{
A \code{\link{TimeRange}}.
}
\description{
Visible range of an item (including adjacent transitions)
}
\examples{
trk <- Track("V1")
cl <- Clip("a",
    source_range = TimeRange(RationalTime(0, 24), RationalTime(48, 24)))
append_child(trk, cl)
visible_range(cl)
}
