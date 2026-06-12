% tinyrox says don't edit this manually, but it can't stop you!
\name{insert}
\alias{insert}
\title{Insert an item at a time, splitting the item it lands in}
\usage{
insert(item, composition, time, remove_transitions = TRUE, fill_template = NULL)
}
\arguments{
\item{item}{The item to insert (usually a clip).}

\item{composition}{A \code{\link{Track}} (or composition).}

\item{time}{A \code{\link{RationalTime}} to insert at.}

\item{remove_transitions}{Remove transitions at \code{time} (default TRUE).}

\item{fill_template}{Optional gap template when appending past the end.}
}
\value{
\code{composition}, invisibly.
}
\description{
Inserts \code{item} at \code{time}, splitting whatever item spans that point;
before the start it prepends, past the end it appends (filling any gap).
Mutates \code{composition} in place.
}
\examples{
trk <- Track("V1")
append_child(trk, Clip("a", source_range = TimeRange(RationalTime(0, 24),
                                                     RationalTime(48, 24))))
cl <- Clip("b", source_range = TimeRange(RationalTime(0, 24),
                                         RationalTime(12, 24)))
insert(cl, trk, RationalTime(24, 24))
length(children(trk))
}
