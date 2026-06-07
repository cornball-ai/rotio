% tinyrox says don't edit this manually, but it can't stop you!
\name{fill}
\alias{fill}
\title{Fill a gap with an item (3/4-point edit)}
\usage{
fill(item, track, track_time, reference_point = "Source")
}
\arguments{
\item{item}{The item to place (usually a clip).}

\item{track}{A \code{\link{Track}}.}

\item{track_time}{A \code{\link{RationalTime}} inside the gap to fill.}

\item{reference_point}{One of \code{"Source"}, \code{"Sequence"}, \code{"Fit"}.}
}
\value{
\code{track}, invisibly.
}
\description{
Replaces the gap covering \code{track_time} with \code{item}. The
\code{reference_point} controls the transform: \code{"Source"} uses the clip's
own duration, \code{"Sequence"} clamps to the gap, \code{"Fit"} time-warps the
clip to fill the gap exactly. Mutates \code{track} in place.
}
