% tinyrox says don't edit this manually, but it can't stop you!
\name{TimeTransform}
\alias{TimeTransform}
\title{Construct a TimeTransform}
\usage{
TimeTransform(offset = RationalTime(0, 1), scale = 1, rate = -1)
}
\arguments{
\item{offset}{A \code{RationalTime} offset (default 0).}

\item{scale}{Time scale (default 1).}

\item{rate}{Target rate, or -1 to preserve (default -1).}
}
\value{
A \code{TimeTransform}.
}
\description{
An offset/scale/rate transform (OTIO \code{TimeTransform}). Note: in rotio
\code{TimeTransform} is a plain opentime value type that does not serialize to
JSON; nle.api gives it an \code{OTIO_SCHEMA} for its own (de)serialization,
which is not verified against rotio JSON.
}
