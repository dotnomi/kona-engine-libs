# CMake Script to Build bgfx
cmake_minimum_required(VERSION 3.15)

if(NOT DEFINED TARGET_PLATFORM)
    message(FATAL_ERROR "TARGET_PLATFORM not defined")
endif()

if(NOT DEFINED PREFIX)
    set(PREFIX "${CMAKE_CURRENT_SOURCE_DIR}/build-out/${TARGET_PLATFORM}")
endif()

set(EXT_DIR "${CMAKE_CURRENT_SOURCE_DIR}/external")
file(MAKE_DIRECTORY ${EXT_DIR})

set(SRC_DIR "${EXT_DIR}/bgfx")
set(BUILD_DIR "${EXT_DIR}/bgfx-build")

# Clone bgfx.cmake wrapper repository
if(NOT EXISTS "${SRC_DIR}")
    message(STATUS "Cloning bgfx.cmake...")
    execute_process(
        COMMAND git clone --depth 1 https://github.com/bkaradzic/bgfx.cmake.git ${SRC_DIR}
        RESULT_VARIABLE GIT_RESULT
    )
    if(NOT GIT_RESULT EQUAL 0)
        message(FATAL_ERROR "Failed to clone bgfx.cmake")
    endif()
    if(TARGET_PLATFORM STREQUAL "webgl")
        message(STATUS "Patching bx.cmake to remove -msse4.2 for WebGL...")
        file(READ "${SRC_DIR}/cmake/bx/bx.cmake" BX_CMAKE_CONTENT)
        string(REPLACE "-msse4.2" "" BX_CMAKE_CONTENT "${BX_CMAKE_CONTENT}")
        file(WRITE "${SRC_DIR}/cmake/bx/bx.cmake" "${BX_CMAKE_CONTENT}")
    endif()
    message(STATUS "Initializing submodules for bgfx.cmake...")
    execute_process(
        COMMAND git submodule update --init --recursive
        WORKING_DIRECTORY "${SRC_DIR}"
        RESULT_VARIABLE SUB_RESULT
    )
    if(NOT SUB_RESULT EQUAL 0)
        message(FATAL_ERROR "Failed to update submodules for bgfx.cmake")
    endif()
endif()

# Setup CMake args
set(CMAKE_ARGS
    "-DCMAKE_INSTALL_PREFIX=${PREFIX}"
    "-DCMAKE_BUILD_TYPE=Release"
    "-DBGFX_BUILD_EXAMPLES=OFF"
    "-DBGFX_BUILD_TESTS=OFF"
    "-DBGFX_BUILD_TOOLS=OFF"
    "-DBGFX_INSTALL=ON"
    "-DBGFX_CUSTOM_TARGETS=OFF"
)

if(TARGET_PLATFORM STREQUAL "windows-x64")
    list(APPEND CMAKE_ARGS "-G" "MinGW Makefiles" "-DCMAKE_C_COMPILER=gcc" "-DCMAKE_CXX_COMPILER=g++")
elseif(TARGET_PLATFORM STREQUAL "windows-arm64")
    list(APPEND CMAKE_ARGS "-G" "MinGW Makefiles" "-DCMAKE_C_COMPILER=gcc" "-DCMAKE_CXX_COMPILER=g++")
elseif(TARGET_PLATFORM STREQUAL "macos-x64")
    list(APPEND CMAKE_ARGS "-DCMAKE_OSX_ARCHITECTURES=x86_64")
elseif(TARGET_PLATFORM STREQUAL "macos-arm64")
    list(APPEND CMAKE_ARGS "-DCMAKE_OSX_ARCHITECTURES=arm64")
elseif(TARGET_PLATFORM STREQUAL "linux-x64")
    list(APPEND CMAKE_ARGS "-DCMAKE_POSITION_INDEPENDENT_CODE=ON")
elseif(TARGET_PLATFORM STREQUAL "linux-arm64")
    list(APPEND CMAKE_ARGS
        "-DCMAKE_POSITION_INDEPENDENT_CODE=ON"
        "-DCMAKE_SYSTEM_NAME=Linux"
        "-DCMAKE_SYSTEM_PROCESSOR=aarch64"
        "-DCMAKE_C_COMPILER=aarch64-linux-gnu-gcc"
        "-DCMAKE_CXX_COMPILER=aarch64-linux-gnu-g++"
    )
