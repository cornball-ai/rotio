# sequence.md as canonical artifact + sequence.json as cache.
#
# sequence.md holds human prose plus ONE delimited state block:
#
#   <!-- sequence:state json cornball.sequence.v1 -->
#   { ... payload ... }
#   <!-- /sequence:state -->
#
# Parsing is strict: missing, duplicated, or malformed markers are errors.
# Schema version mismatch is an error. Writing surgically replaces only the
# state block and preserves all surrounding prose.

.OPEN_RE  <- "(?m)^<!--\\s*sequence:state\\s+([[:alnum:]_-]+)\\s+([[:alnum:]_.-]+)\\s*-->\\s*$"
.CLOSE_RE <- "(?m)^<!--\\s*/sequence:state\\s*-->\\s*$"
.OPEN_FMT  <- "<!-- sequence:state %s %s -->"
.CLOSE_TAG <- "<!-- /sequence:state -->"
.SUPPORTED_SCHEMA   <- "cornball.sequence.v1"
.SUPPORTED_ENCODING <- "json"

# Internal: find the single state block in `txt`. Returns a list with
#   $open_match, $close_match (character positions; both start + stop),
#   $encoding, $schema, $body (the raw payload between markers).
# Errors on any of: missing marker, duplicated marker, close before open,
# encoding != "json", schema != cornball.sequence.v1.
.find_state_block <- function(txt) {
    opens  <- gregexpr(.OPEN_RE,  txt, perl = TRUE)[[1]]
    closes <- gregexpr(.CLOSE_RE, txt, perl = TRUE)[[1]]
    n_open  <- if (opens[1]  == -1L) 0L else length(opens)
    n_close <- if (closes[1] == -1L) 0L else length(closes)
    if (n_open == 0L) {
        stop("sequence.md is missing the opening marker ",
             "'<!-- sequence:state json cornball.sequence.v1 -->'.",
             call. = FALSE)
    }
    if (n_open > 1L) {
        stop("sequence.md has ", n_open,
             " opening markers; exactly one is allowed.", call. = FALSE)
    }
    if (n_close == 0L) {
        stop("sequence.md is missing the closing marker '<!-- /sequence:state -->'.",
             call. = FALSE)
    }
    if (n_close > 1L) {
        stop("sequence.md has ", n_close,
             " closing markers; exactly one is allowed.", call. = FALSE)
    }
    open_start  <- opens[1L]
    open_len    <- attr(opens, "match.length")[1L]
    open_end    <- open_start + open_len - 1L
    close_start <- closes[1L]
    close_len   <- attr(closes, "match.length")[1L]
    close_end   <- close_start + close_len - 1L
    if (close_start <= open_end) {
        stop("sequence.md closing marker appears before the opening marker.",
             call. = FALSE)
    }

    # Parse encoding + schema from the opening marker
    open_text <- substr(txt, open_start, open_end)
    m <- regmatches(open_text, regexec(.OPEN_RE, open_text, perl = TRUE))[[1]]
    if (length(m) < 3L) {
        stop("sequence.md opening marker is malformed: '", open_text, "'",
             call. = FALSE)
    }
    encoding <- m[2L]
    schema   <- m[3L]
    if (!identical(encoding, .SUPPORTED_ENCODING)) {
        stop("sequence.md declares encoding '", encoding,
             "'; only '", .SUPPORTED_ENCODING, "' is supported in v1.",
             call. = FALSE)
    }
    if (!identical(schema, .SUPPORTED_SCHEMA)) {
        stop("sequence.md declares schema '", schema,
             "'; this nle.api supports '", .SUPPORTED_SCHEMA, "'.",
             call. = FALSE)
    }

    body <- substr(txt, open_end + 1L, close_start - 1L)
    list(open_start = open_start, open_end = open_end,
         close_start = close_start, close_end = close_end,
         encoding = encoding, schema = schema,
         body = body)
}

# Internal: strip surrounding ``` ... ``` if the payload was wrapped in a
# fenced code block (Markdown editors often re-fence on save).
.strip_optional_fence <- function(body) {
    body <- trimws(body)
    if (startsWith(body, "```")) {
        # drop first line (``` or ```json) and the trailing ```
        lines <- strsplit(body, "\n", fixed = TRUE)[[1]]
        if (length(lines) >= 2L && grepl("^```", lines[length(lines)])) {
            lines <- lines[-c(1L, length(lines))]
            body <- paste(lines, collapse = "\n")
        }
    }
    body
}

#' Extract the state block payload from a sequence.md
#'
#' Lower-level helper used by \code{\link{read_sequence}}. Errors strictly
#' on marker problems; returns the raw payload string.
#'
#' @param path Path to a sequence.md file.
#' @return A character scalar — the payload between markers (with any
#'   surrounding code fence stripped).
#' @export
extract_sequence_state_md <- function(path) {
    if (!file.exists(path)) {
        stop("extract_sequence_state_md: file not found: ", path, call. = FALSE)
    }
    txt <- paste(readLines(path, warn = FALSE), collapse = "\n")
    blk <- .find_state_block(txt)
    .strip_optional_fence(blk$body)
}

