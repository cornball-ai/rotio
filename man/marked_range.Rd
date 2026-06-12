% tinyrox says don't edit this manually, but it can't stop you!
\name{marked_range}
\alias{marked_range}
\alias{marked_range<-}
\title{Marked range of a Marker}
\usage{
marked_range(x)

marked_range(x) <- value
}
\arguments{
\item{x}{A \code{\link{Marker}}.}

\item{value}{A \code{\link{TimeRange}}.}
}
\value{
The marker's \code{\link{TimeRange}}; the setter returns \code{x}.
}
\description{
Marked range of a Marker
}
\examples{
m <- Marker("note", TimeRange(RationalTime(0, 30), RationalTime(30, 30)))
marked_range(m)
}
