% tinyrox says don't edit this manually, but it can't stop you!
\name{to_time_string}
\alias{to_time_string}
\title{Time string ("HH:MM:SS.sss") for a RationalTime}
\usage{
to_time_string(x)
}
\arguments{
\item{x}{A \code{RationalTime}.}
}
\value{
Character scalar, the time as \code{"HH:MM:SS.sss"}.
}
\description{
Time string ("HH:MM:SS.sss") for a RationalTime
}
\examples{
to_time_string(RationalTime(90, 24))
}
