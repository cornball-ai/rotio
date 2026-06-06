# Phase 4: composition coordinate model, validated against rotio.

mkclip <- function(n, s, d, r = 24) Clip(n, ExternalReference(paste0(n, ".mov")),
                                         source_range = TimeRange(RationalTime(s, r), RationalTime(d, r)))

A <- mkclip("A", 10, 24)
trk <- Track("V1")
append_child(trk, A)
append_child(trk, Gap(RationalTime(12, 24)))
B <- mkclip("B", 5, 30)
append_child(trk, B)

# range_in_parent / trimmed_range / visible_range
expect_equal(c(value(start_time(range_in_parent(A))), value(duration(range_in_parent(A)))), c(0, 24))
expect_equal(c(value(start_time(range_in_parent(B))), value(duration(range_in_parent(B)))), c(36, 30))
expect_equal(value(start_time(trimmed_range(A))), 10)
expect_equal(value(start_time(visible_range(A))), 10)
expect_error(range_in_parent(mkclip("z", 0, 5)))      # no parent

# timeline track filters + global_start_time
tl <- Timeline("t")
global_start_time(tl) <- RationalTime(86400, 24)
append_child(tracks(tl), Track("V1", kind = "Video"))
append_child(tracks(tl), Track("A1", kind = "Audio"))
expect_equal(value(global_start_time(tl)), 86400)
expect_equal(length(video_tracks(tl)), 1L)
expect_equal(length(audio_tracks(tl)), 1L)

# is_equivalent_to / visible / overlapping
expect_true(is_equivalent_to(A, clone(A)))
expect_false(is_equivalent_to(A, B))
expect_true(visible(A))
expect_false(overlapping(trk))

# available_range for a clip
cwm <- Clip("c", ExternalReference("c.mov",
            available_range = TimeRange(RationalTime(0, 24), RationalTime(100, 24))))
expect_equal(value(duration(available_range(cwm))), 100)
expect_error(available_range(A))                       # no available_range on media

# ---- rotio parity ----
if (requireNamespace("rotio", quietly = TRUE)) {
    rmk <- function(n, s, d) rotio::Clip(n, rotio::ExternalReference(paste0(n, ".mov")),
        source_range = rotio::TimeRange(rotio::RationalTime(s, 24), rotio::RationalTime(d, 24)))
    rtr <- function(t) c(unname(t$start_time[["value"]]), unname(t$start_time[["rate"]]),
                         unname(t$duration[["value"]]), unname(t$duration[["rate"]]))
    ntr <- function(t) c(value(start_time(t)), rate(start_time(t)), value(duration(t)), rate(duration(t)))

    rA <- rmk("A", 10, 24); rB <- rmk("B", 5, 30)
    rtrk <- rotio::Track("V1")
    rotio::append_child(rtrk, rA); rotio::append_child(rtrk, rotio::Gap(rotio::RationalTime(12, 24)))
    rotio::append_child(rtrk, rB)
    expect_equal(ntr(range_in_parent(A)), rtr(rotio::range_in_parent(rA)))
    expect_equal(ntr(range_in_parent(B)), rtr(rotio::range_in_parent(rB)))
    expect_equal(ntr(trimmed_range(A)), rtr(rotio::trimmed_range(rA)))

    # track_trimmed_to_range parity (compare each child's source_range)
    nt <- track_trimmed_to_range(trk, TimeRange(RationalTime(10, 24), RationalTime(40, 24)))
    rt <- rotio::track_trimmed_to_range(rtrk, rotio::TimeRange(rotio::RationalTime(10, 24), rotio::RationalTime(40, 24)))
    expect_equal(length(children(nt)), length(rotio::children(rt)))
    for (k in seq_along(children(nt))) {
        nsr <- source_range(children(nt)[[k]]); rsr <- rotio::source_range(rotio::children(rt)[[k]])
        expect_equal(ntr(nsr), rtr(rsr), info = paste("ttr child", k))
    }

    # flatten_stack parity
    nv1 <- Track("V1"); append_child(nv1, mkclip("x", 0, 10))
    nv2 <- Track("V2"); append_child(nv2, Gap(RationalTime(3, 24))); append_child(nv2, mkclip("y", 0, 10))
    nf <- flatten_stack(list(nv1, nv2))
    rv1 <- rotio::Track("V1"); rotio::append_child(rv1, rmk("x", 0, 10))
    rv2 <- rotio::Track("V2"); rotio::append_child(rv2, rotio::Gap(rotio::RationalTime(3, 24)))
    rotio::append_child(rv2, rmk("y", 0, 10))
    rf <- rotio::flatten_stack(list(rv1, rv2))
    expect_equal(length(children(nf)), length(rotio::children(rf)))
    for (k in seq_along(children(nf))) {
        expect_equal(ntr(source_range(children(nf)[[k]])),
                     rtr(rotio::source_range(rotio::children(rf)[[k]])), info = paste("flatten child", k))
    }
}

