% tinyrox says don't edit this manually, but it can't stop you!
\name{otio_set_name}
\alias{otio_set_name}
\alias{otio_set_kind}
\title{Rename or re-kind an OTIO object}
\usage{
otio_set_name(x, name)

otio_set_kind(track, kind)
}
\arguments{
\item{x}{An \code{otio_timeline} or \code{otio_track}.}

\item{name}{New name.}

\item{track}{An \code{otio_track}.}

\item{kind}{New track kind.}
}
\value{
The object, invisibly.
}
\description{
\code{otio_set_name()} renames a timeline or track; \code{otio_set_kind()}
changes a track's kind. Both mutate the object in place.
}
