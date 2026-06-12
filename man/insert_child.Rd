% tinyrox says don't edit this manually, but it can't stop you!
\name{insert_child}
\alias{insert_child}
\title{Insert a child at a 1-based position (in place)}
\usage{
insert_child(x, index, child)
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
Insert a child at a 1-based position (in place)
}
\examples{
trk <- Track("V1")
append_child(trk, Clip("b"))
insert_child(trk, 1, Clip("a"))
name(children(trk)[[1]])
}
