cmake_minimum_required(VERSION 3.5)

include(ExternalProject)
ExternalProject_Add(opencv-thirdparties
    GIT_REPOSITORY    https://github.com/opencv/opencv.git
    GIT_TAG           4.3.0
    SOURCE_DIR        "${CMAKE_CURRENT_BINARY_DIR}/opencv-src"
    BINARY_DIR        "${CMAKE_CURRENT_BINARY_DIR}/opencv-build"
    INSTALL_DIR       "${OPENCV_ROOT_DIR}"
    # CONFIGURE_COMMAND cmake ${CMAKE_CURRENT_BINARY_DIR}/opencv-src
    # BUILD_COMMAND     cmake --build ${CMAKE_CURRENT_BINARY_DIR}/opencv-build -j4
    #INSTALL_COMMAND   ${CMAKE_COMMAND} --install "${CMAKE_CURRENT_BINARY_DIR}/opencv-src" --prefix ${OPENCV_ROOT_DIR}
    CMAKE_ARGS  	  "-DCMAKE_INSTALL_PREFIX=${OPENCV_ROOT_DIR}"
    TEST_COMMAND      ""
)
