# OBS Blade Remote standalone: tray / menu bar app around the bridge core
# (desktop/core) with the shared panel (desktop/ui).
#   desktop/core/build-lib.sh   (Windows: cargo build --release in desktop/core)
#   cmake -B build -DCMAKE_PREFIX_PATH=<Qt6> && cmake --build build --config Release
cmake_minimum_required(VERSION 3.28)
project(obs-blade-remote-standalone VERSION 0.4.0 LANGUAGES CXX)
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_AUTOMOC ON)
set(CMAKE_AUTORCC ON)
if(APPLE)
  set(CMAKE_OSX_DEPLOYMENT_TARGET 12.0 CACHE STRING "")
endif()

find_package(Qt6 REQUIRED COMPONENTS Widgets)
# Qt6 builds that still link Apple's AGL break on the macOS 26 SDK
if(APPLE AND TARGET WrapOpenGL::WrapOpenGL)
  get_target_property(_wrap_gl_libs WrapOpenGL::WrapOpenGL INTERFACE_LINK_LIBRARIES)
  if(_wrap_gl_libs)
    list(FILTER _wrap_gl_libs EXCLUDE REGEX "AGL")
    set_target_properties(WrapOpenGL::WrapOpenGL PROPERTIES INTERFACE_LINK_LIBRARIES "${_wrap_gl_libs}")
  endif()
endif()

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
  message(FATAL_ERROR "Bridge core not built: ${OBB_CORE_LIB}")
endif()

add_executable(
  obs-blade-remote
  WIN32
  MACOSX_BUNDLE
  src/main.cpp
  src/obs_process.cpp
  src/obs_process.hpp
  src/autostart.cpp
  src/autostart.hpp
  "${OBB_DESKTOP}/ui/remote_panel.cpp"
  "${OBB_DESKTOP}/ui/remote_panel.hpp"
  resources/resources.qrc
)
target_include_directories(obs-blade-remote PRIVATE "${OBB_DESKTOP}/core/include" "${OBB_DESKTOP}/ui" src)
target_link_libraries(obs-blade-remote PRIVATE Qt6::Widgets "${OBB_CORE_LIB}")
if(APPLE)
  target_link_libraries(obs-blade-remote PRIVATE iconv)
  set_target_properties(
    obs-blade-remote
    PROPERTIES
      OUTPUT_NAME "OBS Blade Remote"
      MACOSX_BUNDLE_INFO_PLIST "${CMAKE_CURRENT_SOURCE_DIR}/resources/Info.plist.in"
      MACOSX_BUNDLE_GUI_IDENTIFIER com.kounex.obs-blade-remote.app
      MACOSX_BUNDLE_BUNDLE_NAME "OBS Blade Remote"
      MACOSX_BUNDLE_SHORT_VERSION_STRING ${PROJECT_VERSION}
      MACOSX_BUNDLE_BUNDLE_VERSION ${PROJECT_VERSION}
  )
elseif(WIN32)
  # The exe's icon (Explorer, taskbar, Start menu)
  target_sources(obs-blade-remote PRIVATE resources/app.rc)
  target_link_libraries(obs-blade-remote PRIVATE ws2_32 userenv ntdll bcrypt advapi32 kernel32)
else()
  target_link_libraries(obs-blade-remote PRIVATE pthread dl m)
endif()
