% tinyrox says don't edit this manually, but it can't stop you!
\name{is_unknown_schema}
\alias{is_unknown_schema}
\title{Is an object's schema unknown?}
\usage{
is_unknown_schema(x)
}
\arguments{
\item{x}{An OTIO object.}
}
\value{
A logical scalar.
}
\description{
\code{TRUE} when the object's schema type is not a recognised OTIO type
(e.g. parsed from JSON written by a newer or third-party schema).
}
\examples{
is_unknown_schema(Timeline("demo"))
}
