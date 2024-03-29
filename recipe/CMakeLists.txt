#[[
Copyright (c) Microsoft Corporation

All rights reserved.

MIT License

Permission is hereby granted, free of charge, to any person obtaining a copy of
this software and associated documentation files (the "Software"), to deal in
the Software without restriction, including without limitation the rights to
use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies
of the Software, and to permit persons to whom the Software is furnished to do
so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED *AS IS*, WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
]]

cmake_minimum_required(VERSION 3.8)
project(Irrlicht)

set_property(GLOBAL PROPERTY USE_FOLDERS ON)

# Irrlicht directories
# -------------------------------------------------------------------------------------------------
set(IRR_SRC_DIR "source/Irrlicht")
set(IRR_INC_DIR "include")
set(IRR_TOOL_DIR "tools")

# Options
# -------------------------------------------------------------------------------------------------
set(DXSDK "")
if(DEFINED ENV{DXSDK_DIR})
    set(DXSDK "$ENV{DXSDK_DIR}")
endif()

set(IRR_UNICODE_PATH 0 CACHE BOOL "Whether to enable unicode path support on windows")
set(IRR_FAST_MATH 0 CACHE BOOL "Whether to enable fast maths (at the expense of precision)")
set(IRR_DIRECTX_SDK ${DXSDK} CACHE PATH "Path to the DirectX SDK (for DirectX 9, this folder should contain /Include, /Lib)")
set(IRR_BUILD_TOOLS 0 CACHE BOOL "Whether to generate the tools")
set(IRR_BUILD_DIRECTX 0 CACHE BOOL "Whether to build DirectX")
option(BUILD_SHARED_LIBS "Build libraries as shared as opposed to static" ON)

# Some helper functions
# -------------------------------------------------------------------------------------------------
function(glob_c_cpp_sources result folder)
    file(GLOB res
        "${folder}/*.c"
        "${folder}/*.cpp"
        "${folder}/*.h"
        "${folder}/*.hpp"
        "${folder}/*.rc")
    set(${result} ${res} PARENT_SCOPE)
endfunction()

# Source files
# -------------------------------------------------------------------------------------------------
glob_c_cpp_sources(IRR_SRC_FILES                    ${IRR_SRC_DIR})
glob_c_cpp_sources(IRR_SRC_FILES_INTERFACE          ${IRR_INC_DIR})
glob_c_cpp_sources(IRR_SRC_FILES_AESGLADMAN         ${IRR_SRC_DIR}/aesGladman)
glob_c_cpp_sources(IRR_SRC_FILES_LZMA               ${IRR_SRC_DIR}/lzma)

glob_c_cpp_sources(IRR_TOOL_FILES_FILE_TO_HEADER    ${IRR_TOOL_DIR}/FileToHeader/)
glob_c_cpp_sources(IRR_TOOL_FILES_GUI_EDITOR        ${IRR_TOOL_DIR}/GUIEditor/)
glob_c_cpp_sources(IRR_TOOL_FILES_FONT_TOOL         ${IRR_TOOL_DIR}/IrrFontTool/newFontTool/)
glob_c_cpp_sources(IRR_TOOL_FILES_MESH_CONVERTER    ${IRR_TOOL_DIR}/MeshConverter/)

# Group files
# -------------------------------------------------------------------------------------------------
source_group(Irrlicht\\engine           FILES ${IRR_SRC_FILES})
source_group(Irrlicht\\interface        FILES ${IRR_SRC_FILES_INTERFACE})
source_group(Irrlicht\\libs\\aesGladman FILES ${IRR_SRC_FILES_AESGLADMAN})
source_group(Irrlicht\\libs\\lzma       FILES ${IRR_SRC_FILES_LZMA})

# Library files
# -------------------------------------------------------------------------------------------------
find_package(ZLIB REQUIRED)
find_package(PNG REQUIRED)
find_package(JPEG REQUIRED)
find_package(BZip2 REQUIRED)
find_package(SDL REQUIRED)

# Irrlicht target
# -------------------------------------------------------------------------------------------------
set(IRR_ALL_SRC_FILES
    ${IRR_SRC_FILES}
    ${IRR_SRC_FILES_INTERFACE}
    ${IRR_SRC_FILES_AESGLADMAN}
    ${IRR_SRC_FILES_LZMA}
    )
    
if(APPLE)
    file(GLOB IRR_SRC_FILES_MACOS "${IRR_SRC_DIR}/MacOSX/*.mm" "${IRR_SRC_DIR}/MacOSX/*.h" )
    list(APPEND IRR_ALL_SRC_FILES ${IRR_SRC_FILES_MACOS})
    set_source_files_properties("${IRR_SRC_DIR}/Irrlicht.cpp" PROPERTIES COMPILE_OPTIONS "-x;objective-c++")
    set_source_files_properties("${IRR_SRC_DIR}/COpenGLDriver.cpp" PROPERTIES COMPILE_OPTIONS "-x;objective-c++")
endif()

add_library(Irrlicht ${IRR_ALL_SRC_FILES})


target_link_libraries(Irrlicht PRIVATE
    PNG::PNG
    JPEG::JPEG
    ZLIB::ZLIB
    ${BZIP2_LIBRARY}
    SDL::SDL
    )

