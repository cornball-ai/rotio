# Phase 5 edit algorithms: every case is validated against rotio (the oracle),
# which wraps the same OTIO C++ algorithm nle.api ports.

if (requireNamespace("rotio", quietly = TRUE)) {

    # ---- builders (nle.api + rotio), identical structure ----
    nclip <- function(n, s, d, avail = NULL) {
        ref <- ExternalReference(paste0(n, ".mov"))
        if (!is.null(avail)) {
            available_range(ref) <- TimeRange(RationalTime(avail[1], 24), RationalTime(avail[2], 24))
        }
        Clip(n, ref, source_range = TimeRange(RationalTime(s, 24), RationalTime(d, 24)))
    }
    rclip <- function(n, s, d, avail = NULL) {
        ref <- rotio::ExternalReference(paste0(n, ".mov"))
        if (!is.null(avail)) {
            rotio::`available_range<-`(ref, rotio::TimeRange(rotio::RationalTime(avail[1], 24), rotio::RationalTime(avail[2], 24)))
        }
        rotio::Clip(n, ref, source_range = rotio::TimeRange(rotio::RationalTime(s, 24), rotio::RationalTime(d, 24)))
    }
    ngap <- function(d) Gap(RationalTime(d, 24))
    rgap <- function(d) rotio::Gap(rotio::RationalTime(d, 24))

    ntrack <- function(items) {
        t <- Track("V")
        for (it in items) append_child(t, it)
        t
    }
    rtrack <- function(items) {
        t <- rotio::Track("V")
        for (it in items) rotio::append_child(t, it)
        t
    }

    # snapshot a track as (class, source-start, source-duration) per child
    nsnap <- function(t) lapply(children(t), function(c) {
        sr <- c$source_range
        c(class(c)[1], if (is.null(sr)) c(NA, NA) else c(value(start_time(sr)), value(duration(sr))))
    })
    rsnap <- function(t) lapply(rotio::children(t), function(c) {
        sr <- tryCatch(rotio::source_range(c), error = function(e) NULL)
        c(class(c)[1], if (is.null(sr)) c(NA, NA) else c(unname(sr$start_time[["value"]]), unname(sr$duration[["value"]])))
    })

    RT <- function(v) RationalTime(v, 24)
    rRT <- function(v) rotio::RationalTime(v, 24)

    # ---- slip ----
    for (dv in c(0, 2, -2, 100, -100)) {
        nt <- ntrack(list(nclip("A", 5, 10, avail = c(0, 30))))
        rt <- rtrack(list(rclip("A", 5, 10, avail = c(0, 30))))
        slip(children(nt)[[1]], RT(dv))
        rotio::slip(rotio::children(rt)[[1]], rRT(dv))
        expect_equal(nsnap(nt), rsnap(rt), info = paste("slip", dv))
    }

    # ---- ripple ----
    for (din in c(0, 2, -3)) for (dout in c(0, 2, -3, 100)) {
        nt <- ntrack(list(nclip("A", 5, 10, avail = c(0, 30)), nclip("B", 0, 8)))
        rt <- rtrack(list(rclip("A", 5, 10, avail = c(0, 30)), rclip("B", 0, 8)))
        ripple(children(nt)[[1]], RT(din), RT(dout))
        rotio::ripple(rotio::children(rt)[[1]], rRT(din), rRT(dout))
        expect_equal(nsnap(nt), rsnap(rt), info = paste("ripple", din, dout))
    }

    # ---- slide ----
    for (dv in c(0, 2, -2, 100)) {
        nt <- ntrack(list(nclip("A", 0, 10, avail = c(0, 40)), nclip("B", 0, 8), nclip("C", 0, 6)))
        rt <- rtrack(list(rclip("A", 0, 10, avail = c(0, 40)), rclip("B", 0, 8), rclip("C", 0, 6)))
        slide(children(nt)[[2]], RT(dv))
        rotio::slide(rotio::children(rt)[[2]], rRT(dv))
        expect_equal(nsnap(nt), rsnap(rt), info = paste("slide", dv))
    }

    # ---- trim (with a following clip and a following gap) ----
    for (din in c(0, 2, -2)) for (dout in c(0, 2, -2)) {
        nt <- ntrack(list(nclip("A", 0, 6), nclip("B", 0, 10), nclip("C", 0, 6)))
        rt <- rtrack(list(rclip("A", 0, 6), rclip("B", 0, 10), rclip("C", 0, 6)))
        trim(children(nt)[[2]], RT(din), RT(dout))
        rotio::trim(rotio::children(rt)[[2]], rRT(din), rRT(dout))
        expect_equal(nsnap(nt), rsnap(rt), info = paste("trim-clip", din, dout))

        ng <- ntrack(list(nclip("A", 0, 6), nclip("B", 0, 10), ngap(6)))
        rg <- rtrack(list(rclip("A", 0, 6), rclip("B", 0, 10), rgap(6)))
        trim(children(ng)[[2]], RT(din), RT(dout))
        rotio::trim(rotio::children(rg)[[2]], rRT(din), rRT(dout))
        expect_equal(nsnap(ng), rsnap(rg), info = paste("trim-gap", din, dout))
    }

    # ---- roll ----
    for (din in c(0, 2, -2)) for (dout in c(0, 2, -2)) {
        nt <- ntrack(list(nclip("A", 0, 10, avail = c(0, 40)), nclip("B", 0, 10, avail = c(0, 40)), nclip("C", 0, 10, avail = c(0, 40))))
        rt <- rtrack(list(rclip("A", 0, 10, avail = c(0, 40)), rclip("B", 0, 10, avail = c(0, 40)), rclip("C", 0, 10, avail = c(0, 40))))
        roll(children(nt)[[2]], RT(din), RT(dout))
        rotio::roll(rotio::children(rt)[[2]], rRT(din), rRT(dout))
        expect_equal(nsnap(nt), rsnap(rt), info = paste("roll", din, dout))
    }
}
