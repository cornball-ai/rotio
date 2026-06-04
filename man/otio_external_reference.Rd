% tinyrox says don't edit this manually, but it can't stop you!
\name{otio_external_reference}
\alias{otio_external_reference}
\alias{otio_target_url}
\alias{otio_set_target_url}
\title{External media reference}
\usage{
otio_external_reference(target_url = "")

otio_target_url(x)

otio_set_target_url(x, target_url)
}
\arguments{
\item{target_url}{Media URL.}

\item{x}{An \code{otio_external_reference}.}
}
\value{
An \code{otio_external_reference}.
}
\description{
An OTIO \code{ExternalReference} points a clip at media by URL. Construct one
with \code{otio_external_reference()}, read or change its URL with
\code{otio_target_url()} / \code{otio_set_target_url()}.
}
\examples{
ref <- otio_external_reference("a.mp4")
otio_target_url(ref)
}
