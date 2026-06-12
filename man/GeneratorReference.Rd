% tinyrox says don't edit this manually, but it can't stop you!
\name{GeneratorReference}
\alias{GeneratorReference}
\title{Construct a GeneratorReference}
\usage{
GeneratorReference(name = "", generator_kind = "", available_range = NULL,
                   parameters = NULL, metadata = NULL)
}
\arguments{
\item{name}{Reference name.}

\item{generator_kind}{Generator kind (e.g. \code{"SMPTEBars"}).}

\item{available_range}{Optional \code{\link{TimeRange}}.}

\item{parameters}{Named list of generator parameters.}

\item{metadata}{Named list of metadata.}
}
\value{
A \code{GeneratorReference}.
}
\description{
Procedurally-generated media (color bars, solids, ...).
}
\examples{
GeneratorReference("bars", generator_kind = "SMPTEBars")
}
