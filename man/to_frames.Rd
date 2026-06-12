% tinyrox says don't edit this manually, but it can't stop you!
\name{to_frames}
\alias{to_frames}
\title{Frame number of a RationalTime}
\usage{
to_frames(x, rate = NULL)
}
\arguments{
\item{x}{A \code{RationalTime}.}

\item{rate}{Optional target rate to rescale to first.}
}
\value{
Integer scalar, the frame number.
}
\description{
Integer frame number. With no \code{rate}, truncates at the time's own rate;
with a \code{rate}, rescales first. Truncates toward zero (opentime
\code{int(value_rescaled_to(rate))}).
}
\examples{
to_frames(from_seconds(1.5, 24))
to_frames(RationalTime(48, 24), 48)
}
