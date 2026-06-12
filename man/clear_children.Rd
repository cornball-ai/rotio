% tinyrox says don't edit this manually, but it can't stop you!
\name{clear_children}
\alias{clear_children}
\title{Remove all children (in place)}
\usage{
clear_children(x)
}
\arguments{
\item{x}{A composition or collection.}
}
\value{
\code{x}, invisibly.
}
\description{
Remove all children (in place)
}
\examples{
trk <- Track("V1")
append_child(trk, Clip("a"))
clear_children(trk)
length(children(trk))
}
