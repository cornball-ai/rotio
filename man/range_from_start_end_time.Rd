% tinyrox says don't edit this manually, but it can't stop you!
\name{range_from_start_end_time}
\alias{range_from_start_end_time}
\title{Construct a TimeRange from start and exclusive end times}
\usage{
range_from_start_end_time(start_time, end_time_exclusive)
}
\arguments{
\item{start_time}{A \code{RationalTime}.}

\item{end_time_exclusive}{A \code{RationalTime}.}
}
\value{
A \code{TimeRange}.
}
\description{
Duration is computed in the start time's rate (opentime convention).
}
\examples{
range_from_start_end_time(RationalTime(0, 24), RationalTime(48, 24))
}
