# Phase 2 time-model: standalone checks + a parity grid against rotio.

tr <- TimeRange(RationalTime(10, 24), RationalTime(5, 24))

# end times
expect_equal(value(end_time_exclusive(tr)), 15)
expect_equal(value(end_time_inclusive(tr)), 14)
trf <- TimeRange(RationalTime(10, 24), RationalTime(5.5, 24))
expect_equal(value(end_time_exclusive(trf)), 15.5)
expect_equal(value(end_time_inclusive(trf)), 15)        # fractional -> floor

# contains
expect_true(contains(tr, RationalTime(12, 24)))
expect_false(contains(tr, RationalTime(15, 24)))        # exclusive upper
expect_true(contains(tr, TimeRange(RationalTime(11, 24), RationalTime(2, 24))))

# extended_by / range_from_start_end_time
ext <- extended_by(tr, TimeRange(RationalTime(0, 24), RationalTime(2, 24)))
expect_equal(value(start_time(ext)), 0)
expect_equal(value(end_time_exclusive(ext)), 15)
rng <- range_from_start_end_time(RationalTime(10, 24), RationalTime(15, 24))
expect_equal(value(duration(rng)), 5)

# clamped (keeps original end, clamps start)
c1 <- clamped(tr, TimeRange(RationalTime(12, 24), RationalTime(8, 24)))
expect_equal(c(value(start_time(c1)), value(duration(c1))), c(12, 3))
c2 <- clamped(tr, TimeRange(RationalTime(0, 24), RationalTime(12, 24)))
expect_equal(c(value(start_time(c2)), value(duration(c2))), c(10, 5))

# almost_equal (cross-rate)
expect_true(almost_equal(RationalTime(10, 24), RationalTime(20, 48), 0))
expect_false(almost_equal(RationalTime(10, 24), RationalTime(11, 24), 0.5))

# timecode / time string
expect_equal(to_timecode(RationalTime(48, 24), 24), "00:00:02:00")
expect_equal(value(from_timecode("00:00:02:00", 24)), 48)
expect_equal(to_time_string(RationalTime(90, 24)), "00:00:03.75")
expect_equal(value(from_time_string("0:0:3.75", 24)), 90)

# TimeTransform
tt <- TimeTransform(RationalTime(5, 24), 2, 24)
expect_equal(tt$OTIO_SCHEMA, "TimeTransform.1")
expect_equal(value(tt$offset), 5)
expect_equal(tt$scale, 2)

# ---- parity grid against rotio ----
if (requireNamespace("rotio", quietly = TRUE)) {
    nr <- function(s, d) TimeRange(RationalTime(s, 24), RationalTime(d, 24))
    rr <- function(s, d) rotio::TimeRange(rotio::RationalTime(s, 24), rotio::RationalTime(d, 24))
    rsec <- function(x) unname(x[["value"]] / x[["rate"]])               # rotio RationalTime
    rstart <- function(x) rsec(x$start_time)
    rend <- function(x) rstart(x) + unname(x$duration[["value"]] / x$duration[["rate"]])

    grid <- list(c(0, 5), c(5, 5), c(3, 4), c(10, 5), c(8, 10), c(12, 2), c(0, 20), c(14, 3))
    for (gi in grid) for (gj in grid) {
        a <- nr(gi[1], gi[2]); ra <- rr(gi[1], gi[2])
        b <- nr(gj[1], gj[2]); rb <- rr(gj[1], gj[2])
        lab <- sprintf("[%d,%d) vs [%d,%d)", gi[1], gi[2], gj[1], gj[2])
        expect_equal(contains(a, b), rotio::contains(ra, rb), info = paste("contains", lab))
        expect_equal(intersects(a, b), rotio::intersects(ra, rb), info = paste("intersects", lab))
        expect_equal(overlaps(a, b), rotio::overlaps(ra, rb), info = paste("overlaps", lab))
        ne <- extended_by(a, b); re <- rotio::extended_by(ra, rb)
        expect_equal(c(to_seconds(start_time(ne)), to_seconds(end_time_exclusive(ne))),
                     c(rstart(re), rend(re)), info = paste("extended_by", lab))
        nc <- clamped(a, b); rc <- rotio::clamped(ra, rb)
        expect_equal(c(to_seconds(start_time(nc)), to_seconds(end_time_exclusive(nc))),
                     c(rstart(rc), rend(rc)), info = paste("clamped", lab))
    }
    # scalar parity
    for (gi in grid) {
        a <- nr(gi[1], gi[2]); ra <- rr(gi[1], gi[2])
        expect_equal(value(end_time_exclusive(a)), rsec(rotio::end_time_exclusive(ra)) * 24,
                     info = "end_excl")
        expect_equal(value(end_time_inclusive(a)), rsec(rotio::end_time_inclusive(ra)) * 24,
                     info = "end_incl")
        expect_equal(to_timecode(RationalTime(gi[1], 24), 24),
                     rotio::to_timecode(rotio::RationalTime(gi[1], 24), 24, FALSE),
                     info = "timecode")
        expect_equal(to_time_string(RationalTime(gi[1], 24)),
                     rotio::to_time_string(rotio::RationalTime(gi[1], 24)),
                     info = "time_string")
    }
}