#' Read a sequence from a sequence.md file
#'
#' Parses the single delimited state block, validates schema/version,
#' and returns the resulting \code{nle_sequence}. The surrounding prose
#' is attached as the \code{"prose"} attribute so \code{write_sequence()}
#' can preserve it.
#'
#' Strict parser: errors on missing, duplicated, or malformed markers, on
#' unsupported encoding, or on schema mismatch.
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
    payload <- .strip_optional_fence(blk$body)
    seq <- sequence_from_json(payload)
    # Attach the prose envelope (everything outside the block) for round-trip
    pre  <- substr(txt, 1L, blk$open_end)
    post <- substr(txt, blk$close_start, nchar(txt))
    attr(seq, "prose") <- list(pre = pre, post = post,
                               encoding = blk$encoding, schema = blk$schema,
                               source_path = path)
    seq
}

#' Write a sequence back to a sequence.md file
#'
#' Preserves all prose outside the state block, surgically replaces only
#' the JSON payload between the markers. If \code{path} doesn't exist (or
#' the in-memory sequence has no attached prose), writes a minimal new
#' file with a stub header and the state block.
#'
#' @param seq An \code{nle_sequence}.
#' @param path Path to write to. Defaults to the path \code{seq} was read
#'   from, if any.
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

    encoding <- prose$encoding %||% .SUPPORTED_ENCODING
    schema   <- prose$schema   %||% .SUPPORTED_SCHEMA
    payload  <- sequence_to_json(seq, pretty = TRUE)

    if (!is.null(prose$pre) && !is.null(prose$post)) {
        # In-place surgery on the existing file
        new_block <- paste0("\n", payload, "\n")
        new_txt   <- paste0(prose$pre, new_block, prose$post)
    } else if (file.exists(path)) {
        # Path exists but we're reading the prose fresh
        existing_txt <- paste(readLines(path, warn = FALSE), collapse = "\n")
        blk <- tryCatch(.find_state_block(existing_txt),
                        error = function(e) NULL)
        if (!is.null(blk)) {
            pre  <- substr(existing_txt, 1L, blk$open_end)
            post <- substr(existing_txt, blk$close_start, nchar(existing_txt))
            new_txt <- paste0(pre, "\n", payload, "\n", post)
        } else {
            # No prior block in this file: append a new one
            new_txt <- paste0(existing_txt,
                              if (nchar(existing_txt) > 0L) "\n\n" else "",
                              sprintf(.OPEN_FMT, encoding, schema), "\n",
                              payload, "\n",
                              .CLOSE_TAG, "\n")
        }
    } else {
        # Brand new file: minimal header
        new_txt <- paste0(
            sprintf("# sequence: %s\n\n", seq$id),
            "_Human prose goes above this point._\n\n",
            sprintf(.OPEN_FMT, encoding, schema), "\n",
            payload, "\n",
            .CLOSE_TAG, "\n")
    }

    writeLines(new_txt, path)
    invisible(path)
}

#' Replace only the state block in a sequence.md (without parsing the JSON)
#'
#' Lower-level helper for tools that want to swap the payload without
#' going through the S3 model. Errors via the strict parser if the file
#' has no valid state block to replace.
#'
#' @param path Path to a sequence.md.
#' @param seq An \code{nle_sequence}.
#' @return The path, invisibly.
#' @export
replace_sequence_state_md <- function(path, seq) {
    write_sequence(seq, path)
}

#' Validate a sequence's structural invariants
#'
#' Checks:
#' \itemize{
#'   \item schema string is the expected version
#'   \item every clip's \code{track} refers to an existing track id
#'   \item every clip has \code{tl_out > tl_in}
#'   \item every clip has \code{source_out >= source_in}
#'   \item no two clips share the same id
#' }
#'
#' @param seq An \code{nle_sequence}.
#' @return TRUE invisibly on success; stops with a clear error otherwise.
#' @export
validate_sequence <- function(seq) {
    if (!is_sequence(seq)) {
        stop("validate_sequence: seq must be an nle_sequence", call. = FALSE)
    }
    if (!identical(seq$schema, .SUPPORTED_SCHEMA)) {
        stop("validate_sequence: schema is '", seq$schema,
             "'; expected '", .SUPPORTED_SCHEMA, "'.", call. = FALSE)
    }
    if (anyDuplicated(seq$tracks$id)) {
        stop("validate_sequence: duplicate track ids", call. = FALSE)
    }
    if (anyDuplicated(seq$clips$id)) {
        stop("validate_sequence: duplicate clip ids", call. = FALSE)
    }
    if (nrow(seq$clips) > 0L) {
        bad_track <- !(seq$clips$track %in% seq$tracks$id)
        if (any(bad_track)) {
            stop("validate_sequence: clip(s) reference non-existent track(s): ",
                 paste(unique(seq$clips$track[bad_track]), collapse = ", "),
                 call. = FALSE)
        }
        bad_dur <- seq$clips$tl_out <= seq$clips$tl_in
        if (any(bad_dur)) {
            stop("validate_sequence: clip(s) have tl_out <= tl_in: ",
                 paste(seq$clips$id[bad_dur], collapse = ", "), call. = FALSE)
        }
        bad_src <- seq$clips$source_out < seq$clips$source_in
        if (any(bad_src)) {
            stop("validate_sequence: clip(s) have source_out < source_in: ",
                 paste(seq$clips$id[bad_src], collapse = ", "), call. = FALSE)
        }
    }
    invisible(TRUE)
}
