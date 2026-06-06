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
\description{
\code{metadata(x)} reads the metadata object; \code{metadata(x) <- value}
returns a copy of \code{x} with metadata replaced (value semantics, so it
rebinds \code{x} in the caller).
}
