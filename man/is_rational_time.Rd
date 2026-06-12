% tinyrox says don't edit this manually, but it can't stop you!
\name{is_rational_time}
\alias{is_rational_time}
\alias{is_time_range}
\title{Is x a RationalTime / TimeRange?}
\usage{
is_rational_time(x)

is_time_range(x)
}
\arguments{
\item{x}{Object to test.}
}
\value{
Logical scalar.
}
\description{
Is x a RationalTime / TimeRange?
}
\examples{
is_rational_time(RationalTime(24, 24))
is_time_range(TimeRange(RationalTime(0, 24), RationalTime(48, 24)))
}
