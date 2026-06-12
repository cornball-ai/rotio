% tinyrox says don't edit this manually, but it can't stop you!
\name{parameters}
\alias{parameters}
\alias{parameters<-}
\title{Parameters of a GeneratorReference}
\usage{
parameters(x)

parameters(x) <- value
}
\arguments{
\item{x}{A \code{\link{GeneratorReference}}.}

\item{value}{A named list of parameters.}
}
\value{
A named list of generator parameters; the setter returns \code{x}.
}
\description{
Parameters of a GeneratorReference
}
\examples{
g <- GeneratorReference("bars", parameters = list(width = 1920))
parameters(g)
}
