# Find Doxygen
find_package(Doxygen)

if(NOT Doxygen_FOUND)
  message(STATUS "Doxygen not found - documentation targets will not be available")
  return()
endif()

# Find Sphinx
find_program(SPHINX_BUILD sphinx-build)

if(NOT SPHINX_BUILD)
  message(STATUS "Sphinx not found - documentation targets will not be available")
  return()
endif()

# Set documentation directories
set(PTI_DOCS_SOURCE_DIR "${PROJECT_SOURCE_DIR}/docs")
set(PTI_DOXYGEN_SOURCE_DIR "${PTI_DOCS_SOURCE_DIR}/doxygen")
set(PTI_SPHINX_SOURCE_DIR "${PTI_DOCS_SOURCE_DIR}/sphinx")
set(PTI_DOCS_OUTPUT_DIR "${PROJECT_BINARY_DIR}/docs")
set(PTI_DOXYGEN_OUTPUT_DIR "${PTI_DOCS_OUTPUT_DIR}/doxygen")
set(PTI_SPHINX_OUTPUT_DIR "${PTI_DOCS_OUTPUT_DIR}/sphinx/build/html")

# Documentation output files
set(PTI_DOXYGEN_INDEX "${PTI_DOXYGEN_OUTPUT_DIR}/html/index.html")
set(PTI_SPHINX_INDEX "${PTI_SPHINX_OUTPUT_DIR}/index.html")

# Custom command to build Doxygen documentation
add_custom_command(
  OUTPUT ${PTI_DOXYGEN_INDEX}
  COMMAND ${DOXYGEN_EXECUTABLE} Doxyfile
  WORKING_DIRECTORY ${PTI_DOXYGEN_SOURCE_DIR}
  COMMENT "Generate Doxygen documentation"
  VERBATIM)

# Custom target for Doxygen
add_custom_target(
  docs_doxygen
  DEPENDS ${PTI_DOXYGEN_INDEX}
  COMMENT "Build Doxygen documentation")

# Custom command to build Sphinx documentation
add_custom_command(
  OUTPUT ${PTI_SPHINX_INDEX}
  COMMAND ${SPHINX_BUILD} -b html ${PTI_SPHINX_SOURCE_DIR}/source ${PTI_SPHINX_OUTPUT_DIR}
  WORKING_DIRECTORY ${PTI_SPHINX_SOURCE_DIR}
  DEPENDS ${PTI_DOXYGEN_INDEX}
  COMMENT "Generate Sphinx documentation"
  VERBATIM)

# Custom target for Sphinx (depends on Doxygen output file)
add_custom_target(
  docs_sphinx
  DEPENDS ${PTI_SPHINX_INDEX}
  COMMENT "Build Sphinx documentation")

# Convenience target to build all documentation
add_custom_target(
  docs
  DEPENDS docs_sphinx
  COMMENT "Build all documentation (Doxygen + Sphinx)")
