% tinyrox says don't edit this manually, but it can't stop you!
\name{has_clips}
\alias{has_clips}
\title{Does an object contain any clips (recursive)?}
\usage{
has_clips(x)
}
\arguments{
\item{x}{A Timeline, composition, or collection.}
}
\value{
\code{TRUE} if \code{x} contains at least one clip, else \code{FALSE}.
}
\description{
Does an object contain any clips (recursive)?
}
\examples{
trk <- Track("V1")
append_child(trk, Clip("a"))
has_clips(trk)
}
