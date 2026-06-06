% tinyrox says don't edit this manually, but it can't stop you!
\name{Effect}
\alias{Effect}
\alias{LinearTimeWarp}
\title{Construct an OTIO effect}
\usage{
Effect(name = "", effect_name = "", enabled = TRUE, metadata = NULL)

LinearTimeWarp(name = "", effect_name = "", time_scalar = 1, enabled = TRUE,
               metadata = NULL)
}
\arguments{
\item{name}{Effect instance name (default empty).}

\item{effect_name}{Effect kind label (default empty, matching OTIO). Callers
set this to a driver-recognized name (e.g. \code{"LinearTimeWarp"}).}

\item{enabled}{Whether the effect is active (default \code{TRUE}).}

\item{metadata}{Named list of parameters (serialized as a JSON object).}

\item{time_scalar}{Linear time scale (playback rate multiplier).}
}
\value{
An \code{Effect} object.
}
\description{
A generic \code{Effect} is an \code{effect_name} (the driver-facing label) plus
a metadata dictionary of parameters. \code{LinearTimeWarp} is OTIO's linear
speed change, carrying a \code{time_scalar} (>1 faster, <1 slower).
}
\examples{
Effect("blur", "GaussianBlur", metadata = list(size = 4))

LinearTimeWarp("speed", effect_name = "LinearTimeWarp", time_scalar = 2)
}
