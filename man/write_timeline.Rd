% tinyrox says don't edit this manually, but it can't stop you!
\name{write_timeline}
\alias{write_timeline}
\title{Write a timeline back to a timeline.md file}
\usage{
write_timeline(timeline, path = NULL)
}
\arguments{
\item{timeline}{An \code{nle_timeline}.}

\item{path}{Path to write to; defaults to where \code{timeline} was read from.}
}
\value{
The path, invisibly.
}
\description{
Preserves prose outside the state block, surgically replacing only the OTIO
JSON payload. If \code{path} doesn't exist (or the timeline has no attached
prose), writes a minimal new file with a stub header and the state block.
}
