% tinyrox says don't edit this manually, but it can't stop you!
\name{dump_sequence}
\alias{dump_sequence}
\title{Read a sequence in from a driver's backing store}
\usage{
dump_sequence(driver, ...)
}
\arguments{
\item{driver}{Driver name (string).}

\item{...}{Driver-specific arguments (e.g. \code{file = "scene.blend"}).}
}
\value{
An \code{nle_sequence}.
}
\description{
Dispatches to the registered driver's \code{dump} function.
}
\examples{
\dontrun{
library(blendR)  # registers "blender"
seq <- dump_sequence("blender")
}
}
