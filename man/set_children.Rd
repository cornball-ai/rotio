% tinyrox says don't edit this manually, but it can't stop you!
\name{set_children}
\alias{set_children}
\alias{set_children<-}
\title{Replace all children (in place)}
\usage{
set_children(x, children)

set_children(x) <- value
}
\arguments{
\item{x}{A composition or collection.}

\item{children,value}{A list of parentless OTIO objects.}
}
\value{
\code{x} (invisibly from the function form).
}
\description{
Available as \code{set_children(x, kids)} and \code{set_children(x) <- kids}.
}
\examples{
trk <- Track("V1")
set_children(trk, list(Clip("a"), Clip("b")))
length(children(trk))
}
