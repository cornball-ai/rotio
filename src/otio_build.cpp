// Gap-model bridge between nle.api's clip table and OTIO's sequential tracks.
//
// OTIO Tracks are ordered, contiguous lists of items; a clip has no absolute
// position, only an order, and spaces are explicit Gap children. nle.api's
// verbs think in absolute timeline frames (tl_in/tl_out). These two functions
// translate:
//
//   otio_timeline_clips_df()  materialize a timeline -> a clip table, computing
//                             each clip's tl_in/tl_out from preceding durations
//                             (gaps are summed into position, never surfaced).
//   otio_build_timeline()     rebuild a fresh timeline from a clip table,
//                             inserting Gaps to honor each clip's tl_in.
//
// Rebuilding from scratch on each edit gives pure-function verb semantics for
// free (every verb returns a new timeline) and keeps the gap bookkeeping in one
// audited place. This is bespoke algorithm, not a uniform binding, so it is
// hand-written rather than generated. All times are in the sequence fps; we
// store fps/canvas in the timeline metadata so they survive serialization.

#include "otio_common.h"
#include <opentimelineio/timeline.h>
#include <opentimelineio/stack.h>
#include <opentimelineio/track.h>
#include <opentimelineio/clip.h>
#include <opentimelineio/gap.h>
#include <opentimelineio/externalReference.h>
#include <opentimelineio/composition.h>
#include <opentimelineio/item.h>
#include <opentimelineio/errorStatus.h>
#include <opentime/timeRange.h>
#include <algorithm>
#include <optional>
#include <vector>

using otio::RationalTime;
using otio::TimeRange;

static const double POS_EPS = 1e-6;

// Read a clip/gap's timeline duration in frames (its own rate).
static double child_duration(otio::Composable* comp) {
    otio::Item* item = dynamic_cast<otio::Item*>(comp);
    if (!item) return 0.0;
    otio::ErrorStatus err;
    RationalTime d = item->duration(&err);
    return d.value();
}

// [[Rcpp::export]]
Rcpp::DataFrame otio_timeline_clips_df(SEXP tl) {
    otio::Timeline* t = unwrap_otio<otio::Timeline>(tl);
    std::vector<std::string> id, track, kind, asset;
    std::vector<double> tl_in, tl_out, source_in, source_out, rate;

    for (auto const& tchild : t->tracks()->children()) {
        otio::Track* tr = dynamic_cast<otio::Track*>((otio::Composable*) tchild);
        if (!tr) continue;
        std::string tname = tr->name(), tkind = tr->kind();
        double cursor = 0.0;
        for (auto const& child : tr->children()) {
            otio::Composable* comp = child;
            double dur = child_duration(comp);
            if (otio::Clip* c = dynamic_cast<otio::Clip*>(comp)) {
                double sv = NA_REAL, sr = NA_REAL;
                if (auto srng = c->source_range()) {
                    sv = srng->start_time().value();
                    sr = srng->start_time().rate();
                }
                std::string url;
                if (auto ext = dynamic_cast<otio::ExternalReference*>(
                        c->media_reference())) {
                    url = ext->target_url();
                }
                id.push_back(c->name());
                track.push_back(tname);
                kind.push_back(tkind);
                asset.push_back(url);
                tl_in.push_back(cursor);
                tl_out.push_back(cursor + dur);
                source_in.push_back(sv);
                source_out.push_back(sv + dur);
                rate.push_back(sr);
            }
            cursor += dur; // gaps advance the cursor but are not surfaced
        }
    }
    return Rcpp::DataFrame::create(
        Rcpp::Named("id") = id,
        Rcpp::Named("track") = track,
        Rcpp::Named("kind") = kind,
        Rcpp::Named("asset") = asset,
        Rcpp::Named("tl_in") = tl_in,
        Rcpp::Named("tl_out") = tl_out,
        Rcpp::Named("source_in") = source_in,
        Rcpp::Named("source_out") = source_out,
        Rcpp::Named("rate") = rate,
        Rcpp::Named("stringsAsFactors") = false);
}

