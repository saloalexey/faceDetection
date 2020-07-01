cmake_minimum_required(VERSION 3.5)

if(NOT Boost_FIND_COMPONENTS)
    message(FATAL_ERROR "No COMPONENTS specified for Boost")
endif()

message(STATUS "Requested Boost components : ${Boost_FIND_COMPONENTS}")

set(BOOST_USE_STATIC_LIBS false)

# Set the library prefix and library suffix properly.
if(BOOST_USE_STATIC_LIBS)
    set(CMAKE_FIND_LIBRARY_PREFIXES ${CMAKE_STATIC_LIBRARY_PREFIX})
    set(CMAKE_FIND_LIBRARY_SUFFIXES ${CMAKE_STATIC_LIBRARY_SUFFIX})
    set(LIBRARY_PREFIX ${CMAKE_STATIC_LIBRARY_PREFIX})
    set(LIBRARY_SUFFIX ${CMAKE_STATIC_LIBRARY_SUFFIX})
else()
    set(CMAKE_FIND_LIBRARY_PREFIXES ${CMAKE_SHARED_LIBRARY_PREFIX})
    set(CMAKE_FIND_LIBRARY_SUFFIXES ${CMAKE_SHARED_LIBRARY_SUFFIX})
    set(LIBRARY_PREFIX ${CMAKE_SHARED_LIBRARY_PREFIX})
    set(LIBRARY_SUFFIX ${CMAKE_SHARED_LIBRARY_SUFFIX})
endif()



# Create a string for the first component (e.g. boost_program_options)
# and assigns it to Boost_FIND_COMPONENTS
list(GET Boost_FIND_COMPONENTS 0 BOOST_FIRST_COMPONENT)
set(BOOST_FIRST_COMPONENT "boost_${BOOST_FIRST_COMPONENT}")

include(FindPackageHandleStandardArgs)


