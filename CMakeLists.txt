cmake_minimum_required(VERSION 3.5)

project("FaceDetectionApp" VERSION 1.0)

set(CMAKE_CXX_STANDARD 11)

option(ENABLE_TESTING "Enable Test Builds" ON)
include(cmake/StaticAnalyzers.cmake)

set(SYSROOT ${CMAKE_BINARY_DIR}/sysroot)
file(MAKE_DIRECTORY ${SYSROOT})

list(APPEND CMAKE_MODULE_PATH ${CMAKE_SOURCE_DIR}/cmake)

set(BOOST_ROOT_DIR ${SYSROOT})
set(OPENCV_ROOT_DIR ${SYSROOT})
find_package(Boost REQUIRED COMPONENTS system filesystem program_options)
find_package(OpenCV REQUIRED COMPONENTS core imgcodecs imgproc)


######     LIBRARY      #####
add_subdirectory(fdl)

######     APPLICATION      #####
add_executable(${PROJECT_NAME} main.cpp
    src/Worker.cpp
    src/Dispatcher.cpp
    src/Request.cpp
    src/CmdLineOptions.cpp
    src/JsonImageWrapper.cpp)

target_link_libraries(${PROJECT_NAME} PRIVATE
    OpenCV::core
    OpenCV::imgcodecs
    OpenCV::imgproc
    Boost::system
    Boost::filesystem
    Boost::program_options
    fdl::fdl
    -lpthread)


target_include_directories(${PROJECT_NAME} PUBLIC ${CMAKE_SOURCE_DIR}/inc ${Boost_INCLUDE_DIRS})
target_compile_definitions(${PROJECT_NAME} PUBLIC -DPROJECT_VERSION="${PROJECT_VERSION}")

include(${CMAKE_SOURCE_DIR}/cmake/CompilerWarnings.cmake)
set_project_warnings(${PROJECT_NAME})

######     TESTS      #####
if(ENABLE_TESTING)
  enable_testing()
  message( "******   Building Tests.    *******")
  add_subdirectory(tests)
endif()


