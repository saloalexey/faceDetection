
# - Find Boost
# 
# Copyright (c) 2016 Thiago Barroso Perrotta
# 
# Permission is hereby granted, free of charge, to any person obtaining a copy of
# this software and associated documentation files (the "Software"), to deal in
# the Software without restriction, including without limitation the rights to
# use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of
# the Software, and to permit persons to whom the Software is furnished to do so,
# subject to the following conditions:
# 
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
# 
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
# FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
# COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
# IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
# CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
#
# This module finds if Boost is installed and determines where the
# executables are. It sets the following variables:
#
#  BOOST_FOUND : boolean            - system has Boost
#  BOOST_LIBRARIES : list(filepath) - the libraries needed to use Boost
#  BOOST_INCLUDE_DIRS : list(path)  - the Boost include directories
#
# If Boost is not found, this module downloads it according to the
# following variables:
#
#  BOOST_ROOT_DIR : path                - the Path where Boost will be installed on
#  BOOST_REQUESTED_VERSION : string     - the Boost version to be downloaded
#
# You can also specify its components:
#
#  find_package(Boost COMPONENTS program_options system)
#
# which are stored in Boost_FIND_COMPONENTS : list(string)
#
# You can also specify its behavior:
#
#  BOOST_USE_STATIC_LIBS : boolean (default: OFF)

if(NOT Boost_FIND_COMPONENTS)
	message(FATAL_ERROR "No COMPONENTS specified for Boost")
endif()

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

# Create a list(string) for the build command (e.g. --with-program_options;--with-system)
# and assigns it to BOOST_COMPONENTS_FOR_BUILD
foreach(component ${Boost_FIND_COMPONENTS})
	list(APPEND BOOST_COMPONENTS_FOR_BUILD --with-${component})
endforeach()

# Create a string for the first component (e.g. boost_program_options)
# and assigns it to Boost_FIND_COMPONENTS
list(GET Boost_FIND_COMPONENTS 0 BOOST_FIRST_COMPONENT)
set(BOOST_FIRST_COMPONENT "boost_${BOOST_FIRST_COMPONENT}")

include(FindPackageHandleStandardArgs)


macro(DO_FIND_BOOST_SYSTEM)
	find_path(BOOST_INCLUDE_DIR boost/config.hpp
		PATHS /usr/local/include /usr/include
		)
	find_library(BOOST_LIBRARY
		NAMES ${BOOST_FIRST_COMPONENT}
		PATHS /usr/local/lib /usr/lib
		)


	FIND_PACKAGE_HANDLE_STANDARD_ARGS(Boost DEFAULT_MSG
		BOOST_INCLUDE_DIR BOOST_LIBRARY
		)
	set(BOOST_LIBRARIES ${BOOST_LIBRARY})
	set(BOOST_INCLUDE_DIRS ${BOOST_INCLUDE_DIR})
	mark_as_advanced(BOOST_LIBRARIES BOOST_INCLUDE_DIRS)
endmacro()

macro(DO_FIND_BOOST_ROOT)
	if(NOT BOOST_ROOT_DIR)
		message(STATUS "BOOST_ROOT_DIR is not defined, using binary directory.")
		set(BOOST_ROOT_DIR ${CURRENT_CMAKE_BINARY_DIR} CACHE PATH "")
	endif()

	find_path(BOOST_INCLUDE_DIR boost/config.hpp ${BOOST_ROOT_DIR}/include)
	message(STATUS "BOOST_INCLUDE_DIR : ${BOOST_INCLUDE_DIR}")

	find_library(BOOST_LIBRARY ${BOOST_FIRST_COMPONENT} HINTS ${BOOST_ROOT_DIR}/lib)

	set(Boost_VERSION 0)
	set(Boost_LIB_VERSION "")
	file(STRINGS "${BOOST_INCLUDE_DIR}/boost/version.hpp" _boost_VERSION_HPP_CONTENTS REGEX "#define BOOST_(LIB_)?VERSION ")
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

	if( NOT ${Boost_VERSION} EQUAL ${BOOST_REQUESTED_VERSION} )
		message(STATUS "Version mismatch. We found ${Boost_VERSION} but expected ${BOOST_REQUESTED_VERSION}")
		unset(BOOST_FOUND)
	else()
		FIND_PACKAGE_HANDLE_STANDARD_ARGS(Boost DEFAULT_MSG
		BOOST_INCLUDE_DIR BOOST_LIBRARY
		)
		set(BOOST_LIBRARIES ${BOOST_LIBRARY})
		set(BOOST_INCLUDE_DIRS ${BOOST_INCLUDE_DIR})
		mark_as_advanced(BOOST_LIBRARIES BOOST_INCLUDE_DIRS)
	endif()
endmacro()