macro(DO_FIND_BOOST_ROOT)

    if( ${ARGC} EQUAL 0)
        unset(LOCAL_BOOST_ROOT_DIR)
    else()
        set(LOCAL_BOOST_ROOT_DIR ${ARGV0})
    endif()

    unset(Boost_INCLUDE_DIRS CACHE)
    find_path(Boost_INCLUDE_DIRS boost/config.hpp HINTS ${LOCAL_BOOST_ROOT_DIR}/include NO_DEFAULT_PATH)
    if(NOT Boost_INCLUDE_DIRS)
        message(STATUS "Look for Boost_INCLUDE_DIRS in default path")
        find_path(Boost_INCLUDE_DIRS boost/config.hpp REQUIRED)
    endif()

    set(SKIP_INSTALLED_BOOST "True")
    if( Boost_FIND_VERSION )
        set(Boost_VERSION 0)
        set(Boost_LIB_VERSION "")
        if(EXISTS "${Boost_INCLUDE_DIRS}/boost/version.hpp")
            file(STRINGS "${Boost_INCLUDE_DIRS}/boost/version.hpp" _boost_VERSION_HPP_CONTENTS REGEX "#define BOOST_(LIB_)?VERSION ")
            set(_Boost_VERSION_REGEX "([0-9]+)")
            set(_Boost_LIB_VERSION_REGEX "\"([0-9_]+)\"")
            foreach(v VERSION LIB_VERSION)
            if("${_boost_VERSION_HPP_CONTENTS}" MATCHES "#define BOOST_${v} ${_Boost_${v}_REGEX}")
                set(Boost_${v} "${CMAKE_MATCH_1}")
            endif()
            endforeach()
            unset(_boost_VERSION_HPP_CONTENTS)

            math(EXPR Boost_MAJOR_VERSION "${Boost_VERSION} / 100000")
            math(EXPR Boost_MINOR_VERSION "${Boost_VERSION} / 100 % 1000")
            math(EXPR Boost_SUBMINOR_VERSION "${Boost_VERSION} % 100")

            set(Boost_VERSION "${Boost_MAJOR_VERSION}.${Boost_MINOR_VERSION}.${Boost_SUBMINOR_VERSION}")
            message(STATUS "Boost_VERSION : ${Boost_VERSION}")
            message(STATUS "Boost_FIND_VERSION : ${Boost_FIND_VERSION}")
            if( NOT ${Boost_VERSION} EQUAL ${Boost_FIND_VERSION} )
                message(STATUS "Version mismatch. We found ${Boost_VERSION} but expected ${Boost_FIND_VERSION}")
                unset(BOOST_FOUND)
                unset(SKIP_INSTALLED_BOOST)
            endif()
        else()
            unset(BOOST_FOUND)
            unset(SKIP_INSTALLED_BOOST)
        endif()
    endif()


    if( ${SKIP_INSTALLED_BOOST} )
        message(STATUS "Setting boost variables.")

        find_path(Boost_INCLUDE_DIRS boost/config.hpp HINTS ${LOCAL_BOOST_ROOT_DIR}/include NO_DEFAULT_PATH)

        # ------------------------------------------------------------------------
        #  Add imported targets
        # ------------------------------------------------------------------------

        if( Boost_INCLUDE_DIRS )
            # For header-only libraries
            if(NOT TARGET Boost::boost)
                add_library(Boost::boost INTERFACE IMPORTED)
                if(Boost_INCLUDE_DIRS)
                    set_target_properties(Boost::boost PROPERTIES
                    INTERFACE_INCLUDE_DIRECTORIES "${Boost_INCLUDE_DIRS}")
                endif()
            endif()

            foreach(COMPONENT ${Boost_FIND_COMPONENTS})
                if(NOT TARGET Boost::${COMPONENT})
                    string(TOUPPER ${COMPONENT} UPPERCOMPONENT)

                    find_library(Boost_${UPPERCOMPONENT}_LIBRARY "boost_${COMPONENT}" HINTS ${LOCAL_BOOST_ROOT_DIR}/lib)
                    if( EXISTS  ${Boost_${UPPERCOMPONENT}_LIBRARY})
                        set(Boost_${UPPERCOMPONENT}_FOUND 1)
                    endif()

                    if(Boost_${UPPERCOMPONENT}_FOUND)
                        if(Boost_USE_STATIC_LIBS)
                            add_library(Boost::${COMPONENT} STATIC IMPORTED)
                        else()
                            # Even if Boost_USE_STATIC_LIBS is OFF, we might have static
                            # libraries as a result.
                            add_library(Boost::${COMPONENT} UNKNOWN IMPORTED)
                        endif()
                        if(Boost_INCLUDE_DIRS)
                            set_target_properties(Boost::${COMPONENT} PROPERTIES
                            INTERFACE_INCLUDE_DIRECTORIES "${Boost_INCLUDE_DIRS}")
                        endif()
                        if(EXISTS "${Boost_${UPPERCOMPONENT}_LIBRARY}")
                            set_target_properties(Boost::${COMPONENT} PROPERTIES
                            IMPORTED_LINK_INTERFACE_LANGUAGES "CXX"
                            IMPORTED_LOCATION "${Boost_${UPPERCOMPONENT}_LIBRARY}")
                        endif()

                        if(_Boost_${UPPERCOMPONENT}_COMPILER_FEATURES)
                            set_target_properties(Boost::${COMPONENT} PROPERTIES
                            INTERFACE_COMPILE_FEATURES "${_Boost_${UPPERCOMPONENT}_COMPILER_FEATURES}")
                        endif()
                    else()
                        message(SEND_ERROR "Component Boost::${COMPONENT} has not FOUND")
                    endif()
                endif()
            endforeach()
        endif()

        # BOOST_LIBRARIES
        FIND_PACKAGE_HANDLE_STANDARD_ARGS(Boost DEFAULT_MSG
            Boost_INCLUDE_DIRS
            )
        mark_as_advanced(BOOST_LIBRARIES Boost_INCLUDE_DIRS)
    endif()
endmacro()

