% tinyrox says don't edit this manually, but it can't stop you!
\name{tracks}
\alias{tracks}
\alias{tracks<-}
\title{The track stack of a timeline}
\usage{
tracks(x)

tracks(x) <- value
}
\arguments{
\item{x}{A \code{\link{Timeline}}.}

\item{value}{A \code{\link{Stack}}.}
}
\value{
The timeline's \code{\link{Stack}}.
}
\description{
The track stack of a timeline
}
\examples{
tl <- add_track(Timeline("demo"), Track("V1", kind = "Video"))
length(children(tracks(tl)))
}
