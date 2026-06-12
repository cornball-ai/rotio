% tinyrox says don't edit this manually, but it can't stop you!
\name{register_upgrade_function}
\alias{register_upgrade_function}
\title{Register a schema upgrade function}
\usage{
register_upgrade_function(schema_name, version_to_upgrade_to, fn)
}
\arguments{
\item{schema_name}{Schema type name (e.g. \code{"Marker"}). Must be a known
OTIO schema.}

\item{version_to_upgrade_to}{Target version (integer).}

\item{fn}{Function of one argument (the field list) returning a field list.}
}
\value{
\code{TRUE} if registered; \code{FALSE} for an unknown schema or a
  duplicate \code{(schema, version)} pair (matching RcppOTIO).
}
\description{
\code{fn} receives the parsed field list of a \code{schema_name} object at the
version below \code{version_to_upgrade_to} and returns the upgraded list. It is
applied automatically by \code{\link{from_json_string}} when an older version
is read.
}
\examples{
register_upgrade_function("Effect", 2, function(fields) fields)
}
