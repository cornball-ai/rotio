% tinyrox says don't edit this manually, but it can't stop you!
\name{trim}
\alias{trim}
\title{Trim an item, filling the freed time with gap}
\usage{
trim(item, delta_in, delta_out, fill_template = NULL)
}
\arguments{
\item{item}{An item (usually a clip).}

\item{fill_template}{Optional item to fill freed time with (default a gap).}

\item{delta_in,delta_out}{\code{\link{RationalTime}} adjustments.}
}
\value{
\code{item}, invisibly.
}
\description{
Adjusts the item's start by \code{delta_in} (also extending the previous
item) and its exclusive end by \code{delta_out}, filling now-empty time with a
gap (or \code{fill_template}); an adjacent gap is grown instead. Mutates in
place.
}
