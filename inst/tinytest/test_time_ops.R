# Phase 2 time-model: standalone checks + a value-AND-rate parity grid vs rotio.

tr <- TimeRange(RationalTime(10, 24), RationalTime(5, 24))
expect_equal(value(end_time_exclusive(tr)), 15)
expect_equal(value(end_time_inclusive(tr)), 14)
# zero / fractional duration end_time_inclusive
expect_equal(value(end_time_inclusive(TimeRange(RationalTime(10, 24), RationalTime(0, 24)))), 10)
expect_equal(value(end_time_inclusive(TimeRange(RationalTime(10, 24), RationalTime(5.5, 24)))), 15)

# cross-rate range_from_start_end_time keeps the START's rate
r <- range_from_start_end_time(RationalTime(24, 24), RationalTime(60, 30))
expect_equal(c(value(duration(r)), rate(duration(r))), c(24, 24))

# almost_equal: delta in the SECOND arg's rate units
expect_false(almost_equal(RationalTime(10, 24), RationalTime(21, 48), 0.6))
expect_true(almost_equal(RationalTime(10, 24), RationalTime(20, 48), 0.5))

# from_time_string preserves the fractional value (no rounding)
expect_equal(value(from_time_string("00:00:00.041666", 24)), 0.041666 * 24)

# ---- value-and-rate parity grid against rotio ----
if (requireNamespace("rotio", quietly = TRUE)) {
    rvr <- function(x) c(unname(x[["value"]]), unname(x[["rate"]]))
    rtr <- function(t) c(rvr(t$start_time), rvr(t$duration))
    ntr <- function(t) c(value(start_time(t)), rate(start_time(t)),
                         value(duration(t)), rate(duration(t)))
    nr <- function(s, d, rt) TimeRange(RationalTime(s, rt), RationalTime(d, rt))
    rr <- function(s, d, rt) rotio::TimeRange(rotio::RationalTime(s, rt),
                                             rotio::RationalTime(d, rt))

    # same-rate and cross-rate range pairs
    specs <- list(list(0, 5, 24), list(5, 5, 24), list(3, 4, 24), list(10, 5, 24),
                  list(8, 10, 24), list(12, 2, 24), list(0, 20, 24), list(14, 3, 24),
                  list(0, 30, 30), list(10, 5, 30), list(15, 10, 30))
    for (i in specs) for (j in specs) {
        a <- do.call(nr, i); ra <- do.call(rr, i)
        b <- do.call(nr, j); rb <- do.call(rr, j)
        lab <- sprintf("%s vs %s", paste(unlist(i), collapse=","), paste(unlist(j), collapse=","))
        expect_equal(contains(a, b), rotio::contains(ra, rb), info = paste("contains", lab))
        expect_equal(intersects(a, b), rotio::intersects(ra, rb), info = paste("intersects", lab))
        expect_equal(overlaps(a, b), rotio::overlaps(ra, rb), info = paste("overlaps", lab))
        expect_equal(ntr(extended_by(a, b)), rtr(rotio::extended_by(ra, rb)),
                     info = paste("extended_by", lab))
        expect_equal(ntr(clamped(a, b)), rtr(rotio::clamped(ra, rb)),
                     info = paste("clamped", lab))
    }

    # range_from_start_end_time cross-rate (value + rate)
    for (sc in list(c(24, 24, 60, 30), c(0, 30, 48, 24), c(10, 24, 50, 24))) {
        nrf <- range_from_start_end_time(RationalTime(sc[1], sc[2]), RationalTime(sc[3], sc[4]))
        rrf <- rotio::range_from_start_end_time(rotio::RationalTime(sc[1], sc[2]),
                                               rotio::RationalTime(sc[3], sc[4]))
        expect_equal(ntr(nrf), rtr(rrf), info = paste("rfset", paste(sc, collapse=",")))
    }

    # almost_equal cross-rate
    for (ae in list(list(10, 24, 21, 48, 0.6), list(10, 24, 20, 48, 0.5),
                    list(10, 24, 11, 24, 0.5), list(100, 30, 80, 24, 0.01))) {
        expect_equal(almost_equal(RationalTime(ae[[1]], ae[[2]]), RationalTime(ae[[3]], ae[[4]]), ae[[5]]),
                     rotio::almost_equal(rotio::RationalTime(ae[[1]], ae[[2]]),
                                        rotio::RationalTime(ae[[3]], ae[[4]]), ae[[5]]),
                     info = paste("almost_equal", paste(unlist(ae), collapse=",")))
    }

    # end_time_inclusive incl. zero/fractional
    for (e in list(c(10, 5, 24), c(10, 0, 24), c(10, 1, 24), c(10, 5.5, 24), c(5, 12, 30))) {
        n <- end_time_inclusive(nr(e[1], e[2], e[3]))
        ro <- rotio::end_time_inclusive(rr(e[1], e[2], e[3]))
        expect_equal(c(value(n), rate(n)), rvr(ro), info = paste("end_incl", paste(e, collapse=",")))
    }

    # to_timecode / from_timecode across rates (non-drop)
    for (rate in c(24, 23.976, 25, 30, 50, 60)) {
        for (v in c(0, 1, 24, 25, 48, 90, 1000)) {
            x <- RationalTime(v, rate)
            expect_equal(to_timecode(x, rate), rotio::to_timecode(rotio::RationalTime(v, rate), rate, FALSE),
                         info = sprintf("tc %g@%g", v, rate))
        }
    }
    # cross-rate timecode (value@24 read at 23.976)
    expect_equal(to_timecode(RationalTime(24, 24), 23.976),
                 rotio::to_timecode(rotio::RationalTime(24, 24), 23.976, FALSE))
    # drop-frame
    dfr <- 30000 / 1001
    for (v in c(0, 30, 1798, 1800, 17982, 17984)) {
        expect_equal(to_timecode(RationalTime(v, dfr), dfr, TRUE),
                     rotio::to_timecode(rotio::RationalTime(v, dfr), dfr, TRUE),
                     info = paste("df-tc", v))
    }
    # from_timecode round-trips (non-drop + drop)
    expect_equal(value(from_timecode("00:01:00:00", 30)),
                 unname(rotio::from_timecode("00:01:00:00", 30)[["value"]]))
    expect_equal(value(from_timecode("00:01:00;02", dfr)),
                 unname(rotio::from_timecode("00:01:00;02", dfr)[["value"]]))

    # from_time_string fractional (value + rate)
    fts <- from_time_string("00:00:00.041666", 24)
    rfts <- rotio::from_time_string("00:00:00.041666", 24)
    expect_equal(c(value(fts), rate(fts)), rvr(rfts))
}

