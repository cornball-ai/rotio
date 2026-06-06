% tinyrox says don't edit this manually, but it can't stop you!
\name{trimmed_range}
\alias{trimmed_range}
\title{Trimmed range of an item}
\usage{
trimmed_range(x)
}
\arguments{
\item{x}{An item (clip, gap).}
}
\value{
A \code{\link{TimeRange}}.
}
\description{
The item's \code{source_range} if set, else (for a clip) the active media
reference's available range.
}
