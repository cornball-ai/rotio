% tinyrox says don't edit this manually, but it can't stop you!
\name{flatten_stack}
\alias{flatten_stack}
\title{Flatten a stack of tracks into a single track}
\usage{
flatten_stack(x)
}
\arguments{
\item{x}{A \code{\link{Stack}} or a list of \code{\link{Track}}s
(bottom-to-top).}
}
\value{
A flattened \code{\link{Track}}.
}
\description{
Composites top-down: the topmost track with a non-gap clip wins each segment;
gaps expose the tracks below. Returns a single \code{\link{Track}} of trimmed
clips and gaps.
}
