# Composition tree operations (reference semantics). These MUTATE in place and
# return the parent invisibly, mirroring rotio: append/insert/set/remove update
# `.parent` pointers, and attaching an already-parented child errors. Indices are
# 1-based. The functional builders add_child()/add_track() (build.R) wrap these
# with clone() for value-semantics callers.

# Holds children (Track, Stack, SerializableCollection).
.is_container <- function(x) is_otio(x) && "children" %in% x$.keys

# A Composition (Track/Stack) accepts only composables; a SerializableCollection
# accepts any OTIO object.
.is_composable <- function(x) inherits(x,
                                       c("Item", "Composition", "Transition"))

.check_child <- function(x, child) {
    if (!is_otio(child)) {
        stop("child must be an OTIO object", call. = FALSE)
    }
    if (is_composition(x) && !.is_composable(child)) {
        stop("child must be a composable (clip, gap, track, transition)",
             call. = FALSE)
    }
    if (!is.null(child$.parent)) {
        stop("child already has a parent", call. = FALSE)
    }
}

#' Construct a SerializableCollection
#'
#' A flat, named collection of OTIO objects (not a composition).
#'
#' @param name Collection name.
#' @param children A list of OTIO objects.
#' @param metadata Named list of metadata.
#' @return A \code{SerializableCollection}.
#' @export
SerializableCollection <- function(name = "", children = list(),
                                   metadata = NULL) {
    x <- .new_otio("SerializableCollection",
                   c("OTIO_SCHEMA", "metadata", "name", "children"),
                   list(OTIO_SCHEMA = "SerializableCollection.1",
                        metadata = .as_metadata(metadata), name = as.character(name),
                        children = list()))
    for (ch in children) {
        append_child(x, ch)
    }
    x
}

#' Children of a composition or collection
#' @param x A composition (Track/Stack) or collection.
#' @return A list of child OTIO objects, in order.
#' @export
children <- function(x) {
    if (!.is_container(x)) {
        stop("children: x has no children", call. = FALSE)
    }
    x$children
}

#' Parent of an OTIO object
#'
#' The containing composition/collection, or \code{NULL}. A Timeline's root track
#' Stack is parentless.
#'
#' @param x An OTIO object.
#' @return The parent object or \code{NULL}.
#' @export
parent <- function(x) x$.parent

#' Append a child to a composition (in place)
#'
#' Mutates \code{x}, attaching \code{child} and setting its parent. Errors if
#' \code{child} already has a parent (use \code{\link{remove_child}} first, or
#' the functional \code{\link{add_child}}). Returns \code{x} invisibly.
#'
#' @param x A composition or collection.
#' @param child An OTIO object with no parent.
#' @return \code{x}, invisibly.
#' @examples
#' trk <- Track("V1")
#' append_child(trk, Clip("a", ExternalReference("a.mp4")))
#' length(children(trk))
#' @export
append_child <- function(x, child) {
    if (!.is_container(x)) {
        stop("append_child: x must hold children", call. = FALSE)
    }
    .check_child(x, child)
    x$children <- c(x$children, list(child))
    child$.parent <- x
    invisible(x)
}

#' Insert a child at a 1-based position (in place)
#' @param x A composition or collection.
#' @param index 1-based position.
#' @param child An OTIO object with no parent.
#' @return \code{x}, invisibly.
#' @export
insert_child <- function(x, index, child) {
    if (!.is_container(x)) {
        stop("insert_child: x must hold children", call. = FALSE)
    }
    .check_child(x, child)
    i <- as.integer(index)
    n <- length(x$children)
    if (i < 1L || i > n + 1L) {
        stop("insert_child: index out of range", call. = FALSE)
    }
    x$children <- append(x$children, list(child), after = i - 1L)
    child$.parent <- x
    invisible(x)
}

#' Replace the child at a position (in place)
#'
#' Detaches the replaced child and attaches the new one. Returns \code{x}
#' invisibly.
#'
#' @param x A composition or collection.
#' @param index 1-based position.
#' @param child An OTIO object with no parent.
#' @return \code{x}, invisibly.
#' @export
set_child <- function(x, index, child) {
    if (!.is_container(x)) {
        stop("set_child: x must hold children", call. = FALSE)
    }
    i <- as.integer(index)
    if (i < 1L || i > length(x$children)) {
        stop("set_child: index out of range", call. = FALSE)
    }
    .check_child(x, child)
    x$children[[i]]$.parent <- NULL
    child$.parent <- x
    x$children[[i]] <- child
    invisible(x)
}

