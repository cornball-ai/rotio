% tinyrox says don't edit this manually, but it can't stop you!
\name{available_range}
\alias{available_range}
\alias{available_range<-}
\title{Available range of a media reference or clip}
\usage{
available_range(x)

available_range(x) <- value
}
\arguments{
\item{x}{A media reference or clip.}

\item{value}{A \code{\link{TimeRange}} or \code{NULL}.}
}
\value{
A \code{\link{TimeRange}} (\code{NULL} for a media reference with none
  set); the setter returns \code{x}.
}
\description{
For a media reference, the stored available range. For a clip, the active
media reference's available range (errors if none is set, matching OTIO).
}
\examples{
ref <- ExternalReference("a.mp4",
    available_range = TimeRange(RationalTime(0, 30), RationalTime(90, 30)))
available_range(ref)
}
