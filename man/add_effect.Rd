% tinyrox says don't edit this manually, but it can't stop you!
\name{add_effect}
\alias{add_effect}
\title{Append an effect (functional: returns a new object)}
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
Returns a clone of \code{x} with \code{effect} appended to its \code{effects}
list; the input is unchanged.
}
\examples{
clip <- Clip("a", ExternalReference("a.mp4"))
clip <- add_effect(clip, LinearTimeWarp(effect_name = "LinearTimeWarp",
                                        time_scalar = 2))
length(effects(clip))
}
