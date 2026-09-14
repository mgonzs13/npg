#!/bin/bash
#
# Shared helpers for the COLIN build scripts. This file is meant to be
# sourced by run-cmake-* and build-*; it is not run directly.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEPS_PREFIX="${NPG_DEPS_PREFIX:-$HOME/.local/share/npg-deps}"
MULTIARCH="$(dpkg-architecture -qDEB_HOST_MULTIARCH 2>/dev/null || echo x86_64-linux-gnu)"

# True when bison, flex, m4 or the Coin-OR development headers are missing.
need_deps() {
    command -v bison >/dev/null 2>&1 || return 0
    command -v flex >/dev/null 2>&1 || return 0
    command -v m4 >/dev/null 2>&1 || return 0
    [ -f /usr/include/coin/ClpSimplex.hpp ] && return 1
    [ -f /usr/local/include/coin/ClpSimplex.hpp ] && return 1
    [ -f "$DEPS_PREFIX/usr/include/coin/ClpSimplex.hpp" ] && return 1
    return 0
}

# Fetch the dependencies into the user-local prefix when they are missing.
ensure_deps() {
    if [ ! -d "$DEPS_PREFIX/usr" ] && need_deps && [ -x "$SCRIPT_DIR/setup-deps" ]; then
        "$SCRIPT_DIR/setup-deps" || exit 1
    fi
}

# Put the user-local dependency prefix on the environment. This must be
# done both when configuring and when building: flex calls m4 (and bison
# reads its data files) at build time, and the compiler has to find the
# headers from the prefix, such as FlexLexer.h.
deps_env() {
    if [ -d "$DEPS_PREFIX/usr" ]; then
        export PATH="$DEPS_PREFIX/usr/bin:$PATH"
        export BISON_PKGDATADIR="$DEPS_PREFIX/usr/share/bison"
        export M4="$DEPS_PREFIX/usr/bin/m4"
        export CPATH="$DEPS_PREFIX/usr/include${CPATH:+:$CPATH}"
        export LIBRARY_PATH="$DEPS_PREFIX/usr/lib/$MULTIARCH${LIBRARY_PATH:+:$LIBRARY_PATH}"
        export LD_LIBRARY_PATH="$DEPS_PREFIX/usr/lib/$MULTIARCH${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
    fi
}

# Populate DEPS_CMAKE_ARGS with the CMake arguments pointing at the
# user-local dependencies, when they are present.
deps_cmake_args() {
    DEPS_CMAKE_ARGS=()
    deps_env
    if [ -d "$DEPS_PREFIX/usr" ]; then
        DEPS_CMAKE_ARGS+=("-DCMAKE_PREFIX_PATH=$DEPS_PREFIX/usr")
        DEPS_CMAKE_ARGS+=("-DCMAKE_INCLUDE_PATH=$DEPS_PREFIX/usr/include")
        DEPS_CMAKE_ARGS+=("-DCMAKE_LIBRARY_PATH=$DEPS_PREFIX/usr/lib/$MULTIARCH")
        DEPS_CMAKE_ARGS+=("-DCMAKE_EXE_LINKER_FLAGS=${LDFLAGS:-} -Wl,-rpath-link,$DEPS_PREFIX/usr/lib/$MULTIARCH -Wl,--disable-new-dtags -Wl,-rpath,$DEPS_PREFIX/usr/lib/$MULTIARCH")
    fi
}

# configure <build-dir> [additional cmake arguments...]
configure() {
    local build_dir="$1"
    shift
    ensure_deps
    deps_cmake_args
    mkdir -p "$SCRIPT_DIR/$build_dir"
    cd "$SCRIPT_DIR/$build_dir" || exit 1
    cmake "$@" "${DEPS_CMAKE_ARGS[@]}" "$SCRIPT_DIR/src"
}

# require_configured <build-dir>
require_configured() {
    if [ ! -f "$SCRIPT_DIR/$1/Makefile" ]; then
        echo "$1/ is not configured: run the matching run-cmake script first" >&2
        exit 1
    fi
}

# build_target <target> [jobs]
build_target() {
    make -j"${2:-${JOBS:-4}}" "$1"
}

# has_target <build-dir> <target>
has_target() {
    grep -q "^$2:" "$SCRIPT_DIR/$1/colin/Makefile" 2>/dev/null
}
