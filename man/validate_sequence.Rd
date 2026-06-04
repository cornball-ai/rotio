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
Checks no duplicate clip ids, and that every clip has a positive duration.
OTIO guarantees the rest of the structure (tracks are sequential, clips sit
on real tracks).
}