// Rebuild a timeline from a clip table. Tracks are given in order; clips are
// assigned to tracks by id and laid out by tl_in, with Gaps filling the space.
// [[Rcpp::export]]
SEXP otio_build_timeline(std::string name,
                         double fps_num, double fps_den,
                         double canvas_w, double canvas_h,
                         double sample_rate,
                         Rcpp::CharacterVector track_ids,
                         Rcpp::CharacterVector track_kinds,
                         Rcpp::CharacterVector clip_track,
                         Rcpp::CharacterVector clip_id,
                         Rcpp::CharacterVector clip_asset,
                         Rcpp::NumericVector clip_tl_in,
                         Rcpp::NumericVector clip_tl_out,
                         Rcpp::NumericVector clip_src_in,
                         Rcpp::NumericVector clip_rate) {
    otio::Timeline* timeline = new otio::Timeline(name);
    otio::AnyDictionary& meta = timeline->metadata();
    meta["nle_fps_num"] = fps_num;
    meta["nle_fps_den"] = fps_den;
    meta["nle_canvas_w"] = canvas_w;
    meta["nle_canvas_h"] = canvas_h;
    meta["nle_sample_rate"] = sample_rate;
    SEXP wrapped = wrap_otio<otio::Timeline>(timeline);

    const int n_clips = clip_id.size();
    for (int t = 0; t < track_ids.size(); ++t) {
        std::string tid = Rcpp::as<std::string>(track_ids[t]);
        otio::Track* tr = new otio::Track(
            tid, std::nullopt, Rcpp::as<std::string>(track_kinds[t]));

        // Clip indices on this track, sorted by tl_in.
        std::vector<int> idx;
        for (int i = 0; i < n_clips; ++i) {
            if (Rcpp::as<std::string>(clip_track[i]) == tid) idx.push_back(i);
        }
        std::sort(idx.begin(), idx.end(), [&](int a, int b) {
            return clip_tl_in[a] < clip_tl_in[b];
        });

        double cursor = 0.0;
        for (int i : idx) {
            double tin = clip_tl_in[i], tout = clip_tl_out[i];
            double r = clip_rate[i], sin = clip_src_in[i];
            if (tout <= tin) {
                Rcpp::stop("clip '%s': non-positive duration",
                           Rcpp::as<std::string>(clip_id[i]));
            }
            if (tin < cursor - POS_EPS) {
                Rcpp::stop("clip '%s' overlaps an earlier clip on track '%s'",
                           Rcpp::as<std::string>(clip_id[i]), tid);
            }
            if (tin > cursor + POS_EPS) {
                otio::ErrorStatus gerr;
                tr->append_child(
                    new otio::Gap(RationalTime(tin - cursor, r)), &gerr);
                if (otio::is_error(gerr)) Rcpp::stop("gap: %s", gerr.details);
            }
            otio::ExternalReference* ref =
                new otio::ExternalReference(Rcpp::as<std::string>(clip_asset[i]));
            TimeRange range(RationalTime(sin, r), RationalTime(tout - tin, r));
            otio::Clip* clip =
                new otio::Clip(Rcpp::as<std::string>(clip_id[i]), ref, range);
            otio::ErrorStatus cerr;
            tr->append_child(clip, &cerr);
            if (otio::is_error(cerr)) Rcpp::stop("clip: %s", cerr.details);
            cursor = tout;
        }

        otio::ErrorStatus terr;
        timeline->tracks()->append_child(tr, &terr);
        if (otio::is_error(terr)) Rcpp::stop("track: %s", terr.details);
    }
    return wrapped;
}

// Read the sequence config (fps/canvas/sample_rate) back from metadata.
// [[Rcpp::export]]
Rcpp::NumericVector otio_timeline_config(SEXP tl) {
    otio::Timeline* t = unwrap_otio<otio::Timeline>(tl);
    otio::AnyDictionary const& meta = t->metadata();
    auto rd = [&](const char* key, double dflt) {
        double v = dflt;
        meta.get_if_set<double>(key, &v);
        return v;
    };
    return Rcpp::NumericVector::create(
        Rcpp::Named("fps_num") = rd("nle_fps_num", 30),
        Rcpp::Named("fps_den") = rd("nle_fps_den", 1),
        Rcpp::Named("canvas_w") = rd("nle_canvas_w", 1080),
        Rcpp::Named("canvas_h") = rd("nle_canvas_h", 1080),
        Rcpp::Named("sample_rate") = rd("nle_sample_rate", 48000));
}
