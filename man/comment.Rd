% tinyrox says don't edit this manually, but it can't stop you!
\name{comment}
\alias{comment}
\alias{comment<-}
\title{Comment of a Marker}
\usage{
comment(x)

comment(x) <- value
}
\arguments{
\item{x}{A \code{\link{Marker}}.}

\item{value}{New comment.}
}
\value{
The comment string; the setter returns \code{x}.
}
\description{
Comment of a Marker
}
\examples{
m <- Marker("note", comment = "check color")
comment(m)
}
