% tinyrox says don't edit this manually, but it can't stop you!
\name{transition_type}
\alias{transition_type}
\alias{transition_type<-}
\alias{in_offset}
\alias{in_offset<-}
\alias{out_offset}
\alias{out_offset<-}
\title{Transition type / offsets}
\usage{
transition_type(x)

transition_type(x) <- value

in_offset(x)

in_offset(x) <- value

out_offset(x)

out_offset(x) <- value
}
\arguments{
\item{x}{A \code{\link{Transition}}.}

\item{value}{New value.}
}
\value{
\code{transition_type} returns a string, \code{in_offset} and
  \code{out_offset} a \code{\link{RationalTime}}; setters return \code{x}.
}
\description{
Transition type / offsets
}
\examples{
tr <- Transition(transition_type = "SMPTE_Dissolve",
                 in_offset = RationalTime(5, 30), out_offset = RationalTime(5, 30))
transition_type(tr)
in_offset(tr)
}
