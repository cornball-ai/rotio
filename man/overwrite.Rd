% tinyrox says don't edit this manually, but it can't stop you!
\name{overwrite}
\alias{overwrite}
\title{Overwrite a span of a composition with an item}
\usage{
overwrite(item, composition, range, remove_transitions = TRUE,
          fill_template = NULL)
}
\arguments{
\item{item}{The item to place (usually a clip).}

\item{composition}{A \code{\link{Track}} (or composition).}

\item{range}{A \code{\link{TimeRange}} to overwrite.}

\item{remove_transitions}{Remove transitions within \code{range} (default TRUE).}

\item{fill_template}{Optional gap template for holes.}
}
\value{
\code{composition}, invisibly.
}
\description{
Places \code{item} over \code{range} (in composition coordinates), partitioning
or removing the items it covers and filling any hole before/after with a gap
(or \code{fill_template}). Mutates \code{composition} in place.
}
