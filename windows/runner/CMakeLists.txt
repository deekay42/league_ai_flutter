cmake_minimum_required(VERSION 3.15)
project(runner LANGUAGES CXX)


if(MSVC)
    add_definitions(-D_CRT_SECURE_NO_WARNINGS)
    add_definitions(-DNOMINMAX)
endif()

set(debug_build $<NOT:$<CONFIG:Release>>)


add_executable(${BINARY_NAME} WIN32
  "flutter_window.cpp"
  "main.cpp"
  "run_loop.cpp"
  "utils.cpp"
  "win32_window.cpp"
  "../../src/desktop_main.cpp"
  "window_configuration.cpp"
  "${FLUTTER_MANAGED_DIR}/generated_plugin_registrant.cc"
  "Runner.rc"
  "runner.exe.manifest"
)


apply_standard_settings(${BINARY_NAME})
target_link_libraries(${BINARY_NAME} PRIVATE flutter flutter_wrapper_app)
target_include_directories(${BINARY_NAME} PRIVATE "${CMAKE_SOURCE_DIR}")
add_dependencies(${BINARY_NAME} flutter_assemble)



add_custom_command(TARGET ${BINARY_NAME} PRE_BUILD
    COMMAND "${CMAKE_COMMAND}" -E
    # do nothing for non-Release build
    $<${debug_build}:echo>
    # output text to make clear that the copy command is not actually issued
    $<${debug_build}:"copy omitted for non-release build, command would have been ">
    # the actual copy command, which is overridden by the "echo" above
    # in the case of a non-release build
    touch releaseflag)

add_custom_command(TARGET ${BINARY_NAME}
                       PRE_BUILD
                       COMMAND "..\\..\\..\\..\\python\\build\\embed_py2c.bat" "..\\..\\..\\..\\python" Release "..\\..\\..")



