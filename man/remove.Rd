% tinyrox says don't edit this manually, but it can't stop you!
\name{remove}
\alias{remove}
\title{Remove the item at a time, optionally leaving a gap}
\usage{
remove(composition, time, fill = TRUE, fill_template = NULL)
}
\arguments{
\item{composition}{A \code{\link{Track}} (or composition).}

\item{time}{A \code{\link{RationalTime}} within the item to remove.}

\item{fill}{Fill the hole with a gap/template (default TRUE).}

\item{fill_template}{Optional item to fill with (default a gap).}
}
\value{
\code{composition}, invisibly.
}
\description{
Removes the item covering \code{time}; if \code{fill}, replaces it with a gap
(or \code{fill_template}) of the same range, otherwise the neighbours
concatenate. Mutates \code{composition} in place.
}
