% tinyrox says don't edit this manually, but it can't stop you!
\name{Transition}
\alias{Transition}
\title{Construct a Transition}
\usage{
Transition(name = "", transition_type = "", in_offset = RationalTime(0, 1),
           out_offset = RationalTime(0, 1), metadata = NULL)
}
\arguments{
\item{name}{Transition name.}

\item{transition_type}{Transition type (e.g. \code{"SMPTE_Dissolve"}).}

\item{metadata}{Named list of metadata.}

\item{in_offset,out_offset}{\code{\link{RationalTime}} offsets into the
neighbouring clips.}
}
\value{
A \code{Transition}.
}
\description{
A transition (e.g. a dissolve) between adjacent items on a track.
}
