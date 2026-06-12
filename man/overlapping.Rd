% tinyrox says don't edit this manually, but it can't stop you!
\name{overlapping}
\alias{overlapping}
\title{Does an item overlap its neighbours?}
\usage{
overlapping(x)
}
\arguments{
\item{x}{An item.}
}
\value{
Logical scalar.
}
\description{
Only transitions overlap (they span a cut); everything else returns
\code{FALSE}.
}
\examples{
overlapping(Clip("a", ExternalReference("a.mp4")))
}
