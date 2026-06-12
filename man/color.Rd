% tinyrox says don't edit this manually, but it can't stop you!
\name{color}
\alias{color}
\alias{color<-}
\title{Get or set an item's display color}
\usage{
color(x)

color(x) <- value
}
\arguments{
\item{x}{An item or composition.}

\item{value}{A color value (or \code{NULL}).}
}
\value{
The item's color value, or \code{NULL} if unset.
}
\description{
Get or set an item's display color
}
\examples{
cl <- Clip("a")
color(cl) <- "RED"
color(cl)
}
