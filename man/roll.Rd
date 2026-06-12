% tinyrox says don't edit this manually, but it can't stop you!
\name{roll}
\alias{roll}
\title{Roll an item, adjusting adjacent items to fit}
\usage{
roll(item, delta_in, delta_out)
}
\arguments{
\item{item}{An item (usually a clip).}

\item{delta_in,delta_out}{\code{\link{RationalTime}} adjustments.}
}
\value{
\code{item}, invisibly.
}
\description{
Adjusts the item's start by \code{delta_in} and exclusive end by
\code{delta_out}, absorbing the change into the neighbouring items' source
ranges (no new items are created); clamps to media available ranges. Mutates
in place.
}
\examples{
trk <- Track("V1")
a <- Clip("a", source_range = TimeRange(RationalTime(0, 24),
                                        RationalTime(24, 24)))
b <- Clip("b", source_range = TimeRange(RationalTime(24, 24),
                                        RationalTime(24, 24)))
append_child(trk, a)
append_child(trk, b)
roll(b, RationalTime(-6, 24), RationalTime(0, 24))
}
