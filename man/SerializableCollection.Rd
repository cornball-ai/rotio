% tinyrox says don't edit this manually, but it can't stop you!
\name{SerializableCollection}
\alias{SerializableCollection}
\title{Construct a SerializableCollection}
\usage{
SerializableCollection(name = "", children = list(), metadata = NULL)
}
\arguments{
\item{name}{Collection name.}

\item{children}{A list of OTIO objects.}

\item{metadata}{Named list of metadata.}
}
\value{
A \code{SerializableCollection}.
}
\description{
A flat, named collection of OTIO objects (not a composition).
}
\examples{
col <- SerializableCollection("shots", list(Clip("a"), Clip("b")))
length(children(col))
}
