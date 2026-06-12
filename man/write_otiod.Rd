% tinyrox says don't edit this manually, but it can't stop you!
\name{write_otiod}
\alias{write_otiod}
\title{Write an OTIOD bundle}
\usage{
write_otiod(timeline, dir, media = NULL, indent = 2)
}
\arguments{
\item{timeline}{A \code{\link{Timeline}}.}

\item{dir}{Bundle directory (created if needed).}

\item{media}{Optional character vector of media files to copy into
\code{<dir>/media/}.}

\item{indent}{Indent width for content.otio (default 2).}
}
\value{
The path to the written \code{content.otio}, invisibly.
}
\description{
Writes \code{timeline} to \code{<dir>/content.otio} and ensures a
\code{media/} subdirectory exists. Optionally copies \code{media} files into
it. Media references inside \code{timeline} should already be relative paths
(e.g. \code{"media/clip01.mp4"}); this writer does not rewrite them.
}
\examples{
d <- tempfile("bundle")
write_otiod(Timeline("demo"), d)
dir(d)
unlink(d, recursive = TRUE)
}
