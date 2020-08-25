cmake_minimum_required(VERSION 3.10)
set(PROJECT_NAME "fbfunctions")
project(${PROJECT_NAME} LANGUAGES CXX)

set(PLUGIN_NAME "${PROJECT_NAME}_plugin")

add_library(${PLUGIN_NAME} SHARED
  "${PLUGIN_NAME}.cpp"
  "../../../../src/desktop_main.cpp"
)
apply_standard_settings(${PLUGIN_NAME})
set_target_properties(${PLUGIN_NAME} PROPERTIES
  CXX_VISIBILITY_PRESET hidden)
target_compile_definitions(${PLUGIN_NAME} PRIVATE FLUTTER_PLUGIN_IMPL)
target_compile_definitions(${PLUGIN_NAME} PRIVATE _SILENCE_CXX17_CODECVT_HEADER_DEPRECATION_WARNING)
target_include_directories(${PLUGIN_NAME} INTERFACE
  "${CMAKE_CURRENT_SOURCE_DIR}/include")


if(MSVC)
    add_definitions(-D_CRT_SECURE_NO_WARNINGS)
    add_definitions(-DNOMINMAX)
endif()


set( leagueiq_libs 
    debug flutter optimized flutter
    debug flutter_wrapper_plugin optimized flutter_wrapper_plugin
    debug firebase_app_d optimized firebase_app
    debug firebase_auth_d optimized firebase_auth
    debug firebase_database_d optimized firebase_database
    debug firebase_firestore_d optimized firebase_firestore
    debug firebase_functions_d optimized firebase_functions
    debug firebase_messaging_d optimized firebase_messaging
    debug advapi32 optimized advapi32
    debug crypt32 optimized crypt32
    debug iphlpapi optimized iphlpapi
    debug psapi optimized psapi
    debug userenv optimized userenv
    debug ws2_32 optimized ws2_32
    debug RpcRT4 optimized RpcRT4
    debug shell32 optimized shell32)
target_link_libraries( ${PLUGIN_NAME} ${leagueiq_libs} )

# List of absolute paths to libraries that should be bundled with the plugin
set(file_chooser_bundled_libraries
  ""
  PARENT_SCOPE
)
