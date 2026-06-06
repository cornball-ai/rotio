% tinyrox says don't edit this manually, but it can't stop you!
\name{validate_with_rotio}
\alias{validate_with_rotio}
\title{Validate an OTIO object against the real OpenTimelineIO library}
\usage{
validate_with_rotio(x)
}
\arguments{
\item{x}{An OTIO object (typically a \code{\link{Timeline}}).}
}
\value{
Invisibly, a list with \code{status} (\code{"valid"} or
  \code{"unverified"}) and, when validated, the rotio-normalized JSON.
}
\description{
Serializes \code{x} to OTIO JSON, parses it with \code{rotio} (the exact
libopentimelineio binding), and re-serializes through rotio. Confirms the
emitted JSON is accepted by real OTIO. Requires the optional \code{rotio}
package.
}
\examples{
\donttest{validate_with_rotio(Timeline("demo"))}
}
