% tinyrox says don't edit this manually, but it can't stop you!
\name{write_sequence}
\alias{write_sequence}
\title{Write a sequence back to a sequence.md file}
\usage{
write_sequence(seq, path = NULL)
}
\arguments{
\item{seq}{An \code{nle_sequence}.}

\item{path}{Path to write to. Defaults to the path \code{seq} was read
from, if any.}
}
\value{
The path, invisibly.
}
\description{
Preserves all prose outside the state block, surgically replaces only
the JSON payload between the markers. If \code{path} doesn't exist (or
the in-memory sequence has no attached prose), writes a minimal new
file with a stub header and the state block.
}
