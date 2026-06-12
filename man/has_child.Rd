% tinyrox says don't edit this manually, but it can't stop you!
\name{has_child}
\alias{has_child}
\title{Does a composition directly contain a child?}
\usage{
has_child(x, child)
}
\arguments{
\item{x}{A composition or collection.}

\item{child}{An OTIO object.}
}
\value{
\code{TRUE} if \code{child} is a direct child of \code{x}, else
  \code{FALSE}.
}
\description{
Does a composition directly contain a child?
}
\examples{
trk <- Track("V1")
cl <- Clip("a")
append_child(trk, cl)
has_child(trk, cl)
}
