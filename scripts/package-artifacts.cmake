# CMake Script to Package and Organize Artifacts
cmake_minimum_required(VERSION 3.15)

set(STAGE_DIR "${CMAKE_CURRENT_SOURCE_DIR}/nativeLibs")
set(BUILD_OUT_DIR "${CMAKE_CURRENT_SOURCE_DIR}/build-out")

message(STATUS "Creating packaging structure in ${STAGE_DIR}...")
file(REMOVE_RECURSE ${STAGE_DIR})
file(MAKE_DIRECTORY ${STAGE_DIR})
file(MAKE_DIRECTORY "${STAGE_DIR}/include")
file(MAKE_DIRECTORY "${STAGE_DIR}/lib")

# List of all targets
set(TARGETS
    windows-x64
    windows-arm64
    macos-x64
    macos-arm64
    linux-x64
    linux-arm64
    webgl
    android
    ios
    ios-simulator-arm64
    ios-x64
)

# 1. Copy headers from the first available build platform that has them
set(HEADERS_COPIED FALSE)
foreach(PLATFORM ${TARGETS})
    set(PLAT_INC "${BUILD_OUT_DIR}/${PLATFORM}/include")
    if(NOT EXISTS "${PLAT_INC}")
        set(PLAT_INC "${BUILD_OUT_DIR}/build-out-${PLATFORM}/include")
    endif()
    if(EXISTS "${PLAT_INC}" AND NOT HEADERS_COPIED)
        message(STATUS "Copying include files from ${PLATFORM} at ${PLAT_INC}...")
        # Copy everything in include to stage include
        file(COPY "${PLAT_INC}/" DESTINATION "${STAGE_DIR}/include")
        set(HEADERS_COPIED TRUE)
    endif()
endforeach()

# If headers weren't found in build-out, try to copy directly from wrapper and externals
if(NOT HEADERS_COPIED)
    message(WARNING "Could not find headers in build-out directory. Copying from sources...")
    # Copy miniaudio.h
    if(EXISTS "${CMAKE_CURRENT_SOURCE_DIR}/miniaudio-wrapper/miniaudio.h")
        file(COPY "${CMAKE_CURRENT_SOURCE_DIR}/miniaudio-wrapper/miniaudio.h" DESTINATION "${STAGE_DIR}/include")
    endif()
    # Copy Box2D headers
    if(EXISTS "${CMAKE_CURRENT_SOURCE_DIR}/external/box2d/include")
        file(COPY "${CMAKE_CURRENT_SOURCE_DIR}/external/box2d/include/" DESTINATION "${STAGE_DIR}/include")
    endif()
    # Copy SDL2 headers
    if(EXISTS "${CMAKE_CURRENT_SOURCE_DIR}/external/sdl2/include")
        file(COPY "${CMAKE_CURRENT_SOURCE_DIR}/external/sdl2/include/" DESTINATION "${STAGE_DIR}/include")
    endif()
endif()

# 2. Copy libraries for each platform
foreach(PLATFORM ${TARGETS})
    set(PLAT_LIB_STAGE "${STAGE_DIR}/lib/${PLATFORM}")
    file(MAKE_DIRECTORY ${PLAT_LIB_STAGE})
    
    set(PLAT_OUT "${BUILD_OUT_DIR}/${PLATFORM}")
    if(NOT EXISTS "${PLAT_OUT}")
        set(PLAT_OUT "${BUILD_OUT_DIR}/build-out-${PLATFORM}")
    endif()
    
    if(EXISTS "${PLAT_OUT}")
        message(STATUS "Processing libraries for ${PLATFORM} at ${PLAT_OUT}...")
        
        # Look in both lib and lib64 directories
        set(LIB_DIRS "${PLAT_OUT}/lib" "${PLAT_OUT}/lib64" "${PLAT_OUT}/bin")
        foreach(LIB_DIR ${LIB_DIRS})
            if(EXISTS "${LIB_DIR}")
                # Find all static libraries (.a on Unix, .lib on Windows)
                file(GLOB_RECURSE LIBS_A "${LIB_DIR}/*.a")
                file(GLOB_RECURSE LIBS_LIB "${LIB_DIR}/*.lib")
                
                # Copy found libraries
                foreach(LIB ${LIBS_A})
                    file(COPY ${LIB} DESTINATION ${PLAT_LIB_STAGE})
                endforeach()
                foreach(LIB ${LIBS_LIB})
                    # Exclude import libraries (like .lib files for DLLs, though we should only have static)
                    file(COPY ${LIB} DESTINATION ${PLAT_LIB_STAGE})
                endforeach()
            endif()
        endforeach()
    else()
        message(WARNING "No build directory found for platform ${PLATFORM} at ${PLAT_OUT}")
    endif()
endforeach()
# 2.5 Generate library manifest summary
set(MANIFEST_FILE "${STAGE_DIR}/manifest.md")
message(STATUS "Generating library manifest at ${MANIFEST_FILE}...")
file(WRITE ${MANIFEST_FILE}
    "### KoNa Engine Native Libraries Manifest\n\n"
    "This package contains the pre-compiled static native libraries for the KoNa Engine.\n\n"
    "| Library | Version / Git Tag | Build Linkage | Description |\n"
    "|---|---|---|---|\n"
    "| SDL2 | release-2.30.3 | Static | Simple DirectMedia Layer |\n"
    "| bgfx | latest (bgfx.cmake) | Static | Graphics rendering library |\n"
    "| Jolt Physics | v5.0.0 | Static | 3D Physics engine |\n"
    "| Box2D | v2.4.1 | Static | 2D Physics engine |\n"
    "| miniaudio | latest (master) | Static | Single-header audio library |\n"
)

# 3. Create nativeLibs.zip archive
message(STATUS "Compressing nativeLibs directory into nativeLibs.zip...")
execute_process(
    COMMAND ${CMAKE_COMMAND} -E tar cfv nativeLibs.zip --format=zip nativeLibs
    WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
    RESULT_VARIABLE ZIP_RESULT
)

if(ZIP_RESULT EQUAL 0)
    message(STATUS "Successfully created nativeLibs.zip")
else()
    message(FATAL_ERROR "Failed to create nativeLibs.zip")
endif()
