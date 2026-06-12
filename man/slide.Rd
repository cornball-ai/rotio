% tinyrox says don't edit this manually, but it can't stop you!
\name{slide}
\alias{slide}
\title{Slide an item, adjusting the previous item's duration}
\usage{
slide(item, delta)
}
\arguments{
\item{item}{An item (usually a clip).}

\item{delta}{A \code{\link{RationalTime}} to slide by.}
}
\value{
\code{item}, invisibly.
}
\description{
Moves the item's start by \code{delta} by changing the previous item's
duration; the item's own source range is unchanged. No-op for the first item.
Mutates in place.
}
\examples{
trk <- Track("V1")
append_child(trk, Gap(RationalTime(24, 24)))
cl <- Clip("a", source_range = TimeRange(RationalTime(0, 24),
                                         RationalTime(48, 24)))
append_child(trk, cl)
slide(cl, RationalTime(-6, 24))
}
