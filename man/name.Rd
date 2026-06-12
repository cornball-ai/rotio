% tinyrox says don't edit this manually, but it can't stop you!
\name{name}
\alias{name}
\alias{name<-}
\title{Get or set the name of an OTIO object}
\usage{
name(x)

name(x) <- value
}
\arguments{
\item{x}{An OTIO object.}

\item{value}{New name.}
}
\value{
The object's name, a character string.
}
\description{
Get or set the name of an OTIO object
}
\examples{
cl <- Clip("a")
name(cl) <- "b"
name(cl)
}