macro(DO_FIND_BOOST_DOWNLOAD)
    if(NOT Boost_FIND_VERSION)
        message(FATAL_ERROR "[Error] Boost version is not defined.")
    endif()

    string(REPLACE "." "_" BOOST_REQUESTED_VERSION_UNDERSCORE ${Boost_FIND_VERSION})

    set(BOOST_MAYBE_STATIC)
    if(BOOST_USE_STATIC_LIBS)
        set(BOOST_MAYBE_STATIC "link=static")
    endif()

    # Download boost if required

    set(BoostArchiveFile boost_${BOOST_REQUESTED_VERSION_UNDERSCORE}.tar.gz)
    set(BoostExtactDir "${CMAKE_BINARY_DIR}/thirdparties/boost/")
    set(BoostSrcDir ${BoostExtactDir}/boost_${BOOST_REQUESTED_VERSION_UNDERSCORE})
    file(MAKE_DIRECTORY ${BoostExtactDir})
    if(NOT EXISTS ${BoostExtactDir}/${BoostArchiveFile})
        message(STATUS "Downloading boost ${Boost_FIND_VERSION}")

        set(BoostSHA256 9995e192e68528793755692917f9eb6422f3052a53c5e13ba278a228af6c7acf)
        file(DOWNLOAD https://dl.bintray.com/boostorg/release/${Boost_FIND_VERSION}/source/${BoostArchiveFile}
            ${BoostExtactDir}/${BoostArchiveFile}
            STATUS Status
            SHOW_PROGRESS
            EXPECTED_HASH SHA256=${BoostSHA256}
        )
    endif()

    if(NOT EXISTS ${BoostSrcDir} )
        message(STATUS "Extracting boost ${Boost_FIND_VERSION}")
        execute_process(COMMAND ${CMAKE_COMMAND} -E tar xfz ${BoostExtactDir}/${BoostArchiveFile}
            WORKING_DIRECTORY ${BoostExtactDir}
            RESULT_VARIABLE Result
        )
        if(NOT Result EQUAL "0")
            message(FATAL_ERROR "Failed extracting boost ${BoostArchiveFile} to ${BoostExtactDir}")
          endif()
    endif()

    if (WIN32)
        message(STATUS "WIN32: Set bootstrap util")
        set( Bootstrap "${BoostSrcDir}/bootstrap.bat")
    else()
        message(STATUS "UNIX: Set bootstrap util")
        set( Bootstrap "${BoostSrcDir}/bootstrap.sh")
    endif ()

    if(NOT EXISTS ${BoostSrcDir}/b2)
        message(STATUS "Bootstrapping boost ${Boost_FIND_VERSION}")
        execute_process(COMMAND ${Bootstrap} WORKING_DIRECTORY ${BoostSrcDir}
            RESULT_VARIABLE Result OUTPUT_VARIABLE Output ERROR_VARIABLE Error)

        if(NOT Result EQUAL "0")
            message(FATAL_ERROR "Failed running ${Bootstrap}:\n${Output}\n${Error}\n")
        endif()
    endif()

    if(NOT EXISTS ${BOOST_ROOT_DIR}/include/boost)

        message(STATUS "Building boost ${Boost_FIND_VERSION}")
        execute_process(COMMAND ${BoostSrcDir}/b2 --user-config=${BoostSrcDir}/project-config.jam --prefix=${BOOST_ROOT_DIR} --ignore-site-config install WORKING_DIRECTORY ${BoostSrcDir}
            RESULT_VARIABLE Result OUTPUT_VARIABLE Output ERROR_VARIABLE Error)

        if(NOT Result EQUAL "0")
            message(FATAL_ERROR "Failed running ${Bootstrap}:\n${Output}\n${Error}\n")
        endif()
    endif()



endmacro()

if(NOT BOOST_FOUND)
    message(STATUS "DO_FIND_BOOST_SYSTEM")
    DO_FIND_BOOST_ROOT()
endif()

if(NOT BOOST_FOUND)
    message(STATUS "DO_FIND_BOOST_DOWNLOAD")
    DO_FIND_BOOST_DOWNLOAD()
    message(STATUS "DO_FIND_BOOST_ROOT")
    DO_FIND_BOOST_ROOT(${BOOST_ROOT_DIR})
endif()

if(NOT BOOST_FOUND)
    message(SEND_ERROR "[Error] Boost not FOUND")
endif()

