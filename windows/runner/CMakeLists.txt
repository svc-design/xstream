cmake_minimum_required(VERSION 3.14)
project(runner LANGUAGES CXX)

# Define the application target.
add_executable(${BINARY_NAME} WIN32
  "flutter_window.cpp"
  "main.cpp"
  "utils.cpp"
  "native_bridge_plugin.cpp"
  "win32_window.cpp"
  "${FLUTTER_MANAGED_DIR}/generated_plugin_registrant.cc"
  "Runner.rc"
  "runner.exe.manifest"
)

# Standard Flutter build settings.
apply_standard_settings(${BINARY_NAME})

# Flutter version macros
target_compile_definitions(${BINARY_NAME} PRIVATE
  FLUTTER_VERSION="${FLUTTER_VERSION}"
  FLUTTER_VERSION_MAJOR=${FLUTTER_VERSION_MAJOR}
  FLUTTER_VERSION_MINOR=${FLUTTER_VERSION_MINOR}
  FLUTTER_VERSION_PATCH=${FLUTTER_VERSION_PATCH}
  FLUTTER_VERSION_BUILD=${FLUTTER_VERSION_BUILD}
  NOMINMAX
  USE_GO_LOGIC
)

# Link required libraries
target_link_libraries(${BINARY_NAME} PRIVATE flutter flutter_wrapper_app dwmapi.lib)

# Locate Go executable
find_program(GO_EXECUTABLE NAMES go)
if(NOT GO_EXECUTABLE)
  message(FATAL_ERROR "Go executable not found. Please install Go and ensure it is available in PATH.")
endif()

# ---- Build and link Go static library ----

add_custom_command(
  OUTPUT ${CMAKE_CURRENT_SOURCE_DIR}/libgo_logic.a ${CMAKE_CURRENT_SOURCE_DIR}/libgo_logic.h
  COMMAND ${CMAKE_COMMAND} -E env GOOS=windows GOARCH=amd64 CGO_ENABLED=1
          ${GO_EXECUTABLE} build -buildmode=c-archive -o libgo_logic.a ../go/nativebridge.go
  WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
  DEPENDS ../go/nativebridge.go
  BYPRODUCTS ${CMAKE_CURRENT_SOURCE_DIR}/libgo_logic.h
)

add_custom_target(go_logic_build ALL DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/libgo_logic.a)

add_library(go_logic STATIC IMPORTED)
set_property(TARGET go_logic PROPERTY IMPORTED_LOCATION "${CMAKE_CURRENT_SOURCE_DIR}/libgo_logic.a")
set_target_properties(go_logic PROPERTIES LINKER_LANGUAGE C)
add_dependencies(${BINARY_NAME} go_logic_build)
target_link_libraries(${BINARY_NAME} PRIVATE go_logic)

# Include dir for generated header
target_include_directories(${BINARY_NAME} PRIVATE
  "${CMAKE_CURRENT_SOURCE_DIR}"
  "${CMAKE_CURRENT_SOURCE_DIR}/.."
  "${FLUTTER_MANAGED_DIR}"
)

# Flutter build dependency
add_dependencies(${BINARY_NAME} flutter_assemble)
