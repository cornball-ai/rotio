% tinyrox says don't edit this manually, but it can't stop you!
\name{set_child}
\alias{set_child}
\title{Replace the child at a position (in place)}
\usage{
set_child(x, index, child)
}
\arguments{
\item{x}{A composition or collection.}

\item{index}{1-based position.}

\item{child}{An OTIO object with no parent.}
}
\value{
\code{x}, invisibly.
}
\description{
Detaches the replaced child and attaches the new one. Returns \code{x}
invisibly.
}
\examples{
trk <- Track("V1")
append_child(trk, Clip("a"))
set_child(trk, 1, Clip("b"))
name(children(trk)[[1]])
}
