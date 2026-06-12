# CMake Script to Build miniaudio
cmake_minimum_required(VERSION 3.15)

set(LIB_NAME miniaudio)
set(HEADER_URL "https://raw.githubusercontent.com/mackron/miniaudio/master/miniaudio.h")
set(WRAPPER_DIR "${CMAKE_CURRENT_SOURCE_DIR}/miniaudio-wrapper")
set(BUILD_DIR "${CMAKE_CURRENT_SOURCE_DIR}/external/${LIB_NAME}-build")

if(NOT DEFINED TARGET_PLATFORM)
    message(FATAL_ERROR "TARGET_PLATFORM not defined")
endif()

if(NOT DEFINED PREFIX)
    set(PREFIX "${CMAKE_CURRENT_SOURCE_DIR}/build-out/${TARGET_PLATFORM}")
endif()

# Download miniaudio.h if not exists or if empty placeholder
set(HEADER_FILE "${WRAPPER_DIR}/miniaudio.h")
if(NOT EXISTS "${HEADER_FILE}" OR (EXISTS "${HEADER_FILE}" AND (NOT EXISTS "${CMAKE_CURRENT_SOURCE_DIR}/external/miniaudio-downloaded")))
    message(STATUS "Downloading miniaudio.h from ${HEADER_URL}...")
    file(DOWNLOAD ${HEADER_URL} ${HEADER_FILE} SHOW_PROGRESS)
    # create a sentinel file to denote that we have fetched it successfully
    file(WRITE "${CMAKE_CURRENT_SOURCE_DIR}/external/miniaudio-downloaded" "1")
endif()

set(CMAKE_ARGS
    "-DCMAKE_INSTALL_PREFIX=${PREFIX}"
    "-DCMAKE_BUILD_TYPE=Release"
)

if(TARGET_PLATFORM STREQUAL "windows-x64")
    list(APPEND CMAKE_ARGS "-A" "x64")
elseif(TARGET_PLATFORM STREQUAL "windows-arm64")
    list(APPEND CMAKE_ARGS "-A" "ARM64")
elseif(TARGET_PLATFORM STREQUAL "macos-x64")
    list(APPEND CMAKE_ARGS "-DCMAKE_OSX_ARCHITECTURES=x86_64")
elseif(TARGET_PLATFORM STREQUAL "macos-arm64")
    list(APPEND CMAKE_ARGS "-DCMAKE_OSX_ARCHITECTURES=arm64")
elseif(TARGET_PLATFORM STREQUAL "linux-x64")
    # Default host config
elseif(TARGET_PLATFORM STREQUAL "linux-arm64")
    list(APPEND CMAKE_ARGS
        "-DCMAKE_C_COMPILER=aarch64-linux-gnu-gcc"
        "-DCMAKE_CXX_COMPILER=aarch64-linux-gnu-g++"
    )
elseif(TARGET_PLATFORM STREQUAL "webgl")
    list(APPEND CMAKE_ARGS
        "-DCMAKE_TOOLCHAIN_FILE=$ENV{EMSDK}/upstream/emscripten/cmake/Modules/Platform/Emscripten.cmake"
    )
elseif(TARGET_PLATFORM STREQUAL "android")
    list(APPEND CMAKE_ARGS
        "-DCMAKE_TOOLCHAIN_FILE=$ENV{ANDROID_NDK_LATEST_HOME}/build/cmake/android.toolchain.cmake"
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
endif()

# Configure
message(STATUS "Configuring miniaudio wrapper...")
execute_process(
    COMMAND ${CMAKE_COMMAND} -S ${WRAPPER_DIR} -B ${BUILD_DIR} ${CMAKE_ARGS}
    RESULT_VARIABLE CONF_RESULT
)
if(NOT CONF_RESULT EQUAL 0)
    message(FATAL_ERROR "Configuration failed for miniaudio")
endif()

# Build
message(STATUS "Building miniaudio wrapper...")
execute_process(
    COMMAND ${CMAKE_COMMAND} --build ${BUILD_DIR} --config Release
    RESULT_VARIABLE BUILD_RESULT
)
if(NOT BUILD_RESULT EQUAL 0)
    message(FATAL_ERROR "Build failed for miniaudio")
endif()

# Install
message(STATUS "Installing miniaudio wrapper...")
execute_process(
    COMMAND ${CMAKE_COMMAND} --install ${BUILD_DIR} --config Release
    RESULT_VARIABLE INST_RESULT
)
if(NOT INST_RESULT EQUAL 0)
    message(FATAL_ERROR "Install failed for miniaudio")
endif()

message(STATUS "miniaudio successfully built and installed to ${PREFIX}")
