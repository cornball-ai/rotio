% tinyrox says don't edit this manually, but it can't stop you!
\name{active_media_reference_key}
\alias{active_media_reference_key}
\alias{active_media_reference_key<-}
\title{Active media reference key of a clip}
\usage{
active_media_reference_key(x)

active_media_reference_key(x) <- value
}
\arguments{
\item{x}{A \code{\link{Clip}}.}

\item{value}{New active key.}
}
\value{
The active media reference key, a character string.
}
\description{
Active media reference key of a clip
}
\examples{
cl <- Clip("a", ExternalReference("a.mp4"))
active_media_reference_key(cl)
}
