% tinyrox says don't edit this manually, but it can't stop you!
\name{to_json_string}
\alias{to_json_string}
\title{Serialize an OTIO object to a JSON string}
\usage{
to_json_string(x, indent = 2)
}
\arguments{
\item{x}{An OTIO object (typically a \code{\link{Timeline}}).}

\item{indent}{Indent width for pretty-printing (default 2). Use 0 for compact.}
}
\value{
A JSON string.
}
\description{
Emits canonical OpenTimelineIO JSON. Each object carries its own
\code{OTIO_SCHEMA}, so the output is the standard \code{.otio} format and
parses in any OTIO reader (verify with \code{\link{validate_with_rotio}}).
}
\examples{
to_json_string(Timeline("demo"))
}
