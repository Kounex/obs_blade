# Renders the shared panel in every state to PNGs (offscreen) - the desktop
# counterpart of tool/widget_shots. Build against any Qt6, e.g. the plugin's:
#   cmake -B build -DCMAKE_PREFIX_PATH=<Qt6 prefix> && cmake --build build
#   QT_QPA_PLATFORM=offscreen build/panel_preview <out dir>
cmake_minimum_required(VERSION 3.28)
project(panel_preview LANGUAGES CXX)
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_AUTOMOC ON)
find_package(Qt6 REQUIRED COMPONENTS Widgets)
if(APPLE AND TARGET WrapOpenGL::WrapOpenGL)
  get_target_property(_wrap_gl_libs WrapOpenGL::WrapOpenGL INTERFACE_LINK_LIBRARIES)
  if(_wrap_gl_libs)
    list(FILTER _wrap_gl_libs EXCLUDE REGEX "AGL")
    set_target_properties(WrapOpenGL::WrapOpenGL PROPERTIES INTERFACE_LINK_LIBRARIES "${_wrap_gl_libs}")
  endif()
endif()
add_executable(panel_preview main.cpp ../remote_panel.cpp ../remote_panel.hpp)
target_include_directories(panel_preview PRIVATE ..)
target_link_libraries(panel_preview PRIVATE Qt6::Widgets)
