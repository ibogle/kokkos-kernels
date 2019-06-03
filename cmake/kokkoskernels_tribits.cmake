INCLUDE(CMakeParseArguments)
INCLUDE(CTest)

IF (KOKKOS_HAS_TRILINOS)
INCLUDE(TribitsETISupport)
ENDIF()

MESSAGE(STATUS "The project name is: ${PROJECT_NAME}")

MACRO(KOKKOSKERNELS_PACKAGE_POSTPROCESS)
IF (KOKKOS_HAS_TRILINOS)
  TRIBITS_PACKAGE_POSTPROCESS()
ELSE()
  INCLUDE(CMakePackageConfigHelpers)
  CONFIGURE_PACKAGE_CONFIG_FILE(cmake/KokkosKernelsConfig.cmake.in
                                "${KokkosKernels_BINARY_DIR}/KokkosKernelsConfig.cmake"
                                INSTALL_DESTINATION ${CMAKE_INSTALL_PREFIX}/lib/cmake)
  WRITE_BASIC_PACKAGE_VERSION_FILE("${KokkosKernels_BINARY_DIR}/KokkosKernelsConfigVersion.cmake"
          VERSION "${KokkosKernels_VERSION_MAJOR}.${KokkosKernels_VERSION_MINOR}.${KokkosKernels_VERSION_PATCH}"
          COMPATIBILITY SameMajorVersion)

  INSTALL(FILES
    "${KokkosKernels_BINARY_DIR}/KokkosKernelsConfig.cmake"
    "${KokkosKernels_BINARY_DIR}/KokkosKernelsConfigVersion.cmake"
    DESTINATION ${CMAKE_INSTALL_PREFIX}/lib/cmake)

  INSTALL(EXPORT ${KOKKOSKERNELS_TARGET_NAME} DESTINATION lib/cmake)
  INSTALL(EXPORT ${KOKKOSKERNELS_TARGET_NAME} DESTINATION lib/cmake/KokkosKernels)
ENDIF()
ENDMACRO(KOKKOSKERNELS_PACKAGE_POSTPROCESS)

MACRO(KOKKOSKERNELS_SUBPACKAGE NAME)
IF (KOKKOS_HAS_TRILINOS)
  TRIBITS_SUBPACKAGE(${NAME})
ELSE()
  SET(PACKAGE_SOURCE_DIR ${CMAKE_CURRENT_SOURCE_DIR})
  SET(PARENT_PACKAGE_NAME ${PACKAGE_NAME})
  SET(PACKAGE_NAME ${PACKAGE_NAME}${NAME})
  STRING(TOUPPER ${PACKAGE_NAME} PACKAGE_NAME_UC)
  SET(${PACKAGE_NAME}_SOURCE_DIR ${CMAKE_CURRENT_SOURCE_DIR})
ENDIF()
ENDMACRO(KOKKOSKERNELS_SUBPACKAGE)

MACRO(KOKKOSKERNELS_SUBPACKAGE_POSTPROCESS)
IF (KOKKOS_HAS_TRILINOS)
  TRIBITS_SUBPACKAGE_POSTPROCESS()
ELSE()
ENDIF()
ENDMACRO(KOKKOSKERNELS_SUBPACKAGE_POSTPROCESS)

MACRO(KOKKOSKERNELS_PROCESS_SUBPACKAGES)
IF (KOKKOS_HAS_TRILINOS)
  TRIBITS_PROCESS_SUBPACKAGES()
ENDIF()
ENDMACRO(KOKKOSKERNELS_PROCESS_SUBPACKAGES)

MACRO(KOKKOSKERNELS_PACKAGE)
IF (KOKKOS_HAS_TRILINOS)
  TRIBITS_PACKAGE(KokkosKernels)
ELSE()
  SET(PACKAGE_NAME KokkosKernels)
  SET(PACKAGE_SOURCE_DIR ${CMAKE_CURRENT_SOURCE_DIR})
  STRING(TOUPPER ${PACKAGE_NAME} PACKAGE_NAME_UC)
  SET(${PACKAGE_NAME}_SOURCE_DIR ${CMAKE_CURRENT_SOURCE_DIR})
ENDIF()
ENDMACRO(KOKKOSKERNELS_PACKAGE)

FUNCTION(KOKKOSKERNELS_INTERNAL_ADD_LIBRARY LIBRARY_NAME)
CMAKE_PARSE_ARGUMENTS(PARSE 
  "STATIC;SHARED"
  ""
  "HEADERS;SOURCES"
  ${ARGN})

IF(PARSE_HEADERS)
  LIST(REMOVE_DUPLICATES PARSE_HEADERS)
ENDIF()
IF(PARSE_SOURCES)
  LIST(REMOVE_DUPLICATES PARSE_SOURCES)
ENDIF()

ADD_LIBRARY(
  ${LIBRARY_NAME}
  ${PARSE_HEADERS}
  ${PARSE_SOURCES}
)