# ---- phase 1-2 source review fixes ----
expect_equal(to_frames(RationalTime(2.7, 24)), 2L)    # truncate toward zero
expect_equal(to_frames(RationalTime(-2.7, 24)), -2L)
ee <- end_time_exclusive(TimeRange(RationalTime(0, 24), RationalTime(2.5, 12)))
expect_equal(c(value(ee), rate(ee)), c(2.5, 12))      # result at duration's rate
expect_equal(to_time_string(RationalTime(-1.5, 1)), "-00:00:01.5")
expect_equal(to_timecode(RationalTime(0, 30000 / 1001), 30000 / 1001), "00:00:00;00")  # infer drop
expect_equal(to_timecode(RationalTime(0, 30), 30), "00:00:00:00")
if (requireNamespace("rotio", quietly = TRUE)) {
    expect_equal(to_frames(RationalTime(2.7, 24)), rotio::to_frames(rotio::RationalTime(2.7, 24)))
    eer <- rotio::end_time_exclusive(rotio::TimeRange(rotio::RationalTime(0, 24), rotio::RationalTime(2.5, 12)))
    expect_equal(c(value(ee), rate(ee)), c(unname(eer[["value"]]), unname(eer[["rate"]])))
    expect_equal(to_time_string(RationalTime(-1.5, 1)), rotio::to_time_string(rotio::RationalTime(-1.5, 1)))
}
