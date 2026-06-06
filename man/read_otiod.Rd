% tinyrox says don't edit this manually, but it can't stop you!
\name{read_otiod}
\alias{read_otiod}
\title{Read an OTIOD bundle}
\usage{
read_otiod(dir)
}
\arguments{
\item{dir}{Bundle directory.}
}
\value{
The bundle's OTIO object (typically a \code{\link{Timeline}}).
}
\description{
Reads \code{<dir>/content.otio} into the object model. Media references stay
relative to the bundle directory.
}
