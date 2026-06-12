% tinyrox says don't edit this manually, but it can't stop you!
\name{is_equivalent_to}
\alias{is_equivalent_to}
\title{Are two OTIO objects equivalent?}
\usage{
is_equivalent_to(x, other)
}
\arguments{
\item{x,other}{OTIO objects.}
}
\value{
Logical scalar.
}
\description{
Structural equality, compared via canonical OTIO JSON.
}
\examples{
is_equivalent_to(Timeline("a"), Timeline("a"))
}
