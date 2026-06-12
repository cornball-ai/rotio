% tinyrox says don't edit this manually, but it can't stop you!
\name{parent}
\alias{parent}
\title{Parent of an OTIO object}
\usage{
parent(x)
}
\arguments{
\item{x}{An OTIO object.}
}
\value{
The parent object or \code{NULL}.
}
\description{
The containing composition/collection, or \code{NULL}. A Timeline's root track
Stack is parentless.
}
\examples{
trk <- Track("V1")
cl <- Clip("a")
append_child(trk, cl)
name(parent(cl))
}
