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
Composites top-down: starts from the topmost track and fills its holes (gaps
and disabled items) with content from the tracks below, recursing downward.
Transitions are preserved; a lower transition cut by a hole boundary errors
with "Cannot trim in the middle of a transition" (matching OTIO).
}
