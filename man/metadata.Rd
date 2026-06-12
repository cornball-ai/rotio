% tinyrox says don't edit this manually, but it can't stop you!
\name{metadata}
\alias{metadata}
\alias{metadata<-}
\title{Get or set object metadata}
\usage{
metadata(x)

metadata(x) <- value
}
\arguments{
\item{x}{An OTIO object.}

\item{value}{A named list.}
}
\value{
The object's metadata as a named list (possibly empty).
}
\description{
Get or set object metadata
}
\examples{
cl <- Clip("a")
metadata(cl) <- list(note = "take 2")
metadata(cl)
}
