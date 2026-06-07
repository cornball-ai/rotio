% tinyrox says don't edit this manually, but it can't stop you!
\name{slip}
\alias{slip}
\title{Slip an item's source range}
\usage{
slip(item, delta)
}
\arguments{
\item{item}{An item (usually a clip).}

\item{delta}{A \code{\link{RationalTime}} to slip by.}
}
\value{
\code{item}, invisibly.
}
\description{
Shifts the item's \code{source_range} start by \code{delta} without changing
its duration or any surrounding item; clamps to the media available range when
present. Mutates \code{item} in place.
}
