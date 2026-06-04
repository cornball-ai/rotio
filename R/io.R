# sequence.md as canonical artifact.
#
# sequence.md holds human prose plus ONE delimited state block carrying raw
# OpenTimelineIO JSON:
#
#   <!-- sequence:state otio -->
#   { ... OTIO JSON ... }
#   <!-- /sequence:state -->
#
# OTIO owns the serialization (each object carries its own OTIO_SCHEMA); the
# marker just identifies the block as OTIO. Parsing is strict: missing,
# duplicated, or malformed markers are errors. Writing surgically replaces only
# the state block and preserves all surrounding prose.

.OPEN_RE  <- "(?m)^<!--\\s*sequence:state\\s+(otio)\\s*-->\\s*$"
.CLOSE_RE <- "(?m)^<!--\\s*/sequence:state\\s*-->\\s*$"
.OPEN_TAG  <- "<!-- sequence:state otio -->"
.CLOSE_TAG <- "<!-- /sequence:state -->"

# Find the single state block; return marker positions and the raw body.
# Errors on missing / duplicated markers or close-before-open.
.find_state_block <- function(txt) {
    opens  <- gregexpr(.OPEN_RE,  txt, perl = TRUE)[[1]]
    closes <- gregexpr(.CLOSE_RE, txt, perl = TRUE)[[1]]
    n_open  <- if (opens[1]  == -1L) 0L else length(opens)
    n_close <- if (closes[1] == -1L) 0L else length(closes)
    if (n_open == 0L) {
        stop("sequence.md is missing the opening marker ",
             "'<!-- sequence:state otio -->'.", call. = FALSE)
    }
    if (n_open > 1L) {
        stop("sequence.md has ", n_open,
             " opening markers; exactly one is allowed.", call. = FALSE)
    }
    if (n_close == 0L) {
        stop("sequence.md is missing the closing marker ",
             "'<!-- /sequence:state -->'.", call. = FALSE)
    }
    if (n_close > 1L) {
        stop("sequence.md has ", n_close,
             " closing markers; exactly one is allowed.", call. = FALSE)
    }
    open_start <- opens[1L]
    open_end   <- open_start + attr(opens, "match.length")[1L] - 1L
    close_start <- closes[1L]
    close_end   <- close_start + attr(closes, "match.length")[1L] - 1L
    if (close_start <= open_end) {
        stop("sequence.md closing marker appears before the opening marker.",
             call. = FALSE)
    }
    list(open_start = open_start, open_end = open_end,
         close_start = close_start, close_end = close_end,
         body = substr(txt, open_end + 1L, close_start - 1L))
}

# Strip a surrounding ``` ... ``` fence if a Markdown editor re-fenced on save.
.strip_optional_fence <- function(body) {
    body <- trimws(body)
    if (startsWith(body, "```")) {
        lines <- strsplit(body, "\n", fixed = TRUE)[[1]]
        if (length(lines) >= 2L && grepl("^```", lines[length(lines)])) {
            body <- paste(lines[-c(1L, length(lines))], collapse = "\n")
        }
    }
    body
}

#' Serialize / restore a sequence as OTIO JSON
#'
#' \code{sequence_to_json()} renders the sequence's OTIO Timeline to canonical
#' \code{.otio} JSON; \code{sequence_from_json()} parses it back into an
#' \code{nle_sequence}. OTIO performs the (de)serialization.
#'
#' @param seq An \code{nle_sequence}.
#' @param pretty Ignored (OTIO pretty-prints); kept for compatibility.
#' @return \code{sequence_to_json}: a JSON string. \code{sequence_from_json}: an
#'   \code{nle_sequence}.
#' @export
sequence_to_json <- function(seq, pretty = TRUE) {
    if (!is_sequence(seq)) {
        stop("sequence_to_json: seq must be an nle_sequence", call. = FALSE)
    }
    otio_timeline_to_json(seq$ptr)
}

#' @rdname sequence_to_json
#' @param json An OTIO JSON string.
#' @export
sequence_from_json <- function(json) {
    structure(list(ptr = otio_timeline_from_json(as.character(json))),
              class = "nle_sequence")
}

#' Extract the state block payload from a sequence.md
#' @param path Path to a sequence.md file.
#' @return The raw OTIO JSON payload between markers.
#' @export
extract_sequence_state_md <- function(path) {
    if (!file.exists(path)) {
        stop("extract_sequence_state_md: file not found: ", path, call. = FALSE)
    }
    txt <- paste(readLines(path, warn = FALSE), collapse = "\n")
    .strip_optional_fence(.find_state_block(txt)$body)
}

