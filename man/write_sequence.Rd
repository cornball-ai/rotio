% tinyrox says don't edit this manually, but it can't stop you!
\name{write_sequence}
\alias{write_sequence}
\title{Write a sequence back to a sequence.md file}
\usage{
write_sequence(seq, path = NULL)
}
\arguments{
\item{seq}{An \code{nle_sequence}.}

\item{path}{Path to write to; defaults to where \code{seq} was read from.}
}
\value{
The path, invisibly.
}
\description{
Preserves prose outside the state block, surgically replacing only the OTIO
JSON payload. If \code{path} doesn't exist (or the sequence has no attached
prose), writes a minimal new file with a stub header and the state block.
}
