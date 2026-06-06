# Phase 1 gate tests: environment-backed core, parent pointers, clone, tree ops.

clip <- function(nm) Clip(nm, ExternalReference(paste0(nm, ".mp4")),
                          source_range = TimeRange(RationalTime(0, 30), RationalTime(30, 30)))

# --- append_child mutates in place and sets the parent ---
trk <- Track("V1")
a <- clip("a")
expect_true(is.null(parent(a)))
append_child(trk, a)
expect_equal(length(children(trk)), 1L)          # mutated in place (no reassign)
expect_identical(parent(a), trk)                  # parent set

# --- single-parent invariant: appending an already-parented child errors ---
trk2 <- Track("V2")
expect_error(append_child(trk2, a))               # a already has a parent
expect_error(append_child(trk, RationalTime(0, 30)))  # not composable

# --- remove / clear detach (parent -> NULL) ---
remove_child(trk, 1L)
expect_equal(length(children(trk)), 0L)
expect_true(is.null(parent(a)))                   # detached
append_child(trk, a)
append_child(trk, clip("b"))
clear_children(trk)
expect_equal(length(children(trk)), 0L)
expect_true(is.null(parent(a)))

# --- set_child detaches the replaced child, attaches the new one ---
old <- clip("old"); new <- clip("new")
append_child(trk, old)
set_child(trk, 1L, new)
expect_true(is.null(parent(old)))
expect_identical(parent(new), trk)
expect_equal(name(children(trk)[[1]]), "new")
expect_error(set_child(trk, 1L, new))             # new now parented -> error

# --- insert_child, queries ---
s <- Track("V3")
c1 <- clip("c1"); c2 <- clip("c2"); c3 <- clip("c3")
append_child(s, c1); append_child(s, c3)
insert_child(s, 2L, c2)
expect_equal(vapply(children(s), name, ""), c("c1", "c2", "c3"))
expect_equal(index_of_child(s, c2), 2L)
expect_true(has_child(s, c2))
expect_true(has_clips(s))
expect_equal(length(find_clips(s)), 3L)

# --- root track Stack is parentless; appended tracks parent to the Stack ---
tl <- Timeline("demo")
expect_true(is.null(parent(tracks(tl))))
vt <- Track("V1")
append_child(tracks(tl), vt)
expect_identical(parent(vt), tracks(tl))
expect_true(is_parent_of(tl$tracks, vt))

# --- clone: root parent NULL, descendants point inside the clone, independent ---
src <- add_track(Timeline("src"), add_child(Track("V1"), clip("x")))
cl <- clone(src)
expect_true(is.null(parent(cl)))
expect_true(is.null(parent(tracks(cl))))
inner_track <- children(tracks(cl))[[1]]
expect_identical(parent(inner_track), tracks(cl))   # rewired inside the clone
inner_clip <- children(inner_track)[[1]]
expect_identical(parent(inner_clip), inner_track)
# mutating the clone does not touch the original
append_child(tracks(cl), Track("V2"))
expect_equal(length(children(tracks(cl))), 2L)
expect_equal(length(children(tracks(src))), 1L)

# --- JSON parse rewires parents ---
back <- from_json_string(to_json_string(src))
bt <- children(tracks(back))[[1]]
expect_identical(parent(bt), tracks(back))
expect_true(is.null(parent(tracks(back))))
bc <- children(bt)[[1]]
expect_identical(parent(bc), bt)

# --- functional add_child / add_track leave inputs untouched ---
v0 <- Track("V1")
v1 <- add_child(v0, clip("a"))
expect_equal(length(children(v0)), 0L)            # input untouched
expect_equal(length(children(v1)), 1L)
t0 <- Timeline("t")
t1 <- add_track(t0, Track("V1"))
expect_equal(length(children(tracks(t0))), 0L)
expect_equal(length(children(tracks(t1))), 1L)

# --- SerializableCollection holds arbitrary objects ---
coll <- SerializableCollection("c", list(Timeline("a"), Timeline("b")))
expect_equal(length(children(coll)), 2L)
expect_equal(coll$OTIO_SCHEMA, "SerializableCollection.1")

# --- .parent is never serialized ---
expect_false(grepl("parent", to_json_string(src), fixed = TRUE))
