PROJECT(colin2)

set( CMAKE_MODULE_PATH    ${CMAKE_MODULE_PATH}
                          ${CMAKE_CURRENT_SOURCE_DIR}
                          ${CMAKE_CURRENT_SOURCE_DIR}/cmake/modules
                          ${CMAKE_CURRENT_SOURCE_DIR}/../cmake/modules)


set(DOXYFILE_TARGET_SUFFIX colin)
include(UseDoxygen OPTIONAL)


# A statically linked binary needs the static Coin-OR libraries, so look
# for .a files before .so files when configuring a static build.
if(STATIC_COLIN)
set(CMAKE_FIND_LIBRARY_SUFFIXES ".a")
endif(STATIC_COLIN)

find_package(Clp)
find_package(CoinUtils)
find_package(Cbc)
find_package(Cgl)
find_package(OSI)


set(CMAKE_CXX_FLAGS "-std=c++11 -Wall ${CMAKE_CXX_FLAGS}")

if(CLP_LIB_PATH)
link_directories(${CLP_LIB_PATH})
endif(CLP_LIB_PATH)

if(STATIC_COLIN)
set(CMAKE_CXX_LINK_FLAGS "-static ${CMAKE_CXX_LINK_FLAGS}")
set(CMAKE_EXE_LINKER_FLAGS "-static ${CMAKE_EXE_LINKER_FLAGS}")
# Coin-OR's static libraries use LAPACK/BLAS, which in turn need the
# Fortran run-time.
set(COLIN_STATIC_EXTRA_LIBS lapack blas gfortran quadmath)
endif(STATIC_COLIN)

set(COLIN_COIN_INCLUDES)

foreach(COLIN_COIN_INCLUDE ${CLP_INCLUDES} ${CBC_INCLUDES}
                           ${COINUTILS_INCLUDES} ${CGL_INCLUDES} ${OSI_INCLUDES})
if(EXISTS "${COLIN_COIN_INCLUDE}")
list(APPEND COLIN_COIN_INCLUDES "${COLIN_COIN_INCLUDE}")
if(EXISTS "${COLIN_COIN_INCLUDE}/coin")
list(APPEND COLIN_COIN_INCLUDES "${COLIN_COIN_INCLUDE}/coin")
endif(EXISTS "${COLIN_COIN_INCLUDE}/coin")
endif(EXISTS "${COLIN_COIN_INCLUDE}")
endforeach(COLIN_COIN_INCLUDE)

list(REMOVE_DUPLICATES COLIN_COIN_INCLUDES)

include_directories(${val_SOURCE_DIR} ${val_SOURCE_DIR}/parsing
${val_BINARY_DIR} ${COLIN_COIN_INCLUDES} ${CPLEX_INCLUDES} ${CONCERT_INCLUDES}  ${GSL_INCLUDES})

set(colin_build_srcs
    compressionsafescheduler.cpp
    colintotalordertransformer.cpp
    FFSolver.cpp
    FFEvent.cpp
    globals.cpp
    lpscheduler.cpp
    RPGBuilder.cpp
    RPGBuilderAnalysis.cpp
    RPGBuilderEvaluation.cpp
    RPGBuilderNumerics.cpp
    temporalanalysis.cpp
    minimalstate.cpp
    temporalconstraints.cpp
    numericanalysis.cpp
    solver.cpp)

add_library(ColinCommon STATIC ${colin_build_srcs})
target_link_libraries(ColinCommon ParsePDDL Inst)
SET_TARGET_PROPERTIES(ColinCommon PROPERTIES COMPILE_FLAGS "-DTOTALORDERSTATES -DPOPF3ANALYSIS")

if(NOT COLIN_LIBS)
set(COLIN_LIBS
    ${CGL_LIBRARIES}
    ${CBC_LIBRARY}
    ${CBC_SOLVER_LIBRARY}
    ${CLP_LIBRARIES}
    ${COINUTILS_LIBRARIES}
    ${OSI_LIBRARIES}
    ${OSICLP_LIBRARIES})
endif(NOT COLIN_LIBS)

add_library(colin STATIC  ${colin_build_srcs} solver-clp.cpp drealMain.cpp)
SET_TARGET_PROPERTIES(colin PROPERTIES COMPILE_FLAGS
"-DTOTALORDERSTATES -DPOPF3ANALYSIS")
target_link_libraries(colin  Inst
        bz2 z stdc++ ${COLIN_LIBS} )

if(CLP_INCLUDES AND CBC_INCLUDES)

    ADD_EXECUTABLE(colin-clp colinMain.cpp)

    SET_TARGET_PROPERTIES(colin-clp PROPERTIES COMPILE_FLAGS
        "-DTOTALORDERSTATES -DPOPF3ANALYSIS")

    target_link_libraries(colin-clp
        colin
        ParsePDDL
        ${CBC_SOLVER_LIBRARY} ${CBC_LIBRARY} ${CGL_LIBRARIES}
        ${OSICLP_LIBRARIES} ${OSI_LIBRARIES} ${CLP_LIBRARIES}
        ${COINUTILS_LIBRARIES} bz2 z stdc++ ${COLIN_STATIC_EXTRA_LIBS})

endif(CLP_INCLUDES AND CBC_INCLUDES)

if(CPLEX AND ILOCPLEX AND CONCERT AND CPLEX_INCLUDES AND CONCERT_INCLUDES)

    ADD_EXECUTABLE(colin-cplex colinMain.cpp solver-cpx.cpp)

    SET_TARGET_PROPERTIES(colin-cplex PROPERTIES COMPILE_FLAGS
        "-DTOTALORDERSTATES -DPOPF3ANALYSIS")

    target_link_libraries(colin-cplex
        ColinCommon
        ${ILOCPLEX} ${CPLEX} ${CONCERT} pthread bz2 z stdc++
        ${COLIN_STATIC_EXTRA_LIBS})

endif(CPLEX AND ILOCPLEX AND CONCERT AND CPLEX_INCLUDES AND CONCERT_INCLUDES)

