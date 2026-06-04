// Shared OTIO <-> Rcpp lifetime helpers, used by the hand-written shim
// (otio_objects.cpp) and the generated getters (otio_gen.cpp).
//
// See otio_objects.cpp for the lifetime contract: OTIO objects are held through
// a heap SerializableObject::Retainer<T> inside an Rcpp::XPtr; the XPtr
// finalizer deletes the Retainer, releasing one managed reference. Never delete
// an OTIO object directly.

#ifndef NLE_API_OTIO_COMMON_H
#define NLE_API_OTIO_COMMON_H

#include <Rcpp.h>
#include <opentimelineio/version.h>
#include <opentimelineio/serializableObject.h>

namespace otio = OTIO_NS;

template <typename T>
using Ret = otio::SerializableObject::Retainer<T>;

template <typename T>
inline SEXP wrap_otio(T* obj) {
    return Rcpp::XPtr<Ret<T>>(new Ret<T>(obj), true);
}

template <typename T>
inline T* unwrap_otio(SEXP p) {
    Rcpp::XPtr<Ret<T>> xp(p);
    Ret<T>& r = *xp;
    T* obj = r; // Retainer::operator T*()
    if (!obj) Rcpp::stop("null OTIO object pointer");
    return obj;
}

#endif // NLE_API_OTIO_COMMON_H
