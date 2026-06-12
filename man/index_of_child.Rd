% tinyrox says don't edit this manually, but it can't stop you!
\name{index_of_child}
\alias{index_of_child}
\title{1-based position of a child, or NA}
\usage{
index_of_child(x, child)
}
\arguments{
\item{x}{A composition or collection.}

\item{child}{An OTIO object.}
}
\value{
The 1-based integer position of \code{child} in \code{x}, or
  \code{NA_integer_} if it is not a direct child.
}
\description{
1-based position of a child, or NA
}
\examples{
trk <- Track("V1")
cl <- Clip("a")
append_child(trk, cl)
index_of_child(trk, cl)
}
