% tinyrox says don't edit this manually, but it can't stop you!
\name{clip_effect_add}
\alias{clip_effect_add}
\alias{clip_effects}
\alias{clip_effect_params}
\alias{clip_effect_remove}
\title{Add, list, inspect, or remove a clip effect}
\usage{
clip_effect_add(timeline, clip, effect_name, params = list(), enabled = TRUE)

clip_effects(timeline, clip)

clip_effect_params(timeline, clip, i)

clip_effect_remove(timeline, clip, i)
}
\arguments{
\item{timeline}{An \code{nle_timeline}.}

\item{clip}{Clip id.}

\item{effect_name}{OTIO effect name, e.g. \code{"transform"}, \code{"crop"}.}

\item{params}{Named list of effect parameters (length-1 numbers or strings).}

\item{enabled}{Whether the effect is active (default \code{TRUE}).}

\item{i}{1-based effect index (as listed by \code{clip_effects}).}
}
\value{
\code{clip_effect_add} / \code{clip_effect_remove}: the updated
  timeline. \code{clip_effects}: a data.frame of the clip's effects.
  \code{clip_effect_params}: a named list.
}
\description{
nle.api models effects on OpenTimelineIO's own \code{Effect}: an
\code{effect_name} plus a metadata dictionary of parameters. This is the
OTIO-native way to attach transform / crop / colour / arbitrary effects; a
driver maps the name and parameters to its engine. For speed, use
\code{\link{clip_speed}} (an OTIO \code{LinearTimeWarp}).
}
\examples{
tl <- new_timeline()
tl <- track_add(tl, "video", id = "v1")
tl <- clip_add(tl, "v1", tl_in = rational_time(0, 30),
               tl_out = rational_time(90, 30), asset = "a.mp4", id = "a")
tl <- clip_effect_add(tl, "a", "transform", list(x = 100, y = 50, scale = 0.5))
clip_effects(tl, "a")
}
