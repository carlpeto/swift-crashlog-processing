#include "CxxCrashHelper.h"
#include <cstdio>
#include <cstdlib>

namespace CrashTest {

class Widget {
public:
    int value;

    Widget(int v) : value(v) {}

    __attribute__((noinline))
    void process(int x) {
        fprintf(stderr, "Widget::process(%d) with value=%d\n", x, value);
        // Crash: null pointer dereference
        volatile int *p = nullptr;
        *p = x + value;
    }
};

template<typename T>
class Container {
    T item;
public:
    Container(T val) : item(val) {}

    __attribute__((noinline))
    void run() {
        fprintf(stderr, "Container<T>::run()\n");
        item.process(42);
    }
};

namespace Internal {

__attribute__((noinline))
void trigger_crash(int seed) {
    fprintf(stderr, "Internal::trigger_crash(%d)\n", seed);
    Widget w(seed);
    Container<Widget> c(w);
    c.run();
}

} // namespace Internal

__attribute__((noinline))
int prepare_and_crash(const char *label, int count) {
    fprintf(stderr, "prepare_and_crash(\"%s\", %d)\n", label, count);
    Internal::trigger_crash(count * 7);
    return 0;
}

} // namespace CrashTest

extern "C" void cxx_crash_through_cpp_frames(void) {
    CrashTest::prepare_and_crash("test-crash", 3);
}
