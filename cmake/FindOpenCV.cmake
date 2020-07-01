cmake_minimum_required(VERSION 3.5)


# Download, build and install opencv at configure time
configure_file(${CMAKE_SOURCE_DIR}/cmake/DownloadOpenCV.cmake opencv-download/CMakeLists.txt)

execute_process(COMMAND ${CMAKE_COMMAND} -DOPENCV_ROOT_DIR=${OPENCV_ROOT_DIR} -G "${CMAKE_GENERATOR}" .
  RESULT_VARIABLE result
  WORKING_DIRECTORY ${CMAKE_BINARY_DIR}/opencv-download )

if(result)
  message(FATAL_ERROR "CMake step for opencv failed: ${result}")
endif()

execute_process(COMMAND ${CMAKE_COMMAND} --build .
  RESULT_VARIABLE result
  WORKING_DIRECTORY ${CMAKE_BINARY_DIR}/opencv-download )

if(result)
  message(FATAL_ERROR "Build step for opencv failed: ${result}")
endif()

execute_process(COMMAND ${CMAKE_COMMAND} --install .
  RESULT_VARIABLE result
  WORKING_DIRECTORY ${CMAKE_BINARY_DIR}/opencv-download )

if(result)
  message(FATAL_ERROR "Install step for opencv failed: ${result}")
endif()

#########     Importing Targets     #################

if(NOT OpenCV_INCLUDE_DIRS_EXPORT)
  find_path(OpenCV_INCLUDE_DIRS_EXPORT opencv4/opencv2/opencv.hpp HINTS ${OPENCV_ROOT_DIR}/include/ NO_DEFAULT_PATH)
  set(OpenCV_INCLUDE_DIRS_EXPORT "${OpenCV_INCLUDE_DIRS_EXPORT};${OpenCV_INCLUDE_DIRS_EXPORT}/opencv4/")
endif()
message(STATUS "OpenCV_INCLUDE_DIRS_EXPORT :${OpenCV_INCLUDE_DIRS_EXPORT}")

foreach(COMPONENT ${OpenCV_FIND_COMPONENTS})
  message(STATUS "Added OpenCV::${COMPONENT} imported target")
  if(NOT TARGET OpenCV::${COMPONENT})
      string(TOUPPER ${COMPONENT} UPPERCOMPONENT)

      find_library(OpenCV_${UPPERCOMPONENT}_LIBRARY "opencv_${COMPONENT}" HINTS ${OPENCV_ROOT_DIR}/lib)
      if( NOT EXISTS  ${OpenCV_${UPPERCOMPONENT}_LIBRARY})
          message(SEND_ERROR "Component opencv::${COMPONENT} has not FOUND")
      endif()

      add_library(OpenCV::${COMPONENT} UNKNOWN IMPORTED)

      if(OpenCV_INCLUDE_DIRS_EXPORT)
          set_target_properties(OpenCV::${COMPONENT} PROPERTIES
            INTERFACE_INCLUDE_DIRECTORIES "${OpenCV_INCLUDE_DIRS_EXPORT}"
          )
      endif()

      if(EXISTS "${OpenCV_${UPPERCOMPONENT}_LIBRARY}")
          set_target_properties(OpenCV::${COMPONENT} PROPERTIES
          IMPORTED_LINK_INTERFACE_LANGUAGES "CXX"
          IMPORTED_LOCATION "${OpenCV_${UPPERCOMPONENT}_LIBRARY}")
      endif()
  endif()
endforeach()




