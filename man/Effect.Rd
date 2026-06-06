% tinyrox says don't edit this manually, but it can't stop you!
\name{Effect}
\alias{Effect}
\alias{LinearTimeWarp}
\alias{TimeEffect}
\alias{FreezeFrame}
\title{Construct an OTIO effect}
\usage{
Effect(name = "", effect_name = "", enabled = TRUE, metadata = NULL)

LinearTimeWarp(name = "", effect_name = "", time_scalar = 1, enabled = TRUE,
               metadata = NULL)

TimeEffect(name = "", effect_name = "", metadata = NULL)

FreezeFrame(name = "", metadata = NULL)
}
\arguments{
\item{name}{Effect instance name (default empty).}

\item{effect_name}{Effect kind label (default empty, matching OTIO).}

\item{enabled}{Whether the effect is active (default \code{TRUE}).}

\item{metadata}{Named list of parameters.}

\item{time_scalar}{Linear time scale (playback rate multiplier).}
}
\value{
An \code{Effect}.
}
\description{
\code{Effect} is a generic \code{effect_name} plus metadata parameters.
\code{LinearTimeWarp} is OTIO's linear speed change (\code{time_scalar}).
}
\examples{
Effect("blur", "GaussianBlur", metadata = list(size = 4))

LinearTimeWarp("speed", effect_name = "LinearTimeWarp", time_scalar = 2)
}
