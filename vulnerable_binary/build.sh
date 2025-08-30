#!/usr/bin/env sh

# Verify Fortify support level
# clang++ -O2 -g -D_FORTIFY_SOURCE=3 -o test_fortify_support test_fortify_support.cpp
# chmod +x test_fortify_support
# ./test_fortify_support
# echo ""
cc="clang++-16"
${cc} -O2 -g -fuse-ld=gold -fsanitize=address -fno-omit-frame-pointer -fno-sanitize-trap=all -o toy_service_asan_trap toy_service.cpp
${cc} -O2 -g -fuse-ld=gold -fsanitize=address -fno-omit-frame-pointer -fno-sanitize-trap=all -fsanitize-recover=all -o toy_service_asan_recover toy_service.cpp
${cc} -O2 -g -fuse-ld=gold -fsanitize=undefined -fno-omit-frame-pointer -fno-sanitize-trap=all  -o toy_service_ubsan_trap toy_service.cpp
${cc} -O2 -g -fuse-ld=gold -fsanitize=undefined -fno-omit-frame-pointer -fno-sanitize-trap=all -fsanitize-recover=all -o toy_service_ubsan_recover toy_service.cpp
# The following does not work on macOS, as it does not support the minimal runtime
${cc} -O2 -g -fuse-ld=gold -fsanitize=undefined -fsanitize-minimal-runtime -fno-sanitize-trap=all -o toy_service_ubsan_minimal_runtime_trap toy_service.cpp
# The following does not work on macOS, as it does not support the minimal runtime
${cc} -O2 -g -fuse-ld=gold -fsanitize=undefined -fsanitize-minimal-runtime -fno-sanitize-trap=all -fsanitize-recover=all -o toy_service_ubsan_minimal_runtime_recover toy_service.cpp
# There is no minimal runtime support for Address Sanitizer, so we do not build a minimal runtime version for it.
# The following does not work on macOS, as it does not support CFI checks
${cc} -O2 -g -fuse-ld=gold -fsanitize=cfi -flto -fno-omit-frame-pointer -fvisibility=hidden -fno-sanitize-trap=all -o toy_service_cfi_trap toy_service.cpp
# The following does not work on macOS, as it does not support CFI checks
${cc} -O2 -g -fuse-ld=gold -fsanitize=cfi -flto -fno-omit-frame-pointer -fvisibility=hidden -fno-sanitize-trap=all -fsanitize-recover=all -o toy_service_cfi_recover toy_service.cpp
${cc} -O2 -g -fuse-ld=gold -D_FORTIFY_SOURCE=0 -o toy_service_unsafe toy_service.cpp
${cc} -O2 -g -fuse-ld=gold -D_FORTIFY_SOURCE=3 -o toy_service_fortified toy_service.cpp
${cc} -O2 -g -fuse-ld=gold -D_FORTIFY_SOURCE=0 -flto -fno-omit-frame-pointer -o toy_service_unsafe_lto toy_service.cpp
${cc} -O2 -g -fuse-ld=gold -D_FORTIFY_SOURCE=3 -flto -fno-omit-frame-pointer -o toy_service_fortified_lto toy_service.cpp
${cc} -O2 -g -fuse-ld=gold -D_FORTIFY_SOURCE=3 -fsanitize=undefined -fsanitize-minimal-runtime -fno-sanitize-trap=all -o toy_service_safe toy_service.cpp

# We cannot recover from a use-after-free
echo "Service with Address Sanitizer aborts on use-after-free"
./toy_service_asan_trap use_after_free
echo

echo "Service with Undefined Behavior Sanitizer traps on integer overflow"
./toy_service_ubsan_trap integer_overflow
echo

echo "Service with Undefined Behavior Sanitizer minimal runtime traps on integer overflow"
./toy_service_ubsan_minimal_runtime_trap integer_overflow
echo

echo "Service with Undefined Behavior Sanitizer recovers on integer overflow"
# Note that this will not abort, but will print a warning messsage and
# return the overflowed value.
./toy_service_ubsan_recover integer_overflow
echo

echo "Service with CFI Sanitizer traps a Bad Cast"
./toy_service_cfi_trap bad_cast
echo

# I don't think this actually recovers, but it traps
echo "Service with CFI Sanitizer recovers on a Bad Cast"
./toy_service_cfi_recover bad_cast
echo

echo "strcpy out of bounds with Address Sanitizer traps"
./toy_service_asan_trap strcpy_out_of_bounds
echo

echo "strcpy out of bounds on fortified build traps"
./toy_service_fortified strcpy_out_of_bounds
echo

echo "strcpy out of bounds on un-fortified does not trap"
echo "It may execute successfully or crash, depending on the system"
echo "It's worse if it doesn't crash because it may corrupt memory"
./toy_service_unsafe strcpy_out_of_bounds
echo

#
# This is the version of the vulnerable library we will actually use with the service.
#
${cc} -O2 \
        -g \
        -fsanitize=cfi \
        -flto \
        -fno-omit-frame-pointer \
        -fvisibility=hidden \
        -fno-sanitize-trap=all \
        -D_FORTIFY_SOURCE=3 \
        -o vulnerable_binary toy_service.cpp

echo "Built vulnerable binary for testing"

# Cross-compile for Raspberry Pi
${cc} -flto -fno-omit-frame-pointer \
        -fvisibility=hidden \
        -fsanitize=cfi \
        -flto \
        -D_FORTIFY_SOURCE=3 \
        -target arm-linux-gnueabihf \
        -I/usr/arm-linux-gnueabihf/include \
        -I/usr/arm-linux-gnueabihf/include/c++/10 \
        -I/usr/arm-linux-gnueabihf/include/c++/10/arm-linux-gnueabihf \
        -L/usr/arm-linux-gnueabihf/lib \
        -Wl,-dynamic-linker,/lib/ld-linux-armhf.so.3 \
        -fuse-ld=gold \
        -fPIC \
        -o toy_service_rpi toy_service.cpp

file toy_service_rpi
echo "Built vulnerable binary for Raspberry Pi"