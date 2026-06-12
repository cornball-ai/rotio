% tinyrox says don't edit this manually, but it can't stop you!
\name{Item}
\alias{Item}
\title{Construct a base Item}
\usage{
Item(name = "", source_range = NULL, effects = NULL, markers = NULL,
     enabled = TRUE, metadata = NULL)
}
\arguments{
\item{name}{Item name.}

\item{source_range}{Optional \code{\link{TimeRange}}.}

\item{effects}{List of \code{\link{Effect}}s.}

\item{markers}{List of \code{\link{Marker}}s.}

\item{enabled}{Whether the item is enabled (default \code{TRUE}).}

\item{metadata}{Named list of metadata.}
}
\value{
An \code{Item}.
}
\description{
A generic OTIO \code{Item} (the base class of clips, gaps, and compositions).
Mainly used by the \code{"Fit"} reference point of \code{\link{fill}}, which
wraps media in a plain item carrying a time warp.
}
\examples{
Item("warp", source_range = TimeRange(RationalTime(0, 30), RationalTime(60, 30)))
}
