% tinyrox says don't edit this manually, but it can't stop you!
\name{Clip}
\alias{Clip}
\title{Construct a Clip}
\usage{
Clip(name, media_reference = MissingReference(), source_range = NULL,
     metadata = NULL)
}
\arguments{
\item{name}{Clip name.}

\item{media_reference}{A media reference (see \code{\link{ExternalReference}});
defaults to a \code{MissingReference}.}

\item{source_range}{Optional \code{\link{TimeRange}} into the media.}

\item{metadata}{Named list of metadata.}
}
\value{
A \code{Clip} object.
}
\description{
An OTIO \code{Clip} is a media reference plus a \code{source_range} (the
portion of the media used). The reference is stored under the
\code{DEFAULT_MEDIA} key, matching OTIO's multi-reference model.
}
\examples{
Clip("a", ExternalReference("a.mp4"),
     source_range = TimeRange(RationalTime(0, 30), RationalTime(90, 30)))
}
