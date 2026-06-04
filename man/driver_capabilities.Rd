% tinyrox says don't edit this manually, but it can't stop you!
\name{driver_capabilities}
\alias{driver_capabilities}
\title{A driver's capability report}
\usage{
driver_capabilities(driver)
}
\arguments{
\item{driver}{Driver name (string).}
}
\description{
Returns whatever the driver's \code{capabilities()} function returns.
Conventionally a list with \code{formats}, \code{coords}, \code{time},
\code{fields_preserved}, \code{metadata}.
}
