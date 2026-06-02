% tinyrox says don't edit this manually, but it can't stop you!
\name{replace_sequence_state_md}
\alias{replace_sequence_state_md}
\title{Replace only the state block in a sequence.md (without parsing the JSON)}
\usage{
replace_sequence_state_md(path, seq)
}
\arguments{
\item{path}{Path to a sequence.md.}

\item{seq}{An \code{nle_sequence}.}
}
\value{
The path, invisibly.
}
\description{
Lower-level helper for tools that want to swap the payload without
going through the S3 model. Errors via the strict parser if the file
has no valid state block to replace.
}
