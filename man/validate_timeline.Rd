% tinyrox says don't edit this manually, but it can't stop you!
\name{validate_timeline}
\alias{validate_timeline}
\title{Validate a timeline's structural invariants}
\usage{
validate_timeline(timeline)
}
\arguments{
\item{timeline}{An \code{nle_timeline}.}
}
\value{
TRUE invisibly on success; stops with a clear error otherwise.
}
\description{
Checks no duplicate clip ids, and that every clip has a positive duration.
OTIO guarantees the rest of the structure (tracks are sequential, clips sit
on real tracks).
}
