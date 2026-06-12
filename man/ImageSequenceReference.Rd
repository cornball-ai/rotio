% tinyrox says don't edit this manually, but it can't stop you!
\name{ImageSequenceReference}
\alias{ImageSequenceReference}
\title{Construct an ImageSequenceReference}
\usage{
ImageSequenceReference(target_url_base = "", name_prefix = "",
                       name_suffix = "", start_frame = 1L, frame_step = 1L,
                       rate = 1, frame_zero_padding = 0L,
                       missing_frame_policy = "error", available_range = NULL,
                       metadata = NULL)
}
\arguments{
\item{target_url_base}{Directory URL.}

\item{start_frame}{First frame number (default 1).}

\item{frame_step}{Frames between images (default 1).}

\item{rate}{Frame rate (default 1).}

\item{frame_zero_padding}{Zero-padding width for the frame number (default 0).}

\item{missing_frame_policy}{One of \code{"error"}, \code{"hold"}, \code{"black"}.}

\item{available_range}{Optional \code{\link{TimeRange}}.}

\item{metadata}{Named list of metadata.}

\item{name_prefix,name_suffix}{Filename prefix/suffix around the frame number.}
}
\value{
An \code{ImageSequenceReference}.
}
\description{
A numbered image sequence (e.g. \code{frame.0001.exr}).
}
\examples{
ImageSequenceReference("file:///frames", "frame.", ".exr",
                       frame_zero_padding = 4, rate = 24)
}
