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
