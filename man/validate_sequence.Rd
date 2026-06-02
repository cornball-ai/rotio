% tinyrox says don't edit this manually, but it can't stop you!
\name{validate_sequence}
\alias{validate_sequence}
\title{Validate a sequence's structural invariants}
\usage{
validate_sequence(seq)
}
\arguments{
\item{seq}{An \code{nle_sequence}.}
}
\value{
TRUE invisibly on success; stops with a clear error otherwise.
}
\description{
Checks:
\itemize{
\item schema string is the expected version
\item every clip's \code{track} refers to an existing track id
\item every clip has \code{tl_out > tl_in}
\item every clip has \code{source_out >= source_in}
\item no two clips share the same id
}
}
