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
target_compile_definitions(${BINARY_NAME} PRIVATE FLUTTER_VERSION="${FLUTTER_VERSION}")
target_compile_definitions(${BINARY_NAME} PRIVATE FLUTTER_VERSION_MAJOR=${FLUTTER_VERSION_MAJOR})
target_compile_definitions(${BINARY_NAME} PRIVATE FLUTTER_VERSION_MINOR=${FLUTTER_VERSION_MINOR})
target_compile_definitions(${BINARY_NAME} PRIVATE FLUTTER_VERSION_PATCH=${FLUTTER_VERSION_PATCH})
target_compile_definitions(${BINARY_NAME} PRIVATE FLUTTER_VERSION_BUILD=${FLUTTER_VERSION_BUILD})

# Prevent Windows macros from interfering with C++ STL
target_compile_definitions(${BINARY_NAME} PRIVATE NOMINMAX)

# Link required libraries
target_link_libraries(${BINARY_NAME} PRIVATE flutter flutter_wrapper_app dwmapi.lib)

# ---- Build and link Go static library ----

# Generate libgo_logic.a from Go code
add_custom_command(
  OUTPUT ${CMAKE_CURRENT_SOURCE_DIR}/libgo_logic.a
  COMMAND ${CMAKE_COMMAND} -E env GOOS=windows GOARCH=amd64
          go build -buildmode=c-archive -o libgo_logic.a ../go/nativebridge.go
  WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
  DEPENDS ../go/nativebridge.go
)

# Build target for the Go library
add_custom_target(go_logic_build ALL DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/libgo_logic.a)

# Import and link Go static library
add_library(go_logic STATIC IMPORTED)
set_property(TARGET go_logic PROPERTY IMPORTED_LOCATION "${CMAKE_CURRENT_SOURCE_DIR}/libgo_logic.a")
add_dependencies(${BINARY_NAME} go_logic_build)
target_link_libraries(${BINARY_NAME} PRIVATE go_logic)

# Add include dir for generated libgo_logic.h (optional)
target_include_directories(${BINARY_NAME} PRIVATE "${CMAKE_CURRENT_SOURCE_DIR}")

# Flutter build dependency
add_dependencies(${BINARY_NAME} flutter_assemble)