macro(DO_FIND_BOOST_DOWNLOAD)
	if(NOT BOOST_REQUESTED_VERSION)
		message(FATAL_ERROR "BOOST_REQUESTED_VERSION is not defined.")
	endif()

	string(REPLACE "." "_" BOOST_REQUESTED_VERSION_UNDERSCORE ${BOOST_REQUESTED_VERSION})

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
		message(STATUS "Downloading boost ${BOOST_REQUESTED_VERSION}")

		set(BoostSHA256 9995e192e68528793755692917f9eb6422f3052a53c5e13ba278a228af6c7acf)
		file(DOWNLOAD https://dl.bintray.com/boostorg/release/${BOOST_REQUESTED_VERSION}/source/${BoostArchiveFile}
			${BoostExtactDir}/${BoostArchiveFile}
			STATUS Status
			SHOW_PROGRESS
			EXPECTED_HASH SHA256=${BoostSHA256}
		)
	endif()

	if(NOT EXISTS ${BoostSrcDir} )
		execute_process(COMMAND ${CMAKE_COMMAND} -E tar xfz ${BoostExtactDir}/${BoostArchiveFile}
			WORKING_DIRECTORY ${BoostExtactDir}
			RESULT_VARIABLE Result
		)
		if(NOT Result EQUAL "0")
			message(FATAL_ERROR "Failed extracting boost ${BoostArchiveFile} to ${BoostExtactDir}")
	  	endif()
	endif()

	if (WIN32)
		message(STATUS "WIN32: Boost not FOUND")
		set( Bootstrap "${BoostSrcDir}/bootstrap.bat")
	else()
		message(STATUS "UNIX Set bootstrap util to")
		set( Bootstrap "${BoostSrcDir}/bootstrap.sh")
	endif ()

	if(NOT EXISTS ${BoostSrcDir}/b2)
		execute_process(COMMAND ${Bootstrap} WORKING_DIRECTORY ${BoostSrcDir}
			RESULT_VARIABLE Result OUTPUT_VARIABLE Output ERROR_VARIABLE Error)

		if(NOT Result EQUAL "0")
			message(FATAL_ERROR "Failed running ${Bootstrap}:\n${Output}\n${Error}\n")
		endif()
	endif()	
		
	if(NOT EXISTS ${BOOST_ROOT_DIR}/include/boost)
		execute_process(COMMAND ${BoostSrcDir}/b2 --user-config=${BoostSrcDir}/project-config.jam --prefix=${BOOST_ROOT_DIR} --ignore-site-config install WORKING_DIRECTORY ${BoostSrcDir}
			RESULT_VARIABLE Result OUTPUT_VARIABLE Output ERROR_VARIABLE Error)
			
		if(NOT Result EQUAL "0")
			message(FATAL_ERROR "Failed running ${Bootstrap}:\n${Output}\n${Error}\n")
		endif()
	endif()


	# include(ExternalProject)
  	# ExternalProject_Add(
    #   boostTarget
	#   PREFIX ${BoostSrcDir}
	#   SOURCE_DIR ${BoostSrcDir}
	#   BINARY_DIR ${BoostSrcDir}
    #   CONFIGURE_COMMAND ""
    #   BUILD_COMMAND ${BoostSrcDir}/b2 --user-config=${BoostSrcDir}/project-config.jam --prefix=${BOOST_ROOT_DIR} --ignore-site-config install
    #   INSTALL_COMMAND ""
    #   LOG_BUILD ON
    # )

	# ExternalProject_Get_Property(boostTarget install_dir)
	# set(BOOST_INCLUDE_DIRS ${install_dir}/include)
	set(BOOST_INCLUDE_DIRS ${BOOST_ROOT_DIR}/include)

	macro(libraries_to_fullpath varname)
		set(${varname})
		foreach(component ${Boost_FIND_COMPONENTS})
			list(APPEND ${varname} ${BOOST_ROOT_DIR}/lib/${LIBRARY_PREFIX}boost_${component}${LIBRARY_SUFFIX})
		endforeach()
	endmacro()
	libraries_to_fullpath(BOOST_LIBRARIES)

	FIND_PACKAGE_HANDLE_STANDARD_ARGS(Boost DEFAULT_MSG
		BOOST_INCLUDE_DIRS BOOST_LIBRARIES
		)
	mark_as_advanced(BOOST_LIBRARIES BOOST_INCLUDE_DIRS)
endmacro()

if(NOT BOOST_FOUND)
	message(STATUS "DO_FIND_BOOST_ROOT")
	DO_FIND_BOOST_ROOT()
endif()

# if(NOT BOOST_FOUND)
# 	message(STATUS "DO_FIND_BOOST_SYSTEM")
# 	DO_FIND_BOOST_SYSTEM()
# endif()

if(NOT BOOST_FOUND)
	message(STATUS "DO_FIND_BOOST_DOWNLOAD")
	DO_FIND_BOOST_DOWNLOAD()
endif()






# ExternalProject_Add(
# 	linuxBoost
# 	PREFIX ${CMAKE_CURRENT_BINARY_DIR}/linuxBoost
# 	URL https://dl.bintray.com/boostorg/release/1.73.0/source/boost_1_73_0.tar.gz
# 	URL_HASH SHA256=9995e192e68528793755692917f9eb6422f3052a53c5e13ba278a228af6c7acf
# 	TIMEOUT 10
# 	CONFIGURE_COMMAND ${CMAKE_CURRENT_BINARY_DIR}/linuxBoost/src/boost_1_73_0/bootstrap.sh
# 	BUILD_COMMAND ${CMAKE_CURRENT_BINARY_DIR}/linuxBoost/src/boost_1_73_0/b2
# 	#INSTALL_DIR ${SYSROOT}
# 	INSTALL_COMMAND ${CMAKE_CURRENT_BINARY_DIR}/linuxBoost/src/boost_1_73_0/b2 -q  
# 		--user-config=${CMAKE_CURRENT_BINARY_DIR}/linuxBoost/src/boost_1_73_0/user-config.jam
# 		--prefix=${SYSROOT} # --layout=$(BOOST_LAYOUT)
# 		--ignore-site-config install
# )