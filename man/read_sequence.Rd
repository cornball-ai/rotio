% tinyrox says don't edit this manually, but it can't stop you!
\name{read_sequence}
\alias{read_sequence}
\title{Read a sequence from a sequence.md file}
\usage{
read_sequence(path)
}
\arguments{
\item{path}{Path to a sequence.md file.}
}
\value{
An \code{nle_sequence}.
}
\description{
Parses the single delimited state block, validates schema/version,
and returns the resulting \code{nle_sequence}. The surrounding prose
is attached as the \code{"prose"} attribute so \code{write_sequence()}
can preserve it.
Strict parser: errors on missing, duplicated, or malformed markers, on
unsupported encoding, or on schema mismatch.
}
