project("TestFaceDetection")

enable_testing()

find_package(GTest REQUIRED )

add_executable(${PROJECT_NAME} main.cpp testFaceDetection.cpp)
target_link_libraries(${PROJECT_NAME} PRIVATE
    gtest
    gtest_main
    fdl::fdl)

set(RESOURCES_DIR "${CMAKE_SOURCE_DIR}/tests/resources/")
target_compile_definitions(${PROJECT_NAME} PRIVATE -DIMAGE_DIR="${RESOURCES_DIR}")

add_test(NAME "${PROJECT_NAME}.Test" COMMAND ${PROJECT_NAME})
