% tinyrox says don't edit this manually, but it can't stop you!
\name{add_child}
\alias{add_child}
\title{Append a child to a composition}
\usage{
add_child(parent, child)
}
\arguments{
\item{parent}{A \code{\link{Track}} or \code{\link{Stack}}.}

\item{child}{An item to append (clip, gap, or track for a stack).}
}
\value{
A new composition.
}
\description{
Returns a new composition (Track or Stack) with \code{child} appended. The
input is unchanged.
}
\examples{
v <- Track("V1", kind = "Video")
v <- add_child(v, Clip("a", ExternalReference("a.mp4")))
}
