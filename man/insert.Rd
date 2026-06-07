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
