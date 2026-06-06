% tinyrox says don't edit this manually, but it can't stop you!
\name{append_child}
\alias{append_child}
\title{Append a child to a composition (in place)}
\usage{
append_child(x, child)
}
\arguments{
\item{x}{A composition or collection.}

\item{child}{An OTIO object with no parent.}
}
\value{
\code{x}, invisibly.
}
\description{
Mutates \code{x}, attaching \code{child} and setting its parent. Errors if
\code{child} already has a parent (use \code{\link{remove_child}} first, or
the functional \code{\link{add_child}}). Returns \code{x} invisibly.
}
\examples{
trk <- Track("V1")
append_child(trk, Clip("a", ExternalReference("a.mp4")))
length(children(trk))
}
