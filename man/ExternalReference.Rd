% tinyrox says don't edit this manually, but it can't stop you!
\name{ExternalReference}
\alias{ExternalReference}
\alias{MissingReference}
\title{Construct a media reference}
\usage{
ExternalReference(target_url, available_range = NULL, metadata = NULL)

MissingReference(name = "", available_range = NULL, metadata = NULL)
}
\arguments{
\item{target_url}{Media URL for an \code{ExternalReference}.}

\item{available_range}{Optional \code{\link{TimeRange}} of available media.}

\item{metadata}{Named list of metadata.}

\item{name}{Reference name (default empty).}
}
\value{
A media reference object.
}
\description{
\code{ExternalReference} points a clip at media by URL.
\code{MissingReference} is a placeholder for a clip with no resolvable media.
}
\examples{
ExternalReference("media/clip01.mp4")
MissingReference()
}
