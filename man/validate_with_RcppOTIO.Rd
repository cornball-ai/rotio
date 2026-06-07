% tinyrox says don't edit this manually, but it can't stop you!
\name{validate_with_RcppOTIO}
\alias{validate_with_RcppOTIO}
\title{Validate an OTIO object against the real OpenTimelineIO library}
\usage{
validate_with_RcppOTIO(x)
}
\arguments{
\item{x}{An OTIO object (typically a \code{\link{Timeline}}).}
}
\value{
Invisibly, a list with \code{status} (\code{"valid"} or
  \code{"unverified"}) and, when validated, the RcppOTIO-normalized JSON.
}
\description{
Serializes \code{x} to OTIO JSON, parses it with \code{RcppOTIO} (the exact
libopentimelineio binding), and re-serializes through RcppOTIO. Confirms the
emitted JSON is accepted by real OTIO. Requires the optional \code{RcppOTIO}
package.
}
\examples{
\donttest{validate_with_RcppOTIO(Timeline("demo"))}
}
