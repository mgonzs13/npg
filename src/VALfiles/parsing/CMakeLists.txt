cmake_minimum_required(VERSION 2.4)

project(ParsePDDL)

find_program(BISON_EXECUTABLE bison)

if(NOT EXISTS ${BISON_EXECUTABLE})
	message("Could not find bison executable.")
endif(NOT EXISTS ${BISON_EXECUTABLE})

# Support bison installed in a non-system prefix (e.g. the user-local
# dependencies set up by setup-deps), where the compiled-in data directory
# is not present.
if(DEFINED ENV{BISON_PKGDATADIR})
	set(BISON_COMMAND ${CMAKE_COMMAND} -E env
		"BISON_PKGDATADIR=$ENV{BISON_PKGDATADIR}" ${BISON_EXECUTABLE})
else()
	set(BISON_COMMAND ${BISON_EXECUTABLE})
endif()


FIND_PROGRAM(FLEX_EXECUTABLE flex)

if(NOT EXISTS ${FLEX_EXECUTABLE})
        message("Could not find flex executable.")
endif(NOT EXISTS ${FLEX_EXECUTABLE})

add_custom_command(
       OUTPUT
        ${CMAKE_CURRENT_BINARY_DIR}/lex.yy.cc
       COMMAND
        ${FLEX_EXECUTABLE}
       ARGS
       -+  --outfile=${CMAKE_CURRENT_BINARY_DIR}/lex.yy.cc ${CMAKE_CURRENT_SOURCE_DIR}/pddl+.lex
       DEPENDS
        ${CMAKE_CURRENT_SOURCE_DIR}/pddl+.lex
)

add_custom_command(
       OUTPUT
        ${CMAKE_CURRENT_BINARY_DIR}/pddl+.cpp
       COMMAND
        ${BISON_COMMAND}
       ARGS
        ${CMAKE_CURRENT_SOURCE_DIR}/pddl+.yacc -o ${CMAKE_CURRENT_BINARY_DIR}/pddl+.cpp
       DEPENDS
        ${CMAKE_CURRENT_SOURCE_DIR}/pddl+.yacc ${CMAKE_CURRENT_BINARY_DIR}/lex.yy.cc
       COMMAND
        ${CMAKE_CURRENT_SOURCE_DIR}/fixyywrap ${CMAKE_CURRENT_BINARY_DIR} ${CMAKE_CURRENT_SOURCE_DIR}
)

include_directories(${CMAKE_CURRENT_SOURCE_DIR} ${CMAKE_CURRENT_BINARY_DIR})

set(libParsePDDL_SRCS
      pddl+.cpp ptree.cpp DebugWriteController.cpp
)

add_library(ParsePDDL STATIC ${libParsePDDL_SRCS})

