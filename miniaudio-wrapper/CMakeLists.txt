cmake_minimum_required(VERSION 3.15)
project(miniaudio C)

add_library(miniaudio STATIC miniaudio.c)

target_include_directories(miniaudio PUBLIC ${CMAKE_CURRENT_SOURCE_DIR})

find_package(Threads REQUIRED)
target_link_libraries(miniaudio PRIVATE Threads::Threads)

if(CMAKE_SYSTEM_NAME STREQUAL "Linux")
    target_link_libraries(miniaudio PRIVATE dl m)
elseif(APPLE)
    find_library(COREAUDIO_LIB CoreAudio)
    find_library(AUDIOTOOLBOX_LIB AudioToolbox)
    find_library(COREFOUNDATION_LIB CoreFoundation)
    if(COREAUDIO_LIB)
        target_link_libraries(miniaudio PRIVATE ${COREAUDIO_LIB})
    endif()
    if(AUDIOTOOLBOX_LIB)
        target_link_libraries(miniaudio PRIVATE ${AUDIOTOOLBOX_LIB})
    endif()
    if(COREFOUNDATION_LIB)
        target_link_libraries(miniaudio PRIVATE ${COREFOUNDATION_LIB})
    endif()
elseif(CMAKE_SYSTEM_NAME STREQUAL "Android")
    target_link_libraries(miniaudio PRIVATE OpenSLES log)
endif()

# Installation target
install(TARGETS miniaudio
    ARCHIVE DESTINATION lib
    LIBRARY DESTINATION lib
)
install(FILES miniaudio.h DESTINATION include)
