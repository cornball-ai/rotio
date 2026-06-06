% tinyrox says don't edit this manually, but it can't stop you!
\name{range_in_parent}
\alias{range_in_parent}
\title{Range of an item within its parent composition}
\usage{
range_in_parent(x)
}
\arguments{
\item{x}{An item with a parent.}
}
\value{
A \code{\link{TimeRange}} in the parent's coordinates.
}
\description{
Computed from the durations of the preceding siblings (gaps included). The
duration is the item's trimmed duration.
}