# ---- Phase 4 review fixes: transitions, track ranges, rate-faithful trim ----
A2 <- mkclip("A", 0, 10)
B2 <- mkclip("B", 0, 10)
Tn <- Transition("T", "SMPTE_Dissolve", RationalTime(2, 24), RationalTime(3, 24))
trkt <- Track("V1")
append_child(trkt, A2); append_child(trkt, Tn); append_child(trkt, B2)
expect_equal(c(value(start_time(range_in_parent(Tn))), value(duration(range_in_parent(Tn)))), c(8, 5))
expect_equal(value(start_time(range_in_parent(B2))), 10)
expect_equal(value(duration(visible_range(A2))), 13)    # next transition out_offset
expect_equal(value(start_time(visible_range(B2))), -2)  # prev transition in_offset

t2 <- Track("V2")
append_child(t2, mkclip("a", 0, 10)); append_child(t2, Gap(RationalTime(5, 24))); append_child(t2, mkclip("b", 0, 8))
expect_equal(value(duration(available_range(t2))), 23)

expect_false(visible(Gap(RationalTime(3, 24))))
expect_true(visible(Tn))
disc <- mkclip("d", 0, 5); enabled(disc) <- FALSE
expect_false(visible(disc))
expect_true(overlapping(Tn))
expect_false(overlapping(trkt))

if (requireNamespace("rotio", quietly = TRUE)) {
    rmk2 <- function(n, s, d, r = 24) rotio::Clip(n, rotio::ExternalReference(paste0(n, ".mov")),
        source_range = rotio::TimeRange(rotio::RationalTime(s, r), rotio::RationalTime(d, r)))
    rtr <- function(t) c(unname(t$start_time[["value"]]), unname(t$start_time[["rate"]]),
                         unname(t$duration[["value"]]), unname(t$duration[["rate"]]))
    ntr <- function(t) c(value(start_time(t)), rate(start_time(t)), value(duration(t)), rate(duration(t)))

    rA <- rmk2("A", 0, 10); rB <- rmk2("B", 0, 10)
    rT <- rotio::Transition("T", "SMPTE_Dissolve", rotio::RationalTime(2, 24), rotio::RationalTime(3, 24))
    rtk <- rotio::Track("V1")
    rotio::append_child(rtk, rA); rotio::append_child(rtk, rT); rotio::append_child(rtk, rB)
    expect_equal(ntr(range_in_parent(Tn)), rtr(rotio::range_in_parent(rT)))
    expect_equal(ntr(range_in_parent(B2)), rtr(rotio::range_in_parent(rB)))
    expect_equal(ntr(visible_range(A2)), rtr(rotio::visible_range(rA)))
    expect_equal(ntr(visible_range(B2)), rtr(rotio::visible_range(rB)))

    rt2 <- rotio::Track("V2")
    rotio::append_child(rt2, rmk2("a", 0, 10)); rotio::append_child(rt2, rotio::Gap(rotio::RationalTime(5, 24)))
    rotio::append_child(rt2, rmk2("b", 0, 8))
    expect_equal(ntr(available_range(t2)), rtr(rotio::available_range(rt2)))

    # cross-rate trim: 24fps window into a 30fps clip
    t30 <- Track("V"); append_child(t30, mkclip("c", 0, 30, 30))
    nt30 <- track_trimmed_to_range(t30, TimeRange(RationalTime(5, 24), RationalTime(12, 24)))
    rt30 <- rotio::Track("V"); rotio::append_child(rt30, rmk2("c", 0, 30, 30))
    rrt30 <- rotio::track_trimmed_to_range(rt30, rotio::TimeRange(rotio::RationalTime(5, 24), rotio::RationalTime(12, 24)))
    expect_equal(ntr(source_range(children(nt30)[[1]])),
                 rtr(rotio::source_range(rotio::children(rrt30)[[1]])))   # 6.25@30 + 15@30

    # flatten respects enabled=FALSE on the top clip
    nv1 <- Track("V1"); append_child(nv1, mkclip("x", 0, 10))
    nv2 <- Track("V2"); dy <- mkclip("y", 0, 10); enabled(dy) <- FALSE; append_child(nv2, dy)
    nf <- flatten_stack(list(nv1, nv2))
    rv1 <- rotio::Track("V1"); rotio::append_child(rv1, rmk2("x", 0, 10))
    rv2 <- rotio::Track("V2"); rdy <- rmk2("y", 0, 10); rotio::enabled(rdy) <- FALSE; rotio::append_child(rv2, rdy)
    rf <- rotio::flatten_stack(list(rv1, rv2))
    expect_equal(length(children(nf)), length(rotio::children(rf)))
    for (k in seq_along(children(nf))) {
        expect_equal(ntr(source_range(children(nf)[[k]])),
                     rtr(rotio::source_range(rotio::children(rf)[[k]])), info = paste("flatten-disabled", k))
    }
}
