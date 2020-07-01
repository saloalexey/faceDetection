project("fdl")


find_package( OpenCV REQUIRED core objdetect imgcodecs )


set(LIB_API_VERSION 1)
set(LIB_MINOR_VERSION 0)
set(LIB_RELEASE_VERSION "RC01")
set(LIB_VERSION "${LIB_API_VERSION}.${LIB_MINOR_VERSION}-${LIB_RELEASE_VERSION}")

set(INC_PREF ${CMAKE_CURRENT_SOURCE_DIR}/inc/)
set(SRC_PREF ${CMAKE_CURRENT_SOURCE_DIR}/src/)

set(INSTALL_HEADER_LIST ${INC_PREF}/faceDetection.hpp)
set(HEADER_LIST ${INSTALL_HEADER_LIST} )
set(SOURCE_LIST ${SRC_PREF}/faceDetection.cpp)


add_library(${PROJECT_NAME} SHARED ${SOURCE_LIST})
add_library(${PROJECT_NAME}::${PROJECT_NAME} ALIAS ${PROJECT_NAME})

target_link_libraries(${PROJECT_NAME} PRIVATE
                    OpenCV::core
                    OpenCV::objdetect
                    OpenCV::imgcodecs)

target_include_directories(${PROJECT_NAME} PUBLIC
     $<BUILD_INTERFACE:${INC_PREF}>
     $<INSTALL_INTERFACE:include/${PROJECT_NAME}>)

target_compile_definitions(${PROJECT_NAME} PRIVATE -DSYSROOT="${SYSROOT}")

set_target_properties(${PROJECT_NAME} PROPERTIES
    PUBLIC_HEADER "${INSTALL_HEADER_LIST}"
    POSITION_INDEPENDENT_CODE ON
    VERSION ${LIB_VERSION}
    SOVERSION ${LIB_API_VERSION})

include(${CMAKE_SOURCE_DIR}/cmake/CompilerWarnings.cmake)
set_project_warnings(${PROJECT_NAME})


###########     INSTALL     ####################

string(TOLOWER ${PROJECT_NAME} PROJECT_NAME_LC)

install(TARGETS ${PROJECT_NAME}
    EXPORT ${PROJECT_NAME_LC}-targets
    LIBRARY DESTINATION lib
    PUBLIC_HEADER DESTINATION include/${PROJECT_NAME})

#export(EXPORT ${PROJECT_NAME_LC}-targets
#    FILE "${CMAKE_CURRENT_BINARY_DIR}/cmake/${PROJECT_NAME_LC}-targets.cmake")

install(EXPORT ${PROJECT_NAME_LC}-targets
    FILE ${PROJECT_NAME_LC}-targets.cmake
    NAMESPACE ${PROJECT_NAME}::
    DESTINATION share/cmake/${PROJECT_NAME_LC})
