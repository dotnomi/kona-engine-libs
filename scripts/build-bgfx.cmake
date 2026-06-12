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
        message(STATUS "Patching bgfx.cmake for WebGL pthreads...")
        file(APPEND "${SRC_DIR}/CMakeLists.txt" "\nadd_compile_options(-pthread -s USE_PTHREADS=1)\nadd_link_options(-pthread -s USE_PTHREADS=1)\n")
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
        "-DCMAKE_SYSTEM_NAME=Linux"
        "-DCMAKE_SYSTEM_PROCESSOR=aarch64"
        "-DCMAKE_C_COMPILER=aarch64-linux-gnu-gcc"
        "-DCMAKE_CXX_COMPILER=aarch64-linux-gnu-g++"
    )
elseif(TARGET_PLATFORM STREQUAL "webgl")
    set(ENV{CFLAGS} "-msimd128 -pthread")
    set(ENV{CXXFLAGS} "-msimd128 -pthread")
    set(ENV{LDFLAGS} "-pthread")
    list(APPEND CMAKE_ARGS
        "-DCMAKE_TOOLCHAIN_FILE=$ENV{EMSDK}/upstream/emscripten/cmake/Modules/Platform/Emscripten.cmake"
        "-DCMAKE_C_FLAGS=-msimd128 -pthread -s USE_PTHREADS=1"
        "-DCMAKE_CXX_FLAGS=-msimd128 -pthread -s USE_PTHREADS=1"
        "-DCMAKE_EXE_LINKER_FLAGS=-pthread -s USE_PTHREADS=1"
        "-DBGFX_CONFIG_MULTITHREADED=ON"
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
