% tinyrox says don't edit this manually, but it can't stop you!
\name{media_references}
\alias{media_references}
\title{Media references of a clip}
\usage{
media_references(x)
}
\arguments{
\item{x}{A \code{\link{Clip}}.}
}
\value{
The clip's named list of media references.
}
\description{
Media references of a clip
}
\examples{
cl <- Clip("a", ExternalReference("a.mp4"))
names(media_references(cl))
}
