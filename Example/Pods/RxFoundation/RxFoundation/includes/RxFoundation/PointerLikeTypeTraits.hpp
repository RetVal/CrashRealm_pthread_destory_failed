//
//  PointerLikeTypeTraits.hpp
//  RxFoundation
//
//  Created by closure on 1/8/17.
//  Copyright © 2017 closure. All rights reserved.
//

#ifndef PointerLikeTypeTraits_h
#define PointerLikeTypeTraits_h

#include <RxFoundation/Math.hpp>
#include <RxFoundation/AlignOf.hpp>

namespace Rx {
    /// A traits type that is used to handle pointer types and things that are just
    /// wrappers for pointers as a uniform entity.
    template <typename T> class PointerLikeTypeTraits {
        // getAsVoidPointer
        // getFromVoidPointer
        // getNumLowBitsAvailable
    };
    
    namespace detail {
        /// A tiny meta function to compute the log2 of a compile time constant.
        template <size_t N>
        struct ConstantLog2
        : std::integral_constant<size_t, ConstantLog2<N / 2>::value + 1> {};
        template <> struct ConstantLog2<1> : std::integral_constant<size_t, 0> {};
    }
    
    // Provide PointerLikeTypeTraits for non-cvr pointers.
    template <typename T> struct PointerLikeTypeTraits<T *> {
        static inline void *getAsVoidPointer(T *P) { return P; }
        static inline T *getFromVoidPointer(void *P) { return static_cast<T *>(P); }
        
        enum {
            NumLowBitsAvailable = detail::ConstantLog2<AlignOf<T>::Alignment>::value
        };
    };
    
    template <> struct PointerLikeTypeTraits<void *> {
        static inline void *getAsVoidPointer(void *P) { return P; }
        static inline void *getFromVoidPointer(void *P) { return P; }
        
        /// Note, we assume here that void* is related to raw malloc'ed memory and
        /// that malloc returns objects at least 4-byte aligned. However, this may be
        /// wrong, or pointers may be from something other than malloc. In this case,
        /// you should specify a real typed pointer or avoid this template.
        ///
        /// All clients should use assertions to do a run-time check to ensure that
        /// this is actually true.
        enum { NumLowBitsAvailable = 2 };
    };
    
    // Provide PointerLikeTypeTraits for const pointers.
    template <typename T> class PointerLikeTypeTraits<const T *> {
        typedef PointerLikeTypeTraits<T *> NonConst;
        
    public:
        static inline const void *getAsVoidPointer(const T *P) {
            return NonConst::getAsVoidPointer(const_cast<T *>(P));
        }
        static inline const T *getFromVoidPointer(const void *P) {
            return NonConst::getFromVoidPointer(const_cast<void *>(P));
        }
        enum { NumLowBitsAvailable = NonConst::NumLowBitsAvailable };
    };
    
    // Provide PointerLikeTypeTraits for uintptr_t.
    template <> class PointerLikeTypeTraits<uintptr_t> {
    public:
        static inline void *getAsVoidPointer(uintptr_t P) {
            return reinterpret_cast<void *>(P);
        }
        static inline uintptr_t getFromVoidPointer(void *P) {
            return reinterpret_cast<uintptr_t>(P);
        }
        // No bits are available!
        enum { NumLowBitsAvailable = 0 };
    };
}

#endif /* PointerLikeTypeTraits_h */
