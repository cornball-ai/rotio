% tinyrox says don't edit this manually, but it can't stop you!
\name{end_time_exclusive}
\alias{end_time_exclusive}
\alias{end_time_inclusive}
\title{Exclusive / inclusive end of a TimeRange}
\usage{
end_time_exclusive(x)

end_time_inclusive(x)
}
\arguments{
\item{x}{A \code{TimeRange}.}
}
\value{
A \code{RationalTime}.
}
\description{
\code{end_time_exclusive} = start + duration. \code{end_time_inclusive} is the
last whole frame; for a span of one frame or less it is the start time
(matching opentime).
}
\examples{
tr <- TimeRange(RationalTime(0, 24), RationalTime(48, 24))
end_time_exclusive(tr)
end_time_inclusive(tr)
}
