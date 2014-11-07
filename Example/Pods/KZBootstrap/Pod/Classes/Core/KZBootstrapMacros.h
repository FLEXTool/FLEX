#define KZB_HAS_POD(podname) defined(COCOAPODS_POD_AVAILABLE_ ## podname)

//! remember that params are indexed from 1
#define KZB_REQUIRE_ALL_PARAMS __attribute((nonnull))
#define KZB_REQUIRE_PARAMS(...) __attribute((nonnull(__VA_ARGS__)))
#define KZB_REQUIRE_SUPER NS_REQUIRES_SUPER

#define KZB_KEYPATH_T(target, keypath) ({if(NO){target##.##keypath;}@#keypath})
#define KZB_KEYPATH(keypath) ({if(NO){self.keypath;}@#keypath;})
