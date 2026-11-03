cmake_minimum_required(VERSION 3.20)
project(MrNutzRecomp C CXX)

set(CMAKE_C_STANDARD 11)

# Release pin for lobby matching. Release builds stamp the VERSION file so two
# peers can prove they are the same build; everything else stamps "dev".
file(READ "${CMAKE_CURRENT_SOURCE_DIR}/VERSION" _GAME_VER_RAW)
string(STRIP "${_GAME_VER_RAW}" GAME_RELEASE_VERSION)
set(SNESRECOMP_BUILD_VERSION "" CACHE STRING
    "Lobby release pin (empty = Release uses VERSION, else dev)")
if(SNESRECOMP_BUILD_VERSION STREQUAL "")
    get_property(_is_multi GLOBAL PROPERTY GENERATOR_IS_MULTI_CONFIG)
    if(_is_multi)
        set(SNESRECOMP_BUILD_VERSION "$<IF:$<CONFIG:Release>,${GAME_RELEASE_VERSION},dev>")
    elseif(CMAKE_BUILD_TYPE STREQUAL "Release")
        set(SNESRECOMP_BUILD_VERSION "${GAME_RELEASE_VERSION}")
    else()
        set(SNESRECOMP_BUILD_VERSION "dev")
    endif()
endif()

set(SNESRECOMP_ROOT "${CMAKE_SOURCE_DIR}/snesrecomp" CACHE PATH
    "Path to the snesrecomp checkout used by this game")
if(NOT EXISTS "${SNESRECOMP_ROOT}/runner/runner.cmake")
    message(FATAL_ERROR
        "snesrecomp submodule missing at ${SNESRECOMP_ROOT}.\n"
        "Run: git submodule update --init --recursive")
endif()
# Mod packages are part of every project, not an option (see the framework's
# docs/MOD_PACKAGES.md). Must precede the include.
set(SNESRECOMP_ENABLE_MODS ON CACHE BOOL
    "Mod package loader + trusted plugins (required for every title)" FORCE)
include(${SNESRECOMP_ROOT}/runner/runner.cmake)

add_executable(MrNutzRecomp
    ${SNESRECOMP_RUNNER_SOURCES}
    src/main.c
    src/host_contract.c
    src/game_rtl.c
    src/gen_stubs.c
)

# rom_identity.txt is the one place the ROM digests live.
snesrecomp_rom_identity(MrNutzRecomp ${CMAKE_SOURCE_DIR}/rom_identity.txt)

# Generated recompiler output (src/gen), derived from a copyrighted ROM and
# never committed. Regenerate with tools/regen.sh.
snesrecomp_target_generated_code(MrNutzRecomp ${CMAKE_SOURCE_DIR}/src/gen)

snesrecomp_target_mod_catalog(MrNutzRecomp ${CMAKE_SOURCE_DIR}/mods/preloaded)

target_include_directories(MrNutzRecomp PRIVATE
    ${SNESRECOMP_RUNNER_INCLUDE_DIRS}
    # common_rtl.c includes "config.h": the desktop contract the host supplies.
    ${SNESRECOMP_ROOT}/runner/src/desktop
    ${CMAKE_SOURCE_DIR}/src
    ${CMAKE_SOURCE_DIR}/recomp
)
target_link_libraries(MrNutzRecomp PRIVATE ${SNESRECOMP_RUNNER_LIBRARIES})
target_compile_definitions(MrNutzRecomp PRIVATE
    SNES_GAME_VERSION="${SNESRECOMP_BUILD_VERSION}"
)
snesrecomp_target_sdl(MrNutzRecomp)

snesrecomp_target_desktop_host(MrNutzRecomp)
snesrecomp_target_rom_cache(MrNutzRecomp)

# Shared Dear ImGui pre-boot launcher (ROM picker, verification, display /
# audio / input settings). Self-contained: it brings its own ImGui, GL link and
# staged assets, and defines RECOMP_LAUNCHER so the framework's host compiles
# its GUI path.
set(RECOMP_UI_ROOT "${CMAKE_SOURCE_DIR}/recomp-ui" CACHE PATH
    "Root directory of the recomp-ui launcher repo" FORCE)
if(NOT EXISTS "${RECOMP_UI_ROOT}/recomp_ui.cmake")
    message(FATAL_ERROR
        "recomp-ui missing at ${RECOMP_UI_ROOT}.\n"
        "Run: git submodule update --init --recursive recomp-ui")
endif()
include(${RECOMP_UI_ROOT}/recomp_ui.cmake)
# BOXART stages launcher_assets/img/boxart.tga beside the exe; the launcher
# shows assets/img/boxart.tga by default. EXISTS-guarded in recomp_ui.cmake,
# so this configures cleanly before any art is fetched.
recomp_target_launcher_ui(MrNutzRecomp CONSOLE snes
    BOXART "${CMAKE_SOURCE_DIR}/launcher_assets/img/boxart.tga")

# Generate & rebuild from inside the launcher: pick ROM -> recompile locally
# -> cmake --build -> relaunch. The implementation is the framework's; this
# project contributes no configuration. recomp-ui/src is on the include path
# because the host speaks RecompLauncherCGameInfo.
target_sources(MrNutzRecomp PRIVATE
    ${SNESRECOMP_ROOT}/host/snesrecomp_codegen_host.c)
target_include_directories(MrNutzRecomp PRIVATE
    ${SNESRECOMP_ROOT}/host
    ${RECOMP_UI_ROOT}/src)