if(IRR_BUILD_TOOLS)
    add_executable(FileToHeader         ${IRR_TOOL_FILES_FILE_TO_HEADER})

    add_executable(GUIEditor            ${IRR_TOOL_FILES_GUI_EDITOR})
    target_link_libraries(GUIEditor     Irrlicht)

    add_executable(FontTool             ${IRR_TOOL_FILES_FONT_TOOL})
    target_link_libraries(FontTool      Irrlicht)

    add_executable(MeshConverter        ${IRR_TOOL_FILES_MESH_CONVERTER})
    target_link_libraries(MeshConverter Irrlicht)
endif()

# Target properties (for compilation & export)
# -------------------------------------------------------------------------------------------------
target_include_directories(Irrlicht
    PRIVATE ${IRR_SRC_DIR}
    PRIVATE ${IRR_SRC_DIR}/aesGladman
    PRIVATE ${IRR_SRC_DIR}/lzma
    )

target_include_directories(Irrlicht PUBLIC
    $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/include>
    $<INSTALL_INTERFACE:include/irrlicht>  # <prefix>/include/irrlicht
)

if(IRR_BUILD_DIRECTX)
    target_include_directories(Irrlicht PRIVATE ${IRR_DIRECTX_SDK}/Include)
    if(${CMAKE_SIZEOF_VOID_P} EQUAL 4)
        set(DX_LIBS ${IRR_DIRECTX_SDK}/Lib/x86)
    else()
        set(DX_LIBS ${IRR_DIRECTX_SDK}/Lib/x64)
    endif()
    target_link_libraries(Irrlicht
        PRIVATE ${DX_LIBS}/d3dx9.lib
        PRIVATE ${DX_LIBS}/dinput8.lib
        PRIVATE ${DX_LIBS}/dxguid.lib)
else()
    target_compile_definitions(Irrlicht PRIVATE NO_IRR_COMPILE_WITH_DIRECT3D_9_)
endif()

if(NOT ${BUILD_SHARED_LIBS})
    target_compile_definitions(Irrlicht PUBLIC _IRR_STATIC_LIB_)
endif()

# Disable Irrlicht building already provided dependencies
target_compile_definitions(Irrlicht
    PRIVATE NO_IRR_USE_NON_SYSTEM_ZLIB_
    PRIVATE NO_IRR_USE_NON_SYSTEM_LIB_PNG_
    PRIVATE NO_IRR_USE_NON_SYSTEM_BZLIB_
    PRIVATE NO_IRR_USE_NON_SYSTEM_JPEG_LIB_
    )

# Per platform config
# -------------------------------------------------------------------------------------------------

# Export symbols
target_compile_definitions(Irrlicht PRIVATE IRRLICHT_EXPORTS)

if(WIN32)
    # Import the symbols of bzip2
    target_compile_definitions(Irrlicht PRIVATE BZ_IMPORT)

    # Disable the ton of warnings from standard library
    target_compile_definitions(Irrlicht PRIVATE _CRT_SECURE_NO_WARNINGS)

    # Multi processor compilation
    target_compile_options(Irrlicht PRIVATE /MP)

    # Unicode
    if(${IRR_UNICODE_PATH})
        target_compile_definitions(Irrlicht PRIVATE UNICODE _UNICODE)
        target_compile_definitions(Irrlicht PUBLIC _IRR_WCHAR_FILESYSTEM)
    endif()

    # Fast math options
    if(${IRR_FAST_MATH})
        target_compile_options(Irrlicht PRIVATE /fp:fast)
        message("Fast Math Enabled")
        # SSE2 is automatically activated on x64
        if(${CMAKE_SIZEOF_VOID_P} EQUAL 4)
            target_compile_options(Irrlicht PRIVATE /arch:SSE2)
        endif()
    endif()

elseif(UNIX)
    # Standard mode
    target_compile_options(Irrlicht
        PRIVATE -Wall
        PRIVATE -pipe
        PRIVATE -fno-exceptions
        PRIVATE -fno-strict-aliasing)

    # Debug macro
    target_compile_options(Irrlicht PRIVATE $<$<CONFIG:Debug>:-D_DEBUG>)
    
    # Find X11 and OpenGL
    find_package(X11 REQUIRED)
    find_package(OpenGL REQUIRED)
    
    # X11 and OpenGL
    target_link_libraries(Irrlicht
        PRIVATE X11::X11
        PRIVATE OpenGL::GL)
        
    if(CMAKE_SYSTEM_NAME STREQUAL "Linux")
        target_link_libraries(Irrlicht PRIVATE X11::Xxf86vm)
    endif()
    
    if(APPLE)
        find_library(COCOA_LIB Cocoa)
        find_library(CARBON_LIB Carbon)
        find_library(IOKIT_LIB IOKit)
        target_link_libraries(Irrlicht PRIVATE ${IOKIT_LIB} ${COCOA_LIB} ${CARBON_LIB})
        target_compile_definitions(Irrlicht PRIVATE MACOSX)
        target_include_directories(Irrlicht PRIVATE ${IRR_SRC_DIR}/MacOSX)
    endif()
endif()

# Installation
# -------------------------------------------------------------------------------------------------
install(
    TARGETS Irrlicht
    EXPORT Irrlicht
    RUNTIME DESTINATION bin
    LIBRARY DESTINATION lib
    ARCHIVE DESTINATION lib
)

install(FILES ${IRR_SRC_FILES_INTERFACE} DESTINATION "include/irrlicht" CONFIGURATIONS Release)

if(IRR_BUILD_TOOLS)
    install(
        TARGETS FileToHeader GUIEditor FontTool MeshConverter
        RUNTIME DESTINATION tools/irrlicht/
        CONFIGURATIONS Release
    )
endif()

