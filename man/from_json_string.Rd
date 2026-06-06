% tinyrox says don't edit this manually, but it can't stop you!
\name{from_json_string}
\alias{from_json_string}
\title{Parse an OTIO JSON string into the object model}
\usage{
from_json_string(input)
}
\arguments{
\item{input}{An OTIO JSON string.}
}
\value{
The reconstructed OTIO object (typically a \code{\link{Timeline}}),
  with parent pointers wired.
}
\description{
Parse an OTIO JSON string into the object model
}
\examples{
tl <- Timeline("demo")
identical(name(from_json_string(to_json_string(tl))), "demo")
}
