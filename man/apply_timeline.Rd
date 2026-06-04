% tinyrox says don't edit this manually, but it can't stop you!
\name{apply_timeline}
\alias{apply_timeline}
\title{Push a timeline into a driver's backing store}
\usage{
apply_timeline(driver, timeline, ...)
}
\arguments{
\item{driver}{Driver name (string).}

\item{timeline}{An \code{nle_timeline}.}

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
timeline <- read_timeline("timeline.md")
apply_timeline("blender", timeline)
}
}