INSTALL(
  TARGETS ${LIBRARY_NAME}
  EXPORT ${PROJECT_NAME}
  RUNTIME DESTINATION bin
  LIBRARY DESTINATION lib
  ARCHIVE DESTINATION lib
  COMPONENT ${PACKAGE_NAME}
)

INSTALL(
  TARGETS ${LIBRARY_NAME}
  EXPORT ${KOKKOSKERNELS_TARGET_NAME}
  RUNTIME DESTINATION bin
  LIBRARY DESTINATION lib
  ARCHIVE DESTINATION lib
)

INSTALL(
  FILES  ${PARSE_HEADERS}
  DESTINATION include
  COMPONENT ${PACKAGE_NAME}
)

INSTALL(
  FILES  ${PARSE_HEADERS}
  DESTINATION include
)

ENDFUNCTION(KOKKOSKERNELS_INTERNAL_ADD_LIBRARY LIBRARY_NAME)

FUNCTION(KOKKOSKERNELS_ADD_LIBRARY LIBRARY_NAME)
IF (KOKKOS_HAS_TRILINOS)
  TRIBITS_ADD_LIBRARY(${LIBRARY_NAME} ${ARGN})
ELSE()
  KOKKOSKERNELS_INTERNAL_ADD_LIBRARY(
    ${LIBRARY_NAME} ${ARGN})
ENDIF()
ENDFUNCTION()

FUNCTION(KOKKOSKERNELS_ADD_EXECUTABLE EXE_NAME)
IF (KOKKOS_HAS_TRILINOS)
  TRIBITS_ADD_EXECUTABLE(${EXE_NAME} ${ARGN})
ELSE()
  CMAKE_PARSE_ARGUMENTS(PARSE 
    "TESTONLY"
    ""
    "SOURCES;TESTONLYLIBS"
    ${ARGN})

  ADD_EXECUTABLE(${EXE_NAME} ${PARSE_SOURCES})
  TARGET_LINK_LIBRARIES(${EXE_NAME} kokkoskernels)
  IF (PARSE_TESTONLYLIBS)
    TARGET_LINK_LIBRARIES(${EXE_NAME} ${PARSE_TESTONLYLIBS})
  ENDIF()
  VERIFY_EMPTY(KOKKOS_ADD_EXECUTABLE ${PARSE_UNPARSED_ARGUMENTS})
ENDIF()
ENDFUNCTION()

FUNCTION(KOKKOSKERNELS_ADD_EXECUTABLE_AND_TEST ROOT_NAME)
IF (KOKKOS_HAS_TRILINOS)
  TRIBITS_ADD_EXECUTABLE_AND_TEST(
    ${ROOT_NAME} 
    TESTONLYLIBS kokkoskernels_gtest 
    ${ARGN}
    NUM_MPI_PROCS 1
    COMM serial mpi
  )
ELSE()
  CMAKE_PARSE_ARGUMENTS(PARSE 
    ""
    ""
    "SOURCES;CATEGORIES"
    ${ARGN})
  VERIFY_EMPTY(KOKKOSKERNELS_ADD_EXECUTABLE_AND_TEST ${PARSE_UNPARSED_ARGUMENTS})
  SET(EXE_NAME ${PACKAGE_NAME}_${ROOT_NAME})
  KOKKOSKERNELS_ADD_TEST_EXECUTABLE(${EXE_NAME}
    SOURCES ${PARSE_SOURCES}
  )
  KOKKOS_ADD_TEST(NAME ${ROOT_NAME} 
    EXE ${EXE_NAME}
  )
ENDIF()
ENDFUNCTION()

MACRO(KOKKOSKERNELS_ADD_TEST_EXECUTABLE EXE_NAME)
CMAKE_PARSE_ARGUMENTS(PARSE 
  ""
  ""
  "SOURCES"
  ${ARGN})
KOKKOSKERNELS_ADD_EXECUTABLE(${EXE_NAME}
  SOURCES ${PARSE_SOURCES}
  TESTONLYLIBS kokkoskernels_gtest
  ${PARSE_UNPARSED_ARGUMENTS}
)
IF (NOT KOKKOS_HAS_TRILINOS)
  TARGET_LINK_LIBRARIES(${EXE_NAME} kokkoskernels_gtest)
ENDIF()
ADD_DEPENDENCIES(check ${EXE_NAME})
ENDMACRO(KOKKOSKERNELS_ADD_TEST_EXECUTABLE)

IF (NOT KOKKOS_HAS_TRILINOS AND KOKKOS_HAS_PARENT)
FUNCTION(TARGET_LINK_KOKKOS TARGET)
  TARGET_LINK_LIBRARIES(${TARGET} ${ARGN} kokkos)
ENDFUNCTION(TARGET_LINK_KOKKOS)
ENDIF()
