% tinyrox says don't edit this manually, but it can't stop you!
\name{dump_timeline}
\alias{dump_timeline}
\title{Read a timeline in from a driver's backing store}
\usage{
dump_timeline(driver, ...)
}
\arguments{
\item{driver}{Driver name (string).}

\item{...}{Driver-specific arguments (e.g. \code{file = "scene.blend"}).}
}
\value{
An \code{nle_timeline}.
}
\description{
Dispatches to the registered driver's \code{dump} function.
}
\examples{
\dontrun{
library(blendR)  # registers "blender"
timeline <- dump_timeline("blender")
}
}
