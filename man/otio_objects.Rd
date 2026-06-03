% tinyrox says don't edit this manually, but it can't stop you!
\name{otio_objects}
\alias{otio_objects}
\alias{otio_timeline}
\alias{otio_track}
\alias{otio_clip}
\alias{otio_add_track}
\alias{otio_add_clip}
\alias{otio_remove_clip}
\alias{otio_tracks}
\alias{otio_clips}
\title{OpenTimelineIO object model (Timeline / Track / Clip)}
\usage{
otio_timeline(name = "")

otio_track(name = "", kind = c("Video", "Audio"))

otio_clip(name = "", target_url = "", start = 0, duration = 0, rate = 30)

otio_add_track(timeline, track)

otio_add_clip(track, clip)

otio_remove_clip(track, i)

otio_tracks(timeline)

otio_clips(track)
}
\arguments{
\item{name}{Object name.}

\item{kind}{Track kind, \code{"Video"} (default) or \code{"Audio"}.}

\item{target_url}{Media URL for the clip's external reference.}

\item{start}{First frame of the source range (value, in \code{rate} units).}

\item{duration}{Source range duration (value, in \code{rate} units).}

\item{rate}{Rate (fps) for \code{start} and \code{duration}.}

\item{timeline}{An \code{otio_timeline}.}

\item{track}{An \code{otio_track}.}

\item{clip}{An \code{otio_clip}.}

\item{i}{1-based index of the child to remove from a track.}
}
\value{
An \code{otio_timeline}, \code{otio_track}, or \code{otio_clip}.
}
\description{
These constructors build live OpenTimelineIO objects in the linked C++
library and return lightweight S3 handles wrapping an external pointer. They
are the foundation the sequence model migrates onto (see PLAN.md); the
pure-R \code{\link{new_sequence}} model is unchanged for now.
}
\details{
Unlike the pure-R edit verbs, these objects are mutable: \code{otio_add_track}
and \code{otio_add_clip} modify the timeline in place (the C++ object is
shared, not copied). Serialization and all field reads are performed by OTIO.

}
\examples{
tl <- otio_timeline("demo")
v1 <- otio_track("v1", "Video")
otio_add_track(tl, v1)
otio_add_clip(v1, otio_clip("a", "a.mp4", start = 0, duration = 90, rate = 30))
otio_tracks(tl)
otio_clips(v1)
}
