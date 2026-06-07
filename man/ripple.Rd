% tinyrox says don't edit this manually, but it can't stop you!
\name{ripple}
\alias{ripple}
\title{Ripple an item's source range}
\usage{
ripple(item, delta_in, delta_out)
}
\arguments{
\item{item}{An item (usually a clip).}

\item{delta_in,delta_out}{\code{\link{RationalTime}} adjustments to the start
and exclusive end.}
}
\value{
\code{item}, invisibly.
}
\description{
Adjusts the item's \code{source_range} start by \code{delta_in} and exclusive
end by \code{delta_out} without moving any other item. Mutates in place.
}
