# Pure-function edit verbs: sequence -> sequence.
#
# Ported from kerNLE/R/commands.R with these changes:
#   - times stored as integer frames at the sequence's fps (was: float seconds)
#   - clip transform stored as canonical top-left + Y down (was: centre + Y up)
#   - asset-cache logic (reconcile_demand, asset_id rebinds) removed; that's
#     cornductor's concern, not nle.api's
#   - verb names use `clip`/`track` argument names (was: `clip_id`/`track_id`)
#   - coordinate inputs honour the `coord` argument (or options(nle.coords))

#' Add a track
#'
#' @param seq An \code{nle_sequence}.
#' @param kind One of \code{"video"}, \code{"audio"}, \code{"image"},
#'   \code{"subtitle"}.
#' @param label Track label; defaults to the track id.
#' @param id Explicit track id; auto-generated from \code{kind} if NULL.
#' @param idx Lane index; defaults to below the current bottom track.
#' @return The updated sequence.
#' @examples
#' seq <- new_sequence()
#' seq <- track_add(seq, "video")
#' seq <- track_add(seq, "audio")
#' nrow(seq$tracks)
#' @export
track_add <- function(seq, kind, label = NULL, id = NULL, idx = NULL) {
    kind <- match.arg(kind, c("video", "audio", "image", "subtitle"))
    stem <- substr(kind, 1, 1)
    if (is.null(id)) {
        n <- sum(startsWith(seq$tracks$id, stem)) + 1L
        id <- sprintf("%s%d", stem, n)
    }
    if (id %in% seq$tracks$id) {
        stop(sprintf("track '%s' already exists", id), call. = FALSE)
    }
    if (is.null(idx)) {
        idx <- if (nrow(seq$tracks) == 0L) 1L else max(seq$tracks$idx) + 1L
    }
    row <- data.frame(id = id, idx = as.integer(idx), kind = kind,
                      label = label %||% id, stringsAsFactors = FALSE)
    seq$tracks <- rbind(seq$tracks, row)
    seq
}

#' Add a clip to a track
#'
#' Time inputs accept either integer frames at the sequence fps, numeric
#' seconds, or a \code{\link{rational_time}}.
#'
#' @param seq An \code{nle_sequence}.
#' @param track Target track id (must exist).
#' @param tl_in Timeline in-point.
#' @param tl_out Timeline out-point.
#' @param asset Source path or cornductor asset id.
#' @param kind Clip kind; defaults to the track's kind.
#' @param source_in Source media in-point (default 0).
#' @param source_out Source media out-point (default = source_in + (tl_out - tl_in) * speed).
#' @param speed Playback multiplier (default 1).
#' @param label Clip label; defaults to the clip id.
#' @param id Explicit clip id; auto-generated if NULL.
#' @return The updated sequence.
#' @export
clip_add <- function(seq, track, tl_in, tl_out, asset,
                     kind = NULL, source_in = 0L, source_out = NULL,
                     speed = 1.0, label = NULL, id = NULL) {
    .track_exists(seq, track)
    if (is.null(kind)) {
        kind <- seq$tracks$kind[seq$tracks$id == track][1]
    }
    tl_in_f  <- .to_frames_at_seq(tl_in, seq)
    tl_out_f <- .to_frames_at_seq(tl_out, seq)
    if (tl_out_f <= tl_in_f) {
        stop("clip_add: tl_out must be strictly after tl_in", call. = FALSE)
    }
    src_in_f <- .to_frames_at_seq(source_in, seq)
    if (is.null(source_out)) {
        src_out_f <- src_in_f + as.integer(round((tl_out_f - tl_in_f) * speed))
    } else {
        src_out_f <- .to_frames_at_seq(source_out, seq)
    }
    id <- id %||% .new_clip_id(seq, stem = track)
    row <- data.frame(
        id = id, track = track, kind = kind, asset = asset,
        tl_in = tl_in_f, tl_out = tl_out_f,
        source_in = src_in_f, source_out = src_out_f,
        speed = as.numeric(speed),
        pos_x = 0, pos_y = 0, scale_x = 1, scale_y = 1,
        rotation_deg = 0,
        crop_left = 0, crop_right = 0, crop_top = 0, crop_bottom = 0,
        blend = "normal", opacity = 1, mute = FALSE,
        label = label %||% id,
        stringsAsFactors = FALSE)
    row$notes <- I(list(character(0)))
    seq$clips <- rbind(seq$clips, row)
    seq
}

