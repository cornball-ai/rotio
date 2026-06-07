% tinyrox says don't edit this manually, but it can't stop you!
\name{to_json_file}
\alias{to_json_file}
\title{Write an OTIO object to a JSON file}
\usage{
to_json_file(x, file_name, indent = 2, target_schema_versions = NULL)
}
\arguments{
\item{x}{An OTIO object (typically a \code{\link{Timeline}}).}

\item{file_name}{Output path (conventionally \code{content.otio}).}

\item{indent}{Indent width (default 2).}

\item{target_schema_versions}{Optional schema downgrade targets; see
\code{\link{to_json_string}}.}
}
\value{
\code{file_name}, invisibly.
}
\description{
Write an OTIO object to a JSON file
}
\examples{
f <- tempfile(fileext = ".otio")
to_json_file(Timeline("demo"), f)
unlink(f)
}
