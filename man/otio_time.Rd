% tinyrox says don't edit this manually, but it can't stop you!
\name{otio_time}
\alias{otio_time}
\alias{otio_value}
\alias{otio_rate}
\alias{otio_to_seconds}
\alias{otio_to_frames}
\alias{otio_rescaled_to}
\alias{otio_timecode}
\title{OpenTimelineIO-backed rational time}
\usage{
otio_time(num, den = 1)

otio_value(x)

otio_rate(x)

otio_to_seconds(x)

otio_to_frames(x, rate)

otio_rescaled_to(x, rate)

otio_timecode(x, rate = otio_rate(x))
}
\arguments{
\item{num}{Frame number / time value (\code{value}). Coerced to double.}

\item{den}{Rate / fps (\code{rate}); must be > 0 (default 1).}

\item{x}{An \code{otio_time}.}

\item{rate}{Rate (fps) to convert to.}
}
\value{
An \code{otio_time} object wrapping a live \code{RationalTime}.
}
\description{
\code{otio_time()} constructs a time value backed by OpenTimelineIO's
\code{opentime::RationalTime} (wrapped as an external pointer into the
linked C++ library). A \code{RationalTime} is a \code{value / rate} pair in
the rate's units; for frame-based editorial work \code{value} is the frame
number and \code{rate} is the fps. This mirrors nle.api's existing
\code{(num, den)} naming: \code{num} is \code{value}, \code{den} is
\code{rate}.
}
\details{
This is the OTIO-native counterpart to \code{\link{rational_time}}. The
pure-R \code{rational_time()} remains in place; \code{otio_time()} is the
path the sequence model migrates onto as the C++ wrap grows (see PLAN.md).

All conversions (\code{to_seconds}, \code{to_frames}, timecode) are computed
by the OTIO library, not reimplemented in R, so they match the canonical
implementation byte for byte.

}
\examples{
t <- otio_time(4918, 30)   # frame 4918 at 30 fps
otio_to_seconds(t)         # 163.933...
otio_to_frames(t, 24)      # rescaled to 24 fps
}
\seealso{
\code{\link{rational_time}} for the pure-R value type.
}
