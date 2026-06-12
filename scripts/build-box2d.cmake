# CMake Script to Build Box2D
cmake_minimum_required(VERSION 3.15)

set(LIB_NAME box2d)
set(GIT_URL "https://github.com/erincatto/box2d.git")
set(GIT_TAG "v2.4.1")

if(NOT DEFINED TARGET_PLATFORM)
    message(FATAL_ERROR "TARGET_PLATFORM not defined")
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

set(CMAKE_ARGS
    "-DCMAKE_INSTALL_PREFIX=${PREFIX}"
    "-DCMAKE_BUILD_TYPE=Release"
    "-DBOX2D_BUILD_UNIT_TESTS=OFF"
    "-DBOX2D_BUILD_TESTBED=OFF"
    "-DBOX2D_BUILD_DOCS=OFF"
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
        "-DANDROID_PLATFORM=android-24"
    )
elseif(TARGET_PLATFORM STREQUAL "ios")
    list(APPEND CMAKE_ARGS
        "-DCMAKE_SYSTEM_NAME=iOS"
        "-DCMAKE_OSX_ARCHITECTURES=arm64"
        "-DCMAKE_OSX_SYSROOT=iphoneos"
    )
endif()

# Configure
message(STATUS "Configuring ${LIB_NAME}...")
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
