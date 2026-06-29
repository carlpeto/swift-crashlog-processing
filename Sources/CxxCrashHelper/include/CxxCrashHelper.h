#ifndef CXX_CRASH_HELPER_H
#define CXX_CRASH_HELPER_H

#ifdef __cplusplus
extern "C" {
#endif

/// Calls through several C++ functions then crashes.
/// The backtrace will contain mangled C++ symbol names.
void cxx_crash_through_cpp_frames(void);

#ifdef __cplusplus
}
#endif

#endif
