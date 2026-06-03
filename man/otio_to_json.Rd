% tinyrox says don't edit this manually, but it can't stop you!
\name{otio_to_json}
\alias{otio_to_json}
\alias{otio_from_json}
\title{Serialize / deserialize an OTIO timeline as JSON}
\usage{
otio_to_json(timeline)

otio_from_json(json)
}
\arguments{
\item{timeline}{An \code{otio_timeline}.}

\item{json}{An OTIO JSON string.}
}
\value{
\code{otio_to_json}: a JSON string. \code{otio_from_json}: an
  \code{otio_timeline}.
}
\description{
\code{otio_to_json()} renders a timeline to canonical OTIO JSON via the
library's own serializer; \code{otio_from_json()} parses it back into a live
timeline. The JSON is the standard \code{.otio} format (each object carries
its own \code{OTIO_SCHEMA}).
}
\examples{
tl <- otio_timeline("demo")
js <- otio_to_json(tl)
identical(otio_name(otio_from_json(js)), "demo")
}
