% tinyrox says don't edit this manually, but it can't stop you!
\name{shift_after}
\alias{shift_after}
\title{Ripple-shift clips after a timeline frame}
\usage{
shift_after(seq, after, delta, inclusive = TRUE)
}
\arguments{
\item{seq}{An \code{nle_sequence}.}

\item{after}{Timeline boundary; clips at or after this frame shift.}

\item{delta}{Shift amount in frames at the sequence fps (or seconds /
\code{rational_time} — converted at the boundary).}

\item{inclusive}{When \code{TRUE} (the default), clips with
\code{tl_in == after} shift too. Set \code{FALSE} to keep clips
that start exactly at the boundary in place (useful when an edit
anchors at \code{after}).}
}
\value{
The updated sequence.
}
\description{
Adds \code{delta} to the \code{tl_in} and \code{tl_out} of every clip
whose \code{tl_in} is at-or-after (or strictly after, see
\code{inclusive}) the given \code{after} frame. Source in/out points
are NOT touched: clips keep showing the same source content, just at
a shifted timeline position.
}
\details{
This is the canonical "close a gap" / "open a gap" operation. Pass
a negative \code{delta} to pull strips earlier (close); positive to
push them later (open).

Both \code{after} and \code{delta} accept any time form: integer
frames at the sequence fps, numeric seconds, or a
\code{\link{rational_time}}.

}
\examples{
seq <- new_sequence(fps = 30L)
seq <- track_add(seq, "video", id = "v1")
seq <- clip_add(seq, "v1", tl_in = rational_time(0, 30),
                tl_out = rational_time(90, 30), asset = "a.mp4", id = "a")
seq <- clip_add(seq, "v1", tl_in = rational_time(90, 30),
                tl_out = rational_time(180, 30), asset = "b.mp4", id = "b")
seq <- shift_after(seq, after = rational_time(90, 30), delta = -30)
seq$clips$tl_in
}
