% tinyrox says don't edit this manually, but it can't stop you!
\name{clone}
\alias{clone}
\title{Deep-clone an OTIO object}
\usage{
clone(x)
}
\arguments{
\item{x}{An OTIO object.}
}
\value{
A deep copy.
}
\description{
Returns a deep copy of \code{x}. The clone's parent is reset to \code{NULL}
and its descendants' parent pointers are rewired inside the clone, so it is a
fully detached, internally consistent subtree.
}
\examples{
tl <- add_track(Timeline("a"), Track("V1"))
tl2 <- clone(tl)
}