#' Delete a clip
#' @param seq An \code{nle_sequence}.
#' @param clip Clip id.
#' @export
clip_delete <- function(seq, clip) {
    i <- .clip_idx(seq, clip)
    seq$clips <- seq$clips[-i, , drop = FALSE]
    seq
}

#' Move a clip in time and/or to another track
#' @param seq An \code{nle_sequence}.
#' @param clip Clip id.
#' @param tl_in New timeline in-point; NULL to keep.
#' @param track New track id (must exist); NULL to keep.
#' @export
clip_move <- function(seq, clip, tl_in = NULL, track = NULL) {
    i <- .clip_idx(seq, clip)
    if (!is.null(track)) {
        .track_exists(seq, track)
        seq$clips$track[i] <- track
    }
    if (!is.null(tl_in)) {
        old_in  <- seq$clips$tl_in[i]
        old_out <- seq$clips$tl_out[i]
        new_in  <- .to_frames_at_seq(tl_in, seq)
        seq$clips$tl_in[i]  <- new_in
        seq$clips$tl_out[i] <- new_in + (old_out - old_in)
    }
    seq
}

#' Trim a clip's visible range
#'
#' Moving \code{tl_in} (left edge) shifts the source in-point so the
#' picture stays put. Moving \code{tl_out} (right edge) changes the
#' duration.
#'
#' @param seq An \code{nle_sequence}.
#' @param clip Clip id.
#' @param tl_in New left-edge timeline time; NULL to keep.
#' @param tl_out New right-edge timeline time; NULL to keep.
#' @export
clip_trim <- function(seq, clip, tl_in = NULL, tl_out = NULL) {
    i <- .clip_idx(seq, clip)
    cl <- seq$clips[i, ]
    new_in  <- if (is.null(tl_in)) cl$tl_in else .to_frames_at_seq(tl_in, seq)
    new_out <- if (is.null(tl_out)) cl$tl_out else .to_frames_at_seq(tl_out, seq)
    if (new_out <= new_in) {
        stop("clip_trim: would leave non-positive duration", call. = FALSE)
    }
    # Shift source_in proportional to the left-edge move, accounting for speed
    src_shift <- as.integer(round((new_in - cl$tl_in) * cl$speed))
    new_src_in  <- cl$source_in + src_shift
    new_src_out <- new_src_in +
        as.integer(round((new_out - new_in) * cl$speed))
    if (new_src_in < 0L) {
        stop("clip_trim: would move source in-point before the start of the source",
             call. = FALSE)
    }
    seq$clips$tl_in[i]       <- new_in
    seq$clips$tl_out[i]      <- new_out
    seq$clips$source_in[i]   <- new_src_in
    seq$clips$source_out[i]  <- new_src_out
    seq
}

#' Split a clip at a timeline frame
#' @param seq An \code{nle_sequence}.
#' @param clip Clip id.
#' @param at Timeline time at which to cut (interpreted via \code{.to_frames_at_seq}).
#' @export
clip_split <- function(seq, clip, at) {
    i <- .clip_idx(seq, clip)
    cl <- seq$clips[i, ]
    at_f <- .to_frames_at_seq(at, seq)
    if (at_f <= cl$tl_in || at_f >= cl$tl_out) {
        stop("clip_split: split point must fall strictly inside the clip",
             call. = FALSE)
    }
    left_tl_dur <- at_f - cl$tl_in
    left_src_dur <- as.integer(round(left_tl_dur * cl$speed))
    # Left piece keeps id, shrinks
    seq$clips$tl_out[i]     <- at_f
    seq$clips$source_out[i] <- cl$source_in + left_src_dur
    # Right piece is a clone with new id, starts at the split point
    right <- cl
    right$id        <- .new_clip_id(seq, stem = paste0(cl$id, "_split"))
    right$tl_in     <- at_f
    right$tl_out    <- cl$tl_out
    right$source_in <- cl$source_in + left_src_dur
    right$source_out <- cl$source_out
    seq$clips <- rbind(seq$clips, right)
    seq
}

#' Set a clip's playback speed (time-remap)
#'
#' Keeps the source span fixed and rescales the timeline duration, so
#' speeding a clip up shortens it. Re-anchors at the clip's current
#' \code{tl_in}.
#'
#' @param seq An \code{nle_sequence}.
#' @param clip Clip id.
#' @param speed Playback multiplier (> 0; >1 is faster/shorter).
#' @export
clip_speed <- function(seq, clip, speed) {
    if (speed <= 0) {
        stop("clip_speed: speed must be positive", call. = FALSE)
    }
    i <- .clip_idx(seq, clip)
    cl <- seq$clips[i, ]
    source_span <- cl$source_out - cl$source_in
    new_tl_dur  <- as.integer(round(source_span / speed))
    seq$clips$speed[i]  <- as.numeric(speed)
    seq$clips$tl_out[i] <- cl$tl_in + new_tl_dur
    seq
}

