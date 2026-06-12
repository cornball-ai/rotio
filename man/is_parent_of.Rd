% tinyrox says don't edit this manually, but it can't stop you!
\name{is_parent_of}
\alias{is_parent_of}
\title{Is x an ancestor of other?}
\usage{
is_parent_of(x, other)
}
\arguments{
\item{x}{A composition or collection.}

\item{other}{An OTIO object.}
}
\value{
\code{TRUE} if \code{x} appears anywhere in \code{other}'s parent
  chain, else \code{FALSE}.
}
\description{
Is x an ancestor of other?
}
\examples{
trk <- Track("V1")
cl <- Clip("a")
append_child(trk, cl)
is_parent_of(trk, cl)
}
