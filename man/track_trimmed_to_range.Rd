% tinyrox says don't edit this manually, but it can't stop you!
\name{track_trimmed_to_range}
\alias{track_trimmed_to_range}
\title{Trim a track to a time range}
\usage{
track_trimmed_to_range(in_track, trim_range)
}
\arguments{
\item{in_track}{A \code{\link{Track}}.}

\item{trim_range}{A \code{\link{TimeRange}} in track coordinates.}
}
\value{
A new \code{\link{Track}}.
}
\description{
Returns a new track containing each child trimmed to the portion that falls
within \code{trim_range} (in track coordinates); children fully outside are
dropped.
}
