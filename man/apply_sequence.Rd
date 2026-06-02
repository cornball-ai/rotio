% tinyrox says don't edit this manually, but it can't stop you!
\name{apply_sequence}
\alias{apply_sequence}
\title{Push a sequence into a driver's backing store}
\usage{
apply_sequence(driver, seq, ...)
}
\arguments{
\item{driver}{Driver name (string).}

\item{seq}{An \code{nle_sequence}.}

\item{...}{Driver-specific arguments.}
}
\value{
Invisibly whatever the driver returns.
}
\description{
Dispatches to the registered driver's \code{apply} function.
}
\examples{
\dontrun{
library(blendR)
seq <- read_sequence("sequence.md")
apply_sequence("blender", seq)
}
}
