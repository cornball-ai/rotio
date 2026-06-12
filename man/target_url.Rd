% tinyrox says don't edit this manually, but it can't stop you!
\name{target_url}
\alias{target_url}
\alias{target_url<-}
\title{Target URL of a clip or external reference}
\usage{
target_url(x)

target_url(x) <- value
}
\arguments{
\item{x}{A \code{\link{Clip}} or \code{\link{ExternalReference}}.}

\item{value}{New URL.}
}
\value{
The target URL string, or \code{NULL} if the active reference has
  no URL.
}
\description{
Target URL of a clip or external reference
}
\examples{
cl <- Clip("a", ExternalReference("a.mp4"))
target_url(cl) <- "b.mp4"
target_url(cl)
}
