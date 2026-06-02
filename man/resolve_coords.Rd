% tinyrox says don't edit this manually, but it can't stop you!
\name{resolve_coords}
\alias{resolve_coords}
\title{Resolve the coords argument}
\usage{
resolve_coords(coord = NULL)
}
\arguments{
\item{coord}{Optional character: \code{"topleft"}, \code{"cartesian"},
or \code{"center"}.}
}
\value{
One of the three valid values.
}
\description{
Most user-facing verbs accept a \code{coord} argument. When NULL, the
value falls back to \code{options(nle.coords)} and then to the
canonical \code{"topleft"}.
}
