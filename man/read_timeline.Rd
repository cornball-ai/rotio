% tinyrox says don't edit this manually, but it can't stop you!
\name{read_timeline}
\alias{read_timeline}
\title{Read a timeline from a timeline.md file}
\usage{
read_timeline(path)
}
\arguments{
\item{path}{Path to a timeline.md file.}
}
\value{
An \code{nle_timeline}.
}
\description{
Parses the single OTIO state block and returns an \code{nle_timeline}. The
surrounding prose is attached as the \code{"prose"} attribute so
\code{write_timeline()} can preserve it. Strict parser.
}