#' Read a sequence from a sequence.md file
#'
#' Parses the single OTIO state block and returns an \code{nle_sequence}. The
#' surrounding prose is attached as the \code{"prose"} attribute so
#' \code{write_sequence()} can preserve it. Strict parser.
#'
#' @param path Path to a sequence.md file.
#' @return An \code{nle_sequence}.
#' @export
read_sequence <- function(path) {
    if (!file.exists(path)) {
        stop("read_sequence: file not found: ", path, call. = FALSE)
    }
    txt <- paste(readLines(path, warn = FALSE), collapse = "\n")
    blk <- .find_state_block(txt)
    seq <- sequence_from_json(.strip_optional_fence(blk$body))
    attr(seq, "prose") <- list(
        pre = substr(txt, 1L, blk$open_end),
        post = substr(txt, blk$close_start, nchar(txt)),
        source_path = path)
    seq
}

#' Write a sequence back to a sequence.md file
#'
#' Preserves prose outside the state block, surgically replacing only the OTIO
#' JSON payload. If \code{path} doesn't exist (or the sequence has no attached
#' prose), writes a minimal new file with a stub header and the state block.
#'
#' @param seq An \code{nle_sequence}.
#' @param path Path to write to; defaults to where \code{seq} was read from.
#' @return The path, invisibly.
#' @export
write_sequence <- function(seq, path = NULL) {
    if (!is_sequence(seq)) {
        stop("write_sequence: seq must be an nle_sequence", call. = FALSE)
    }
    prose <- attr(seq, "prose")
    path <- path %||% prose$source_path
    if (is.null(path)) {
        stop("write_sequence: path is required for sequences that weren't ",
             "read from a file.", call. = FALSE)
    }
    payload <- sequence_to_json(seq)

    if (!is.null(prose$pre) && !is.null(prose$post)) {
        new_txt <- paste0(prose$pre, "\n", payload, "\n", prose$post)
    } else if (file.exists(path)) {
        existing_txt <- paste(readLines(path, warn = FALSE), collapse = "\n")
        blk <- tryCatch(.find_state_block(existing_txt), error = function(e) NULL)
        if (!is.null(blk)) {
            new_txt <- paste0(substr(existing_txt, 1L, blk$open_end), "\n",
                              payload, "\n",
                              substr(existing_txt, blk$close_start,
                                     nchar(existing_txt)))
        } else {
            new_txt <- paste0(existing_txt,
                              if (nchar(existing_txt) > 0L) "\n\n" else "",
                              .OPEN_TAG, "\n", payload, "\n", .CLOSE_TAG, "\n")
        }
    } else {
        new_txt <- paste0(
            sprintf("# sequence: %s\n\n", seq$id),
            "_Human prose goes above this point._\n\n",
            .OPEN_TAG, "\n", payload, "\n", .CLOSE_TAG, "\n")
    }
    writeLines(new_txt, path)
    invisible(path)
}

#' Replace only the state block in a sequence.md
#' @param path Path to a sequence.md.
#' @param seq An \code{nle_sequence}.
#' @return The path, invisibly.
#' @export
replace_sequence_state_md <- function(path, seq) write_sequence(seq, path)

#' Validate a sequence's structural invariants
#'
#' Checks no duplicate clip ids, and that every clip has a positive duration.
#' OTIO guarantees the rest of the structure (tracks are sequential, clips sit
#' on real tracks).
#'
#' @param seq An \code{nle_sequence}.
#' @return TRUE invisibly on success; stops with a clear error otherwise.
#' @export
validate_sequence <- function(seq) {
    if (!is_sequence(seq)) {
        stop("validate_sequence: seq must be an nle_sequence", call. = FALSE)
    }
    clips <- seq$clips
    if (anyDuplicated(clips$id)) {
        stop("validate_sequence: duplicate clip ids", call. = FALSE)
    }
    if (nrow(clips) > 0L) {
        bad <- clips$tl_out <= clips$tl_in
        if (any(bad)) {
            stop("validate_sequence: clip(s) have tl_out <= tl_in: ",
                 paste(clips$id[bad], collapse = ", "), call. = FALSE)
        }
    }
    invisible(TRUE)
}
