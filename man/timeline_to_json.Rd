% tinyrox says don't edit this manually, but it can't stop you!
\name{timeline_to_json}
\alias{timeline_to_json}
\alias{timeline_from_json}
\title{Serialize / restore a timeline as OTIO JSON}
\usage{
timeline_to_json(timeline, pretty = TRUE)

timeline_from_json(json)
}
\arguments{
\item{timeline}{An \code{nle_timeline}.}

\item{pretty}{Ignored (OTIO pretty-prints); kept for compatibility.}

\item{json}{An OTIO JSON string.}
}
\value{
\code{timeline_to_json}: a JSON string. \code{timeline_from_json}: an
  \code{nle_timeline}.
}
\description{
\code{timeline_to_json()} renders the timeline's OTIO Timeline to canonical
\code{.otio} JSON; \code{timeline_from_json()} parses it back into an
\code{nle_timeline}. OTIO performs the (de)serialization.
}
