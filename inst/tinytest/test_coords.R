# Phase 4: composition coordinate model, validated against RcppOTIO.

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

# ---- RcppOTIO parity ----
if (requireNamespace("RcppOTIO", quietly = TRUE)) {
    rmk <- function(n, s, d) RcppOTIO::Clip(n, RcppOTIO::ExternalReference(paste0(n, ".mov")),
        source_range = RcppOTIO::TimeRange(RcppOTIO::RationalTime(s, 24), RcppOTIO::RationalTime(d, 24)))
    rtr <- function(t) c(unname(t$start_time[["value"]]), unname(t$start_time[["rate"]]),
                         unname(t$duration[["value"]]), unname(t$duration[["rate"]]))
    ntr <- function(t) c(value(start_time(t)), rate(start_time(t)), value(duration(t)), rate(duration(t)))

    rA <- rmk("A", 10, 24); rB <- rmk("B", 5, 30)
    rtrk <- RcppOTIO::Track("V1")
    RcppOTIO::append_child(rtrk, rA); RcppOTIO::append_child(rtrk, RcppOTIO::Gap(RcppOTIO::RationalTime(12, 24)))
    RcppOTIO::append_child(rtrk, rB)
    expect_equal(ntr(range_in_parent(A)), rtr(RcppOTIO::range_in_parent(rA)))
    expect_equal(ntr(range_in_parent(B)), rtr(RcppOTIO::range_in_parent(rB)))
    expect_equal(ntr(trimmed_range(A)), rtr(RcppOTIO::trimmed_range(rA)))

    # track_trimmed_to_range parity (compare each child's source_range)
    nt <- track_trimmed_to_range(trk, TimeRange(RationalTime(10, 24), RationalTime(40, 24)))
    rt <- RcppOTIO::track_trimmed_to_range(rtrk, RcppOTIO::TimeRange(RcppOTIO::RationalTime(10, 24), RcppOTIO::RationalTime(40, 24)))
    expect_equal(length(children(nt)), length(RcppOTIO::children(rt)))
    for (k in seq_along(children(nt))) {
        nsr <- source_range(children(nt)[[k]]); rsr <- RcppOTIO::source_range(RcppOTIO::children(rt)[[k]])
        expect_equal(ntr(nsr), rtr(rsr), info = paste("ttr child", k))
    }

    # flatten_stack parity
    nv1 <- Track("V1"); append_child(nv1, mkclip("x", 0, 10))
    nv2 <- Track("V2"); append_child(nv2, Gap(RationalTime(3, 24))); append_child(nv2, mkclip("y", 0, 10))
    nf <- flatten_stack(list(nv1, nv2))
    rv1 <- RcppOTIO::Track("V1"); RcppOTIO::append_child(rv1, rmk("x", 0, 10))
    rv2 <- RcppOTIO::Track("V2"); RcppOTIO::append_child(rv2, RcppOTIO::Gap(RcppOTIO::RationalTime(3, 24)))
    RcppOTIO::append_child(rv2, rmk("y", 0, 10))
    rf <- RcppOTIO::flatten_stack(list(rv1, rv2))
    expect_equal(length(children(nf)), length(RcppOTIO::children(rf)))
    for (k in seq_along(children(nf))) {
        expect_equal(ntr(source_range(children(nf)[[k]])),
                     rtr(RcppOTIO::source_range(RcppOTIO::children(rf)[[k]])), info = paste("flatten child", k))
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

if (requireNamespace("RcppOTIO", quietly = TRUE)) {
    rmk2 <- function(n, s, d, r = 24) RcppOTIO::Clip(n, RcppOTIO::ExternalReference(paste0(n, ".mov")),
        source_range = RcppOTIO::TimeRange(RcppOTIO::RationalTime(s, r), RcppOTIO::RationalTime(d, r)))
    rtr <- function(t) c(unname(t$start_time[["value"]]), unname(t$start_time[["rate"]]),
                         unname(t$duration[["value"]]), unname(t$duration[["rate"]]))
    ntr <- function(t) c(value(start_time(t)), rate(start_time(t)), value(duration(t)), rate(duration(t)))

    rA <- rmk2("A", 0, 10); rB <- rmk2("B", 0, 10)
    rT <- RcppOTIO::Transition("T", "SMPTE_Dissolve", RcppOTIO::RationalTime(2, 24), RcppOTIO::RationalTime(3, 24))
    rtk <- RcppOTIO::Track("V1")
    RcppOTIO::append_child(rtk, rA); RcppOTIO::append_child(rtk, rT); RcppOTIO::append_child(rtk, rB)
    expect_equal(ntr(range_in_parent(Tn)), rtr(RcppOTIO::range_in_parent(rT)))
    expect_equal(ntr(range_in_parent(B2)), rtr(RcppOTIO::range_in_parent(rB)))
    expect_equal(ntr(visible_range(A2)), rtr(RcppOTIO::visible_range(rA)))
    expect_equal(ntr(visible_range(B2)), rtr(RcppOTIO::visible_range(rB)))

    rt2 <- RcppOTIO::Track("V2")
    RcppOTIO::append_child(rt2, rmk2("a", 0, 10)); RcppOTIO::append_child(rt2, RcppOTIO::Gap(RcppOTIO::RationalTime(5, 24)))
    RcppOTIO::append_child(rt2, rmk2("b", 0, 8))
    expect_equal(ntr(available_range(t2)), rtr(RcppOTIO::available_range(rt2)))

    # cross-rate trim: 24fps window into a 30fps clip
    t30 <- Track("V"); append_child(t30, mkclip("c", 0, 30, 30))
    nt30 <- track_trimmed_to_range(t30, TimeRange(RationalTime(5, 24), RationalTime(12, 24)))
    rt30 <- RcppOTIO::Track("V"); RcppOTIO::append_child(rt30, rmk2("c", 0, 30, 30))
    rrt30 <- RcppOTIO::track_trimmed_to_range(rt30, RcppOTIO::TimeRange(RcppOTIO::RationalTime(5, 24), RcppOTIO::RationalTime(12, 24)))
    expect_equal(ntr(source_range(children(nt30)[[1]])),
                 rtr(RcppOTIO::source_range(RcppOTIO::children(rrt30)[[1]])))   # 6.25@30 + 15@30

    # flatten respects enabled=FALSE on the top clip
    nv1 <- Track("V1"); append_child(nv1, mkclip("x", 0, 10))
    nv2 <- Track("V2"); dy <- mkclip("y", 0, 10); enabled(dy) <- FALSE; append_child(nv2, dy)
    nf <- flatten_stack(list(nv1, nv2))
    rv1 <- RcppOTIO::Track("V1"); RcppOTIO::append_child(rv1, rmk2("x", 0, 10))
    rv2 <- RcppOTIO::Track("V2"); rdy <- rmk2("y", 0, 10); RcppOTIO::enabled(rdy) <- FALSE; RcppOTIO::append_child(rv2, rdy)
    rf <- RcppOTIO::flatten_stack(list(rv1, rv2))
    expect_equal(length(children(nf)), length(RcppOTIO::children(rf)))
    for (k in seq_along(children(nf))) {
        expect_equal(ntr(source_range(children(nf)[[k]])),
                     rtr(RcppOTIO::source_range(RcppOTIO::children(rf)[[k]])), info = paste("flatten-disabled", k))
    }
}

# ---- Stack parallel semantics + transitions in algorithms ----
sv1 <- Track("V1"); append_child(sv1, mkclip("p", 0, 10))
sv2 <- Track("V2"); append_child(sv2, mkclip("q", 0, 5))
stk <- Stack(); append_child(stk, sv1); append_child(stk, sv2)
expect_equal(c(value(start_time(range_in_parent(sv2))), value(duration(range_in_parent(sv2)))), c(0, 5))
expect_equal(value(duration(available_range(stk))), 10)   # max, not sum

# track_trimmed_to_range keeps transitions (no error)
trx <- Track("V1")
append_child(trx, mkclip("A", 0, 10))
append_child(trx, Transition("T", "SMPTE_Dissolve", RationalTime(2, 24), RationalTime(3, 24)))
append_child(trx, mkclip("B", 0, 10))
ttx <- track_trimmed_to_range(trx, TimeRange(RationalTime(0, 24), RationalTime(20, 24)))
expect_equal(vapply(children(ttx), function(c) class(c)[1], ""), c("Clip", "Transition", "Clip"))

# track_trimmed_to_range transition keep/drop/error (extent [8,13))
expect_equal(length(children(track_trimmed_to_range(trx, TimeRange(RationalTime(0, 24), RationalTime(5, 24))))), 1L)   # drop T
expect_equal(length(children(track_trimmed_to_range(trx, TimeRange(RationalTime(15, 24), RationalTime(5, 24))))), 1L)  # drop T
expect_equal(vapply(children(track_trimmed_to_range(trx, TimeRange(RationalTime(5, 24), RationalTime(10, 24)))),
                    function(c) class(c)[1], ""), c("Clip", "Transition", "Clip"))                                     # keep T
expect_error(track_trimmed_to_range(trx, TimeRange(RationalTime(0, 24), RationalTime(10, 24))))                        # cut mid-T

# flatten_stack preserves transitions
ftx <- flatten_stack(list(trx))
expect_equal(vapply(children(ftx), function(c) class(c)[1], ""), c("Clip", "Transition", "Clip"))

if (requireNamespace("RcppOTIO", quietly = TRUE)) {
    rmk3 <- function(n, s, d) RcppOTIO::Clip(n, RcppOTIO::ExternalReference(paste0(n, ".mov")),
        source_range = RcppOTIO::TimeRange(RcppOTIO::RationalTime(s, 24), RcppOTIO::RationalTime(d, 24)))
    rtr <- function(t) c(unname(t$start_time[["value"]]), unname(t$start_time[["rate"]]),
                         unname(t$duration[["value"]]), unname(t$duration[["rate"]]))
    ntr <- function(t) c(value(start_time(t)), rate(start_time(t)), value(duration(t)), rate(duration(t)))

    rsv1 <- RcppOTIO::Track("V1"); RcppOTIO::append_child(rsv1, rmk3("p", 0, 10))
    rsv2 <- RcppOTIO::Track("V2"); RcppOTIO::append_child(rsv2, rmk3("q", 0, 5))
    rstk <- RcppOTIO::Stack(); RcppOTIO::append_child(rstk, rsv1); RcppOTIO::append_child(rstk, rsv2)
    expect_equal(ntr(range_in_parent(sv2)), rtr(RcppOTIO::range_in_parent(rsv2)))
    expect_equal(ntr(available_range(stk)), rtr(RcppOTIO::available_range(rstk)))

    rtx <- RcppOTIO::Track("V1")
    RcppOTIO::append_child(rtx, rmk3("A", 0, 10))
    RcppOTIO::append_child(rtx, RcppOTIO::Transition("T", "SMPTE_Dissolve", RcppOTIO::RationalTime(2, 24), RcppOTIO::RationalTime(3, 24)))
    RcppOTIO::append_child(rtx, rmk3("B", 0, 10))
    rttx <- RcppOTIO::track_trimmed_to_range(rtx, RcppOTIO::TimeRange(RcppOTIO::RationalTime(0, 24), RcppOTIO::RationalTime(20, 24)))
    expect_equal(length(children(ttx)), length(RcppOTIO::children(rttx)))

    cls <- function(t) vapply(children(t), function(c) class(c)[1], "")
    rcls <- function(t) vapply(RcppOTIO::children(t), function(c) class(c)[1], "")
    rwin <- function() {
        rt <- RcppOTIO::TimeRange
        rT <- RcppOTIO::RationalTime
        for (w in list(c(0, 5), c(15, 5), c(5, 10), c(7, 9))) {
            n <- track_trimmed_to_range(trx, TimeRange(RationalTime(w[1], 24), RationalTime(w[2], 24)))
            r <- RcppOTIO::track_trimmed_to_range(rtx, rt(rT(w[1], 24), rT(w[2], 24)))
            expect_equal(cls(n), rcls(r), info = paste("trim", w[1], w[2]))
        }
    }
    rwin()
    expect_error(RcppOTIO::track_trimmed_to_range(rtx, RcppOTIO::TimeRange(RcppOTIO::RationalTime(0, 24), RcppOTIO::RationalTime(10, 24))))

    # flatten parity: single track + bottom-fill both preserve the transition
    expect_equal(cls(flatten_stack(list(trx))), rcls(RcppOTIO::flatten_stack(list(rtx))))

    # flatten parity: a shorter top track lets the longer bottom show through
    srng <- function(t) lapply(children(t), function(c) {
        sr <- source_range(c); c(value(start_time(sr)), value(duration(sr)))
    })
    rsrng <- function(t) lapply(RcppOTIO::children(t), function(c) {
        sr <- RcppOTIO::source_range(c); c(unname(sr$start_time[["value"]]), unname(sr$duration[["value"]]))
    })
    ntop <- Track("V2"); append_child(ntop, mkclip("A", 0, 10))
    nbot <- Track("V1"); append_child(nbot, mkclip("B", 0, 20))
    rtop <- RcppOTIO::Track("V2"); RcppOTIO::append_child(rtop, rmk3("A", 0, 10))
    rbot <- RcppOTIO::Track("V1"); RcppOTIO::append_child(rbot, rmk3("B", 0, 20))
    expect_equal(srng(flatten_stack(list(nbot, ntop))),
                 rsrng(RcppOTIO::flatten_stack(list(rbot, rtop))))   # A[0+10], B[10+10]
    botf <- Track("V0"); append_child(botf, mkclip("Z", 0, 20))
    rbotf <- RcppOTIO::Track("V0"); RcppOTIO::append_child(rbotf, rmk3("Z", 0, 20))
    topgap <- Track("V1"); append_child(topgap, Gap(RationalTime(20, 24)))
    rtopgap <- RcppOTIO::Track("V1"); RcppOTIO::append_child(rtopgap, RcppOTIO::Gap(RcppOTIO::RationalTime(20, 24)))
    expect_equal(cls(flatten_stack(list(trx, topgap))),
                 rcls(RcppOTIO::flatten_stack(list(rtx, rtopgap))))
}

# ---- phase 4 source review fixes ----
ptrk <- Track("V")
pcl <- Clip("A", ExternalReference("a.mov"), source_range = TimeRange(RationalTime(0, 24), RationalTime(10, 24)))
append_child(ptrk, pcl)
source_range(ptrk) <- TimeRange(RationalTime(5, 24), RationalTime(3, 24))
tip <- trimmed_range_in_parent(pcl)
expect_equal(c(value(start_time(tip)), value(duration(tip))), c(5, 3))   # parent coords, not translated
ptrk2 <- Track("V")
pgap <- Gap(RationalTime(10, 24))
pcl2 <- Clip("A", ExternalReference("a.mov"), source_range = TimeRange(RationalTime(0, 24), RationalTime(3, 24)))
append_child(ptrk2, pgap)
append_child(ptrk2, pcl2)
source_range(ptrk2) <- TimeRange(RationalTime(0, 24), RationalTime(3, 24))
expect_error(trimmed_range_in_parent(pcl2))   # child fully outside parent source range
# exact boundary contact (child starts at parent source-range end) is no overlap -> error
ptrk3 <- Track("V")
append_child(ptrk3, mkclip("A", 0, 5))
pcl3 <- mkclip("B", 0, 5)
append_child(ptrk3, pcl3)            # B's range_in_parent starts at 5
source_range(ptrk3) <- TimeRange(RationalTime(0, 24), RationalTime(5, 24))   # parent ends at 5
expect_error(trimmed_range_in_parent(pcl3))

# flatten list overload does NOT filter disabled tracks (only the Stack overload does)
dbot <- Track("V0"); append_child(dbot, mkclip("B", 0, 20))
dtop <- Track("V1"); append_child(dtop, mkclip("A", 0, 10)); enabled(dtop) <- FALSE
dfd <- flatten_stack(list(dbot, dtop))
expect_equal(vapply(children(dfd), function(c) class(c)[1], ""), c("Clip", "Clip"))
expect_equal(value(duration(source_range(children(dfd)[[1L]]))), 10)
# but the Stack overload DOES filter the disabled top: only B shows
sbot <- Track("V0"); append_child(sbot, mkclip("B", 0, 20))
stop_ <- Track("V1"); append_child(stop_, mkclip("A", 0, 10)); enabled(stop_) <- FALSE
sstk <- Stack(); append_child(sstk, sbot); append_child(sstk, stop_)
sfd <- flatten_stack(sstk)
expect_equal(vapply(children(sfd), function(c) class(c)[1], ""), "Clip")
expect_equal(value(duration(source_range(children(sfd)[[1L]]))), 20)
