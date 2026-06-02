# JSON serialization: nle_sequence <-> cornball.sequence.v1 JSON.
#
# In-memory: integer frame counts at the sequence fps.
# On the wire: every time field expands to a rational {num, den}, where den
# is the sequence's timebase fps (i.e. frame counts are already rational).

# Internal: turn an integer frame count into a rational time list at the
# sequence's fps.
.frames_to_rational <- function(frames, seq) {
    list(num = as.integer(frames),
         den = as.integer(seq$timebase$fps_num /
                          seq$timebase$fps_den * 1L))
}

# Internal: convert a rational {num, den} back to integer frames at the
# sequence's fps. If den matches the sequence's fps exactly, return num
# as-is. Otherwise rescale.
.rational_to_frames <- function(rt, seq) {
    fps <- seq_fps(seq)
    if (rt$den == as.integer(round(fps))) {
        return(as.integer(rt$num))
    }
    as.integer(round(rt$num * fps / rt$den))
}

# Internal: clip-row -> JSON-shaped list
.clip_to_list <- function(cl, seq) {
    out <- list(
        id        = cl$id,
        track     = cl$track,
        kind      = cl$kind,
        asset     = cl$asset,
        tl_in     = .frames_to_rational(cl$tl_in,     seq),
        tl_out    = .frames_to_rational(cl$tl_out,    seq),
        `in`      = .frames_to_rational(cl$source_in,  seq),
        out       = .frames_to_rational(cl$source_out, seq),
        speed     = cl$speed,
        transform = list(pos_x = cl$pos_x, pos_y = cl$pos_y,
                         scale_x = cl$scale_x, scale_y = cl$scale_y,
                         rotation_deg = cl$rotation_deg),
        crop      = list(left = cl$crop_left, right = cl$crop_right,
                         top = cl$crop_top,  bottom = cl$crop_bottom),
        blend     = cl$blend,
        opacity   = cl$opacity,
        mute      = cl$mute,
        label     = cl$label
    )
    # notes: a list column; pull out the character vector
    if ("notes" %in% names(cl)) {
        n <- cl$notes
        if (is.list(n)) n <- n[[1]]
        if (length(n) > 0L) out$notes <- as.character(n)
    }
    out
}

# Internal: JSON-shaped list -> clip row (for rbind into seq$clips)
.list_to_clip <- function(d, seq) {
    notes_vec <- if (!is.null(d$notes)) as.character(d$notes) else character(0)
    row <- data.frame(
        id    = d$id %||% NA_character_,
        track = d$track %||% NA_character_,
        kind  = d$kind  %||% NA_character_,
        asset = d$asset %||% NA_character_,
        tl_in     = .rational_to_frames(.parse_rational(d$tl_in),  seq),
        tl_out    = .rational_to_frames(.parse_rational(d$tl_out), seq),
        source_in  = .rational_to_frames(.parse_rational(d$`in`),  seq),
        source_out = .rational_to_frames(.parse_rational(d$out),   seq),
        speed = d$speed %||% 1,
        pos_x = d$transform$pos_x %||% 0,
        pos_y = d$transform$pos_y %||% 0,
        scale_x = d$transform$scale_x %||% 1,
        scale_y = d$transform$scale_y %||% 1,
        rotation_deg = d$transform$rotation_deg %||% 0,
        crop_left   = d$crop$left   %||% 0,
        crop_right  = d$crop$right  %||% 0,
        crop_top    = d$crop$top    %||% 0,
        crop_bottom = d$crop$bottom %||% 0,
        blend   = d$blend   %||% "normal",
        opacity = d$opacity %||% 1,
        mute    = d$mute    %||% FALSE,
        label   = d$label   %||% (d$id %||% NA_character_),
        stringsAsFactors = FALSE
    )
    row$notes <- I(list(notes_vec))
    row
}

#' Serialize an nle_sequence to a cornball.sequence.v1 JSON string
#'
#' @param seq An \code{nle_sequence}.
#' @param pretty Indent the output (default TRUE).
#' @return A JSON string.
#' @export
sequence_to_json <- function(seq, pretty = TRUE) {
    if (!is_sequence(seq)) {
        stop("sequence_to_json: seq must be an nle_sequence", call. = FALSE)
    }
    tracks_l <- if (nrow(seq$tracks) == 0L) list() else
        unname(apply(seq$tracks, 1, as.list))
    clips_l  <- if (nrow(seq$clips) == 0L) list() else
        lapply(seq_len(nrow(seq$clips)),
               function(k) .clip_to_list(seq$clips[k, ], seq))
    out <- list(
        schema = "cornball.sequence.v1",
        id     = seq$id,
        meta   = seq$meta,
        timebase = list(
            fps = list(num = seq$timebase$fps_num,
                       den = seq$timebase$fps_den),
            sample_rate = seq$timebase$sample_rate),
        canvas = list(width  = seq$canvas$width,
                      height = seq$canvas$height),
        tracks = tracks_l,
        clips  = clips_l,
        extensions = seq$extensions %||% list()
    )
    jsonlite::toJSON(out, auto_unbox = TRUE, null = "null",
                     na = "null", pretty = pretty)
}

#' Parse a cornball.sequence.v1 JSON string into an nle_sequence
#'
#' @param json A JSON string.
#' @return An \code{nle_sequence}.
#' @export
sequence_from_json <- function(json) {
    x <- jsonlite::fromJSON(json, simplifyVector = FALSE)
    if (!identical(x$schema, "cornball.sequence.v1")) {
        stop("sequence_from_json: unexpected schema '", x$schema,
             "'; expected 'cornball.sequence.v1'", call. = FALSE)
    }
    fps_obj <- x$timebase$fps
    seq <- new_sequence(
        id = x$id %||% "untitled",
        fps = list(num = fps_obj$num, den = fps_obj$den),
        sample_rate = x$timebase$sample_rate %||% 48000L,
        canvas = c(x$canvas$width %||% 1080L,
                   x$canvas$height %||% 1080L),
        meta = x$meta %||% list()
    )
    seq$extensions <- x$extensions %||% list()
    if (length(x$tracks) > 0L) {
        seq$tracks <- do.call(rbind, lapply(x$tracks, function(t) {
            data.frame(id = t$id, idx = as.integer(t$idx),
                       kind = t$kind, label = t$label,
                       stringsAsFactors = FALSE)
        }))
    }
    if (length(x$clips) > 0L) {
        seq$clips <- do.call(rbind, lapply(x$clips, .list_to_clip, seq = seq))
    }
    seq
}

#' Export the JSON cache sibling of a sequence.md
#'
#' Writes \code{sequence_to_json(seq, pretty = TRUE)} to \code{path}. This
#' file is a cache for non-Markdown consumers; \code{sequence.md} stays
#' authoritative.
#'
#' @param seq An \code{nle_sequence}.
#' @param path Output path (typically \code{"sequence.json"}).
#' @export
export_sequence_json <- function(seq, path) {
    writeLines(sequence_to_json(seq, pretty = TRUE), path)
    invisible(path)
}
