% tinyrox says don't edit this manually, but it can't stop you!
\name{media_reference}
\alias{media_reference}
\alias{media_reference<-}
\title{Active media reference of a clip}
\usage{
media_reference(x)

media_reference(x) <- value
}
\arguments{
\item{x}{A \code{\link{Clip}}.}

\item{value}{A media reference.}
}
\value{
The clip's active media reference object.
}
\description{
Active media reference of a clip
}
\examples{
cl <- Clip("a", ExternalReference("a.mp4"))
media_reference(cl)
}
