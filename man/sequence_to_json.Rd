% tinyrox says don't edit this manually, but it can't stop you!
\name{sequence_to_json}
\alias{sequence_to_json}
\alias{sequence_from_json}
\title{Serialize / restore a sequence as OTIO JSON}
\usage{
sequence_to_json(seq, pretty = TRUE)

sequence_from_json(json)
}
\arguments{
\item{seq}{An \code{nle_sequence}.}

\item{pretty}{Ignored (OTIO pretty-prints); kept for compatibility.}

\item{json}{An OTIO JSON string.}
}
\value{
\code{sequence_to_json}: a JSON string. \code{sequence_from_json}: an
  \code{nle_sequence}.
}
\description{
\code{sequence_to_json()} renders the sequence's OTIO Timeline to canonical
\code{.otio} JSON; \code{sequence_from_json()} parses it back into an
\code{nle_sequence}. OTIO performs the (de)serialization.
}
