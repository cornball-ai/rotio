% tinyrox says don't edit this manually, but it can't stop you!
\name{enabled}
\alias{enabled}
\alias{enabled<-}
\title{Whether an item, composition, or effect is enabled}
\usage{
enabled(x)

enabled(x) <- value
}
\arguments{
\item{x}{An object with an \code{enabled} field.}

\item{value}{\code{TRUE} or \code{FALSE}.}
}
\value{
\code{TRUE} if the object is enabled, else \code{FALSE}.
}
\description{
A disabled clip/track is muted; a disabled effect is bypassed.
}
\examples{
cl <- Clip("a")
enabled(cl) <- FALSE
enabled(cl)
}
