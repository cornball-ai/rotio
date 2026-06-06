% tinyrox says don't edit this manually, but it can't stop you!
\name{add_effect}
\alias{add_effect}
\title{Append an effect to an item or composition}
\usage{
add_effect(x, effect)
}
\arguments{
\item{x}{An item or composition (anything with an \code{effects} list).}

\item{effect}{An \code{\link{Effect}}.}
}
\value{
A new object of the same class.
}
\description{
Returns a new object (clip, gap, track, or stack) with \code{effect} appended
to its \code{effects} list. The input is unchanged.
}
\examples{
clip <- Clip("a", ExternalReference("a.mp4"))
clip <- add_effect(clip, LinearTimeWarp(effect_name = "LinearTimeWarp",
                                        time_scalar = 2))
length(effects(clip))
}
