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
