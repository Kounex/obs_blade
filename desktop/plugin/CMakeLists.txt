cmake_minimum_required(VERSION 3.28...3.30)

include("${CMAKE_CURRENT_SOURCE_DIR}/cmake/common/bootstrap.cmake" NO_POLICY_SCOPE)

project(${_name} VERSION ${_version})

option(ENABLE_FRONTEND_API "Use obs-frontend-api for UI functionality" ON)
option(ENABLE_QT "Use Qt functionality" ON)

include(compilerconfig)
include(defaults)
include(helpers)

add_library(${CMAKE_PROJECT_NAME} MODULE)

find_package(libobs REQUIRED)
target_link_libraries(${CMAKE_PROJECT_NAME} PRIVATE OBS::libobs)

if(ENABLE_FRONTEND_API)
  find_package(obs-frontend-api REQUIRED)
  target_link_libraries(${CMAKE_PROJECT_NAME} PRIVATE OBS::obs-frontend-api)
endif()

if(ENABLE_QT)
  find_package(Qt6 COMPONENTS Widgets Core)
  # obs-deps' Qt6 (2025-07-11) still links Apple's AGL framework, which the
  # macOS 26 SDK no longer ships ("framework 'AGL' not found"); nothing here
  # uses it
  if(APPLE AND TARGET WrapOpenGL::WrapOpenGL)
    get_target_property(_wrap_gl_libs WrapOpenGL::WrapOpenGL INTERFACE_LINK_LIBRARIES)
    if(_wrap_gl_libs)
      list(FILTER _wrap_gl_libs EXCLUDE REGEX "AGL")
      set_target_properties(WrapOpenGL::WrapOpenGL PROPERTIES INTERFACE_LINK_LIBRARIES "${_wrap_gl_libs}")
    endif()
  endif()
  target_link_libraries(${CMAKE_PROJECT_NAME} PRIVATE Qt6::Core Qt6::Widgets)
  target_compile_options(
    ${CMAKE_PROJECT_NAME}
    PRIVATE $<$<C_COMPILER_ID:Clang,AppleClang>:-Wno-quoted-include-in-framework-header -Wno-comma>
  )
  set_target_properties(
    ${CMAKE_PROJECT_NAME}
    PROPERTIES AUTOMOC ON AUTOUIC ON AUTORCC ON
  )
endif()

# Shared settings panel (desktop/ui) and the Rust core (desktop/core,
# static library from desktop/core/build-lib.sh / cargo on Windows)
set(OBB_DESKTOP "${CMAKE_CURRENT_SOURCE_DIR}/..")
if(WIN32)
  set(_obb_default "${OBB_DESKTOP}/core/target/release/obb.lib")
elseif(APPLE)
  set(_obb_default "${OBB_DESKTOP}/core/target/dist/macos/libobb.a")
else()
  set(_obb_default "${OBB_DESKTOP}/core/target/dist/linux/libobb.a")
endif()
set(OBB_CORE_LIB "${_obb_default}" CACHE FILEPATH "The bridge core static library")
if(NOT EXISTS "${OBB_CORE_LIB}")
  message(FATAL_ERROR "Bridge core not built: ${OBB_CORE_LIB} (run desktop/core/build-lib.sh)")
endif()

target_sources(
  ${CMAKE_PROJECT_NAME}
  PRIVATE src/plugin-main.cpp src/obs-websocket-api.h "${OBB_DESKTOP}/ui/remote_panel.cpp" "${OBB_DESKTOP}/ui/remote_panel.hpp"
)
target_include_directories(${CMAKE_PROJECT_NAME} PRIVATE "${OBB_DESKTOP}/core/include" "${OBB_DESKTOP}/ui" src)
target_link_libraries(${CMAKE_PROJECT_NAME} PRIVATE "${OBB_CORE_LIB}")
# What the Rust std + deps need (cargo rustc -- --print native-static-libs)
if(APPLE)
  target_link_libraries(${CMAKE_PROJECT_NAME} PRIVATE iconv)
elseif(WIN32)
  target_link_libraries(${CMAKE_PROJECT_NAME} PRIVATE ws2_32 userenv ntdll bcrypt advapi32 kernel32)
else()
  target_link_libraries(${CMAKE_PROJECT_NAME} PRIVATE pthread dl m)
endif()

set_target_properties_plugin(${CMAKE_PROJECT_NAME} PROPERTIES OUTPUT_NAME ${_name})
