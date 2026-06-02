% tinyrox says don't edit this manually, but it can't stop you!
\name{extract_sequence_state_md}
\alias{extract_sequence_state_md}
\title{Extract the state block payload from a sequence.md}
\usage{
extract_sequence_state_md(path)
}
\arguments{
\item{path}{Path to a sequence.md file.}
}
\value{
A character scalar — the payload between markers (with any
  surrounding code fence stripped).
}
\description{
Lower-level helper used by \code{\link{read_sequence}}. Errors strictly
on marker problems; returns the raw payload string.
}