elseif(TARGET_PLATFORM STREQUAL "webgl")
    set(ENV{CFLAGS} "-msimd128")
    set(ENV{CXXFLAGS} "-msimd128")
    set(ENV{LDFLAGS} "")
    list(APPEND CMAKE_ARGS
        "-DCMAKE_TOOLCHAIN_FILE=$ENV{EMSDK}/upstream/emscripten/cmake/Modules/Platform/Emscripten.cmake"
        "-DCMAKE_C_FLAGS=-msimd128 -pthread -DBX_CONFIG_SUPPORTS_THREADING=0 -D__EMSCRIPTEN_MAJOR__=__EMSCRIPTEN_major__ -D__EMSCRIPTEN_MINOR__=__EMSCRIPTEN_minor__ -D__EMSCRIPTEN_TINY__=__EMSCRIPTEN_tiny__"
        "-DCMAKE_CXX_FLAGS=-msimd128 -pthread -DBX_CONFIG_SUPPORTS_THREADING=0 -D__EMSCRIPTEN_MAJOR__=__EMSCRIPTEN_major__ -D__EMSCRIPTEN_MINOR__=__EMSCRIPTEN_minor__ -D__EMSCRIPTEN_TINY__=__EMSCRIPTEN_tiny__"
        "-DCMAKE_EXE_LINKER_FLAGS=-pthread"
        "-DBGFX_CONFIG_MULTITHREADED=OFF"
    )
elseif(TARGET_PLATFORM STREQUAL "android")
    list(APPEND CMAKE_ARGS
        "-DCMAKE_TOOLCHAIN_FILE=$ENV{ANDROID_NDK_HOME}/build/cmake/android.toolchain.cmake"
        "-DANDROID_ABI=arm64-v8a"
        "-DANDROID_PLATFORM=24"
        "-DANDROID_NATIVE_API_LEVEL=24"
    )
elseif(TARGET_PLATFORM STREQUAL "ios")
    list(APPEND CMAKE_ARGS
        "-DCMAKE_SYSTEM_NAME=iOS"
        "-DCMAKE_OSX_ARCHITECTURES=arm64"
        "-DCMAKE_OSX_SYSROOT=iphoneos"
    )
elseif(TARGET_PLATFORM STREQUAL "ios-simulator-arm64")
    list(APPEND CMAKE_ARGS
        "-DCMAKE_SYSTEM_NAME=iOS"
        "-DCMAKE_OSX_ARCHITECTURES=arm64"
        "-DCMAKE_OSX_SYSROOT=iphonesimulator"
    )
elseif(TARGET_PLATFORM STREQUAL "ios-x64")
    list(APPEND CMAKE_ARGS
        "-DCMAKE_SYSTEM_NAME=iOS"
        "-DCMAKE_OSX_ARCHITECTURES=x86_64"
        "-DCMAKE_OSX_SYSROOT=iphonesimulator"
    )
endif()

# Configure
message(STATUS "Configuring bgfx...")
execute_process(
    COMMAND ${CMAKE_COMMAND} -S ${SRC_DIR} -B ${BUILD_DIR} ${CMAKE_ARGS}
    RESULT_VARIABLE CONF_RESULT
)
if(NOT CONF_RESULT EQUAL 0)
    message(FATAL_ERROR "Configuration failed for bgfx")
endif()

# Build
message(STATUS "Building bgfx...")
execute_process(
    COMMAND ${CMAKE_COMMAND} --build ${BUILD_DIR} --config Release
    RESULT_VARIABLE BUILD_RESULT
)
if(NOT BUILD_RESULT EQUAL 0)
    message(FATAL_ERROR "Build failed for bgfx")
endif()

# Install
message(STATUS "Installing bgfx...")
execute_process(
    COMMAND ${CMAKE_COMMAND} --install ${BUILD_DIR} --config Release
    RESULT_VARIABLE INST_RESULT
)
if(NOT INST_RESULT EQUAL 0)
    message(FATAL_ERROR "Install failed for bgfx")
endif()

message(STATUS "bgfx successfully built and installed to ${PREFIX}")
