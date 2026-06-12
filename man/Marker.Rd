% tinyrox says don't edit this manually, but it can't stop you!
\name{Marker}
\alias{Marker}
\title{Construct a Marker}
\usage{
Marker(name = "", marked_range = NULL, color = "GREEN", comment = "",
       metadata = NULL)
}
\arguments{
\item{name}{Marker name.}

\item{marked_range}{A \code{\link{TimeRange}}.}

\item{color}{Marker color (default \code{"GREEN"}).}

\item{comment}{Free-text comment.}

\item{metadata}{Named list of metadata.}
}
\value{
A \code{Marker}.
}
\description{
Annotates a time range on an item.
}
\examples{
Marker("note", TimeRange(RationalTime(0, 30), RationalTime(30, 30)),
       comment = "check color")
}
