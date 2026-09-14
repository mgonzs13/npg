#!/bin/bash
#
# Shared helpers for the COLIN build scripts. This file is meant to be
# sourced by run-cmake-* and build-*; it is not run directly.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEPS_PREFIX="${NPG_DEPS_PREFIX:-$HOME/.local/share/npg-deps}"
MULTIARCH="$(dpkg-architecture -qDEB_HOST_MULTIARCH 2>/dev/null || echo x86_64-linux-gnu)"

# True when bison or the Coin-OR development headers are missing.
need_deps() {
    command -v bison >/dev/null 2>&1 || return 0
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

# Populate DEPS_CMAKE_ARGS with the CMake arguments pointing at the
# user-local dependencies, when they are present.
deps_cmake_args() {
    DEPS_CMAKE_ARGS=()
    if [ -d "$DEPS_PREFIX/usr" ]; then
        export PATH="$DEPS_PREFIX/usr/bin:$PATH"
        export BISON_PKGDATADIR="$DEPS_PREFIX/usr/share/bison"
        DEPS_CMAKE_ARGS+=("-DCMAKE_PREFIX_PATH=$DEPS_PREFIX/usr")
        DEPS_CMAKE_ARGS+=("-DCMAKE_INCLUDE_PATH=$DEPS_PREFIX/usr/include")
        DEPS_CMAKE_ARGS+=("-DCMAKE_LIBRARY_PATH=$DEPS_PREFIX/usr/lib/$MULTIARCH")
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
