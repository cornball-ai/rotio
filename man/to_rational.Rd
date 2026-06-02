% tinyrox says don't edit this manually, but it can't stop you!
\name{to_rational}
\alias{to_rational}
\title{Convert a seconds value to a rational_time at a given denominator}
\usage{
to_rational(seconds, den)
}
\arguments{
\item{seconds}{Numeric seconds.}

\item{den}{Integer denominator (typically the project fps).}
}
\description{
Useful for converting a frame count or wall-clock seconds to the
canonical rational form. Rounds to the nearest \code{num}.
}
