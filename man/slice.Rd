% tinyrox says don't edit this manually, but it can't stop you!
\name{slice}
\alias{slice}
\title{Slice an item in two at a time}
\usage{
slice(composition, time, remove_transitions = TRUE)
}
\arguments{
\item{composition}{A \code{\link{Track}} (or composition).}

\item{time}{A \code{\link{RationalTime}} to slice at.}

\item{remove_transitions}{Remove transitions at \code{time} (default TRUE).}
}
\value{
\code{composition}, invisibly.
}
\description{
Splits the item covering \code{time} into two adjacent items at that point.
Mutates \code{composition} in place. A slice exactly at an item boundary is a
no-op; slicing through a transition removes it (or errors if
\code{remove_transitions} is \code{FALSE}).
}
\examples{
trk <- Track("V1")
append_child(trk, Clip("a", source_range = TimeRange(RationalTime(0, 24),
                                                     RationalTime(48, 24))))
slice(trk, RationalTime(24, 24))
length(children(trk))
}
