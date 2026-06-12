% tinyrox says don't edit this manually, but it can't stop you!
\name{schema_name}
\alias{schema_name}
\title{Schema name of an OTIO object}
\usage{
schema_name(x)
}
\arguments{
\item{x}{An OTIO object.}
}
\value{
A character scalar.
}
\description{
The schema type (without the version suffix); unrecognised types report
\code{"UnknownSchema"} (matching OTIO).
}
\examples{
schema_name(Clip("shot1"))
}
