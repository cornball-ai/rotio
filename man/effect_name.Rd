% tinyrox says don't edit this manually, but it can't stop you!
\name{effect_name}
\alias{effect_name}
\alias{effect_name<-}
\title{Effect kind label}
\usage{
effect_name(x)

effect_name(x) <- value
}
\arguments{
\item{x}{An \code{\link{Effect}}.}

\item{value}{New effect_name.}
}
\value{
The effect kind string; the setter returns \code{x}.
}
\description{
Effect kind label
}
\examples{
e <- Effect("blur", "GaussianBlur")
effect_name(e)
}
