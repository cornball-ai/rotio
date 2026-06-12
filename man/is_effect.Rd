% tinyrox says don't edit this manually, but it can't stop you!
\name{is_effect}
\alias{is_effect}
\title{Is x an Effect?}
\usage{
is_effect(x)
}
\arguments{
\item{x}{Object to test.}
}
\value{
\code{TRUE} if \code{x} is an \code{Effect}, else \code{FALSE}.
}
\description{
Is x an Effect?
}
\examples{
is_effect(Effect("blur", "GaussianBlur"))
}
