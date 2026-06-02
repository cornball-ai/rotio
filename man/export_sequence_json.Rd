% tinyrox says don't edit this manually, but it can't stop you!
\name{export_sequence_json}
\alias{export_sequence_json}
\title{Export the JSON cache sibling of a sequence.md}
\usage{
export_sequence_json(seq, path)
}
\arguments{
\item{seq}{An \code{nle_sequence}.}

\item{path}{Output path (typically \code{"sequence.json"}).}
}
\description{
Writes \code{sequence_to_json(seq, pretty = TRUE)} to \code{path}. This
file is a cache for non-Markdown consumers; \code{sequence.md} stays
authoritative.
}
