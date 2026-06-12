% tinyrox says don't edit this manually, but it can't stop you!
\name{register_downgrade_function}
\alias{register_downgrade_function}
\title{Register a schema downgrade function}
\usage{
register_downgrade_function(schema_name, version_to_downgrade_from, fn)
}
\arguments{
\item{schema_name}{Schema type name. Must be a known OTIO schema.}

\item{version_to_downgrade_from}{Source version (integer).}

\item{fn}{Function of one argument (the field list) returning a field list.}
}
\value{
\code{TRUE} if registered; \code{FALSE} for an unknown schema or a
  duplicate \code{(schema, version)} pair (matching RcppOTIO).
}
\description{
\code{fn} receives the field list of a \code{schema_name} object at
\code{version_to_downgrade_from} and returns the field list one version lower.
Stored for use when writing older schema versions.
}
\examples{
register_downgrade_function("Effect", 2, function(fields) fields)
}
