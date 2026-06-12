% tinyrox says don't edit this manually, but it can't stop you!
\name{find_clips}
\alias{find_clips}
\title{All clips within an object (recursive)}
\usage{
find_clips(x)
}
\arguments{
\item{x}{A Timeline, composition, or collection.}
}
\value{
A list of \code{Clip} objects.
}
\description{
All clips within an object (recursive)
}
\examples{
trk <- Track("V1")
append_child(trk, Clip("a"))
length(find_clips(trk))
}
