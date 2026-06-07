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
