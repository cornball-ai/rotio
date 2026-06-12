% tinyrox says don't edit this manually, but it can't stop you!
\name{target_url_base}
\alias{target_url_base}
\alias{target_url_base<-}
\alias{name_prefix}
\alias{name_suffix}
\alias{start_frame}
\alias{frame_step}
\alias{frame_zero_padding}
\title{ImageSequenceReference fields}
\usage{
target_url_base(x)

target_url_base(x) <- value

name_prefix(x)

name_suffix(x)

start_frame(x)

frame_step(x)

frame_zero_padding(x)
}
\arguments{
\item{x}{An \code{\link{ImageSequenceReference}}.}

\item{value}{New value.}
}
\value{
The stored field value; the setter returns \code{x}.
}
\description{
ImageSequenceReference fields
}
\examples{
isr <- ImageSequenceReference("file:///frames", "frame.", ".exr",
                              frame_zero_padding = 4, rate = 24)
target_url_base(isr)
start_frame(isr)
}
