% tinyrox says don't edit this manually, but it can't stop you!
\name{nle_register_driver}
\alias{nle_register_driver}
\title{Register a driver with nle.api}
\usage{
nle_register_driver(name, dump = NULL, apply = NULL, capabilities = NULL)
}
\arguments{
\item{name}{Driver name (string). Used by callers as
\code{dump_timeline(driver = name, ...)}.}

\item{dump}{Function: \code{function(...) -> nle_timeline}. NULL if
the driver does not implement read-back.}

\item{apply}{Function: \code{function(timeline, ...) -> invisible(...)}. NULL
if the driver does not implement write-through.}

\item{capabilities}{Function: \code{function() -> list}. Should return
a list with at least \code{formats}, \code{coords}, \code{time},
\code{fields_preserved}, \code{metadata} (see TIMELINE_SCHEMA.md).}
}
\value{
Invisible TRUE.
}
\description{
Drivers call this from \code{.onLoad()} (or any other entry point) to
make themselves discoverable. The supplied functions are stored by
reference; they're called by \code{\link{dump_timeline}} /
\code{\link{apply_timeline}} / \code{\link{driver_capabilities}}.
}
