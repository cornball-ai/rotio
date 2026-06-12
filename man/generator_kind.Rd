% tinyrox says don't edit this manually, but it can't stop you!
\name{generator_kind}
\alias{generator_kind}
\alias{generator_kind<-}
\title{Generator kind of a GeneratorReference}
\usage{
generator_kind(x)

generator_kind(x) <- value
}
\arguments{
\item{x}{A \code{\link{GeneratorReference}}.}

\item{value}{New generator kind.}
}
\value{
The generator kind string; the setter returns \code{x}.
}
\description{
Generator kind of a GeneratorReference
}
\examples{
g <- GeneratorReference("bars", generator_kind = "SMPTEBars")
generator_kind(g)
}