#' Set a clip's compositing transform (position, scale, rotation, opacity)
#'
#' Position is given in the chosen coord system (default \code{"topleft"},
#' configurable via \code{options(nle.coords)}). Storage is always
#' canonical top-left + Y down.
#'
#' @param seq An \code{nle_sequence}.
#' @param clip Clip id.
#' @param pos_x,pos_y Position in the chosen coord system; NULL to keep.
#' @param scale_x,scale_y Per-axis scale; NULL to keep.
#' @param rotation_deg Clockwise degrees, applied around the displayed
#'   bbox centre after positioning; NULL to keep.
#' @param opacity Opacity 0-1; NULL to keep.
#' @param coord One of \code{"topleft"}, \code{"cartesian"},
#'   \code{"center"}. Defaults to \code{options(nle.coords)} then
#'   \code{"topleft"}.
#' @param source_w,source_h Source dimensions in pixels, needed for
#'   \code{coord = "cartesian"} or \code{"center"} when scale is set.
#'   Defaults to the canvas size if not given.
#' @export
clip_transform <- function(seq, clip,
                           pos_x = NULL, pos_y = NULL,
                           scale_x = NULL, scale_y = NULL,
                           rotation_deg = NULL, opacity = NULL,
                           coord = NULL,
                           source_w = NULL, source_h = NULL) {
    i <- .clip_idx(seq, clip)
    if (!is.null(scale_x))      seq$clips$scale_x[i]      <- scale_x
    if (!is.null(scale_y))      seq$clips$scale_y[i]      <- scale_y
    if (!is.null(rotation_deg)) seq$clips$rotation_deg[i] <- rotation_deg
    if (!is.null(opacity))      seq$clips$opacity[i]      <- opacity
    if (!is.null(pos_x) || !is.null(pos_y)) {
        coord <- resolve_coords(coord)
        canvas_w <- seq$canvas$width
        canvas_h <- seq$canvas$height
        src_w <- source_w %||% canvas_w
        src_h <- source_h %||% canvas_h
        sx <- seq$clips$scale_x[i]
        sy <- seq$clips$scale_y[i]
        displayed_w <- src_w * sx
        displayed_h <- src_h * sy
        px <- pos_x %||% seq$clips$pos_x[i]
        py <- pos_y %||% seq$clips$pos_y[i]
        tl <- to_topleft(px, py, coord, canvas_w, canvas_h,
                         displayed_w, displayed_h)
        seq$clips$pos_x[i] <- tl[["pos_x"]]
        seq$clips$pos_y[i] <- tl[["pos_y"]]
    }
    seq
}

#' Set a clip's crop (normalized 0-1 from each edge)
#'
#' @param seq An \code{nle_sequence}.
#' @param clip Clip id.
#' @param left,right,top,bottom Normalized [0, 1] crop from each edge;
#'   NULL to keep.
#' @export
clip_crop <- function(seq, clip,
                      left = NULL, right = NULL, top = NULL, bottom = NULL) {
    i <- .clip_idx(seq, clip)
    if (!is.null(left))   seq$clips$crop_left[i]   <- left
    if (!is.null(right))  seq$clips$crop_right[i]  <- right
    if (!is.null(top))    seq$clips$crop_top[i]    <- top
    if (!is.null(bottom)) seq$clips$crop_bottom[i] <- bottom
    seq
}

#' Set a clip's mute, blend mode, or label
#'
#' @param seq An \code{nle_sequence}.
#' @param clip Clip id.
#' @param mute Logical; NULL to keep.
#' @param blend Blend mode (\code{"normal"}, \code{"alpha_over"}, ...);
#'   NULL to keep.
#' @param label Label string; NULL to keep.
#' @export
clip_set <- function(seq, clip, mute = NULL, blend = NULL, label = NULL) {
    i <- .clip_idx(seq, clip)
    if (!is.null(mute))  seq$clips$mute[i]  <- as.logical(mute)
    if (!is.null(blend)) seq$clips$blend[i] <- blend
    if (!is.null(label)) seq$clips$label[i] <- label
    seq
}