#' Replace all children (in place)
#'
#' Available as \code{set_children(x, kids)} and \code{set_children(x) <- kids}.
#'
#' @param x A composition or collection.
#' @param children,value A list of parentless OTIO objects.
#' @return \code{x} (invisibly from the function form).
#' @export
set_children <- function(x, children) {
    if (!.is_container(x)) {
        stop("set_children: x must hold children", call. = FALSE)
    }
    for (ch in children) {
        .check_child(x, ch)
    }
    for (old in x$children) {
        old$.parent <- NULL
    }
    for (ch in children) {
        ch$.parent <- x
    }
    x$children <- children
    invisible(x)
}

#' @rdname set_children
#' @export
`set_children<-` <- function(x, value) {
    set_children(x, value)
    x
}

#' Remove the child at a position (in place)
#' @param x A composition or collection.
#' @param index 1-based position.
#' @return \code{x}, invisibly.
#' @export
remove_child <- function(x, index) {
    if (!.is_container(x)) {
        stop("remove_child: x must hold children", call. = FALSE)
    }
    i <- as.integer(index)
    if (i < 1L || i > length(x$children)) {
        stop("remove_child: index out of range", call. = FALSE)
    }
    x$children[[i]]$.parent <- NULL
    x$children <- x$children[-i]
    invisible(x)
}

#' Remove all children (in place)
#' @param x A composition or collection.
#' @return \code{x}, invisibly.
#' @export
clear_children <- function(x) {
    if (!.is_container(x)) {
        stop("clear_children: x must hold children", call. = FALSE)
    }
    for (old in x$children) {
        old$.parent <- NULL
    }
    x$children <- list()
    invisible(x)
}

#' 1-based position of a child, or NA
#' @param x A composition or collection.
#' @param child An OTIO object.
#' @export
index_of_child <- function(x, child) {
    hits <- which(vapply(x$children, function(c) identical(c, child),
                         logical(1)))
    if (length(hits)) {
        hits[1]
    } else {
        NA_integer_
    }
}

#' Does a composition directly contain a child?
#' @param x A composition or collection.
#' @param child An OTIO object.
#' @export
has_child <- function(x, child) {
    any(vapply(x$children, function(c) identical(c, child), logical(1)))
}

#' Is x an ancestor of other?
#' @param x A composition or collection.
#' @param other An OTIO object.
#' @export
is_parent_of <- function(x, other) {
    p <- other$.parent
    while (!is.null(p)) {
        if (identical(p, x)) {
            return(TRUE)
        }
        p <- p$.parent
    }
    FALSE
}

#' All clips within an object (recursive)
#' @param x A Timeline, composition, or collection.
#' @return A list of \code{Clip} objects.
#' @export
find_clips <- function(x) {
    acc <- list()
    walk <- function(o) {
        if (inherits(o, "Clip")) {
            acc[[length(acc) + 1L]] <<- o
        } else if (is_timeline(o)) {
            walk(o$tracks)
        } else if (.is_container(o)) {
            for (ch in o$children) {
                walk(ch)
            }
        }
    }
    walk(x)
    acc
}

#' Does an object contain any clips (recursive)?
#' @param x A Timeline, composition, or collection.
#' @export
has_clips <- function(x) length(find_clips(x)) > 0L

# ---- media reference keys -------------------------------------------------

#' Media references of a clip
#' @param x A \code{\link{Clip}}.
#' @export
media_references <- function(x) x$media_references

#' Replace the media references of a clip (in place)
#' @param x A \code{\link{Clip}}.
#' @param media_references A named list of media references.
#' @param new_active_key Optional new active key.
#' @return \code{x}, invisibly.
#' @export
set_media_references <- function(x, media_references, new_active_key = NULL) {
    x$media_references <- media_references
    if (!is.null(new_active_key)) {
        x$active_media_reference_key <- new_active_key
    }
    invisible(x)
}

#' Active media reference key of a clip
#' @param x A \code{\link{Clip}}.
#' @param value New active key.
#' @export
active_media_reference_key <- function(x) x$active_media_reference_key

#' @rdname active_media_reference_key
#' @export
`active_media_reference_key<-` <- function(x, value) {
    x$active_media_reference_key <- as.character(value)
    x
}

#' The default media reference key (\code{"DEFAULT_MEDIA"})
#' @export
default_media_key <- function() "DEFAULT_MEDIA"

