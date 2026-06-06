% tinyrox says don't edit this manually, but it can't stop you!
\name{add_child}
\alias{add_child}
\title{Append a child, functionally (clone + append)}
\usage{
add_child(parent, child)
}
\arguments{
\item{parent}{A composition (Track/Stack) or collection.}

\item{child}{An OTIO object.}
}
\value{
A new composition.
}
\description{
Returns a new composition: a clone of \code{parent} with a clone of
\code{child} appended. Neither input is mutated (cf. \code{\link{append_child}},
which mutates in place).
}
\examples{
v <- add_child(Track("V1"), Clip("a", ExternalReference("a.mp4")))
}
