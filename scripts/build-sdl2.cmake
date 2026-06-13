# CMake Script to Build SDL2
cmake_minimum_required(VERSION 3.15)

set(LIB_NAME sdl2)
set(GIT_URL "https://github.com/libsdl-org/SDL.git")
set(GIT_TAG "release-2.30.12")

if(NOT DEFINED TARGET_PLATFORM)
    message(FATAL_ERROR "TARGET_PLATFORM not defined (e.g., windows-x64, android, etc.)")
endif()

if(NOT DEFINED PREFIX)
    set(PREFIX "${CMAKE_CURRENT_SOURCE_DIR}/build-out/${TARGET_PLATFORM}")
endif()

set(SRC_DIR "${CMAKE_CURRENT_SOURCE_DIR}/external/${LIB_NAME}")
set(BUILD_DIR "${CMAKE_CURRENT_SOURCE_DIR}/external/${LIB_NAME}-build")

# Clone repository
if(NOT EXISTS "${SRC_DIR}")
    message(STATUS "Cloning ${LIB_NAME}...")
    execute_process(
        COMMAND git clone --depth 1 --branch ${GIT_TAG} ${GIT_URL} ${SRC_DIR}
        RESULT_VARIABLE GIT_RESULT
    )
    if(NOT GIT_RESULT EQUAL 0)
        message(FATAL_ERROR "Failed to clone ${LIB_NAME}")
    endif()
endif()

# Configure toolchain and options based on target platform
set(CMAKE_ARGS
    "-DCMAKE_INSTALL_PREFIX=${PREFIX}"
    "-DCMAKE_BUILD_TYPE=Release"
    "-DSDL_STATIC=ON"
    "-DSDL_SHARED=OFF"
    "-DSDL_TEST=OFF"
    "-DSDL_TESTS=OFF"
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
    list(APPEND CMAKE_ARGS
        "-DCMAKE_TOOLCHAIN_FILE=$ENV{EMSDK}/upstream/emscripten/cmake/Modules/Platform/Emscripten.cmake"
    )
elseif(TARGET_PLATFORM STREQUAL "android")
    list(APPEND CMAKE_ARGS
        "-DCMAKE_SYSTEM_NAME=Android"
        "-DCMAKE_SYSTEM_VERSION=26"
        "-DCMAKE_TOOLCHAIN_FILE=$ENV{ANDROID_NDK_HOME}/build/cmake/android.toolchain.cmake"
        "-DANDROID_ABI=arm64-v8a"
        "-DANDROID_PLATFORM=android-26"
        "-DANDROID_NATIVE_API_LEVEL=26"
    )
elseif(TARGET_PLATFORM STREQUAL "ios")
    list(APPEND CMAKE_ARGS
        "-DCMAKE_SYSTEM_NAME=iOS"
        "-DCMAKE_OSX_ARCHITECTURES=arm64"
        "-DCMAKE_OSX_SYSROOT=iphoneos"
        "-DSDL_MMX=OFF"
        "-DSDL_SSE=OFF"
        "-DSDL_SSE2=OFF"
        "-DSDL_SSE3=OFF"
        "-DSDL_SSEMATH=OFF"
    )
elseif(TARGET_PLATFORM STREQUAL "ios-simulator-arm64")
    list(APPEND CMAKE_ARGS
        "-DCMAKE_SYSTEM_NAME=iOS"
        "-DCMAKE_OSX_ARCHITECTURES=arm64"
        "-DCMAKE_OSX_SYSROOT=iphonesimulator"
        "-DSDL_MMX=OFF"
        "-DSDL_SSE=OFF"
        "-DSDL_SSE2=OFF"
        "-DSDL_SSE3=OFF"
        "-DSDL_SSEMATH=OFF"
    )
elseif(TARGET_PLATFORM STREQUAL "ios-x64")
    list(APPEND CMAKE_ARGS
        "-DCMAKE_SYSTEM_NAME=iOS"
        "-DCMAKE_OSX_ARCHITECTURES=x86_64"
        "-DCMAKE_OSX_SYSROOT=iphonesimulator"
    )
endif()

# Configure
message(STATUS "Configuring ${LIB_NAME} for ${TARGET_PLATFORM}...")
execute_process(
    COMMAND ${CMAKE_COMMAND} -S ${SRC_DIR} -B ${BUILD_DIR} ${CMAKE_ARGS}
    RESULT_VARIABLE CONF_RESULT
)
if(NOT CONF_RESULT EQUAL 0)
    message(FATAL_ERROR "Configuration failed for ${LIB_NAME}")
endif()

# Build
message(STATUS "Building ${LIB_NAME}...")
execute_process(
    COMMAND ${CMAKE_COMMAND} --build ${BUILD_DIR} --config Release
    RESULT_VARIABLE BUILD_RESULT
)
if(NOT BUILD_RESULT EQUAL 0)
    message(FATAL_ERROR "Build failed for ${LIB_NAME}")
endif()

# Install
message(STATUS "Installing ${LIB_NAME}...")
execute_process(
    COMMAND ${CMAKE_COMMAND} --install ${BUILD_DIR} --config Release
    RESULT_VARIABLE INST_RESULT
)
if(NOT INST_RESULT EQUAL 0)
    message(FATAL_ERROR "Install failed for ${LIB_NAME}")
endif()

message(STATUS "${LIB_NAME} successfully built and installed to ${PREFIX}")
