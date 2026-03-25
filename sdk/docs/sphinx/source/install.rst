==============
Installation
==============

.. warning::
   **DRAFT DOCUMENTATION** - This documentation is currently in draft status and subject to change.

PTI SDK is built from source using CMake. The build process is straightforward and well-tested on Linux and Windows platforms.

For detailed installation instructions, refer to the `INSTALL.md <https://github.com/intel/pti-gpu/blob/master/sdk/INSTALL.md>`_ file in the repository.

Prerequisites
-------------

Before building PTI SDK, ensure you have:

* CMake 3.12 or higher
* Intel(R) oneAPI Base Toolkit (2024.1.1 or higher recommended)
* Level Zero Loader (version 1.16.15 or higher)
* C++17 compatible compiler

See the `INSTALL.md <https://github.com/intel/pti-gpu/blob/master/sdk/INSTALL.md>`_ file for complete prerequisites and platform-specific requirements.

Quick Installation (Linux)
---------------------------

1. Set up the oneAPI environment:

   .. code-block:: bash

      source <path_to_oneapi>/setvars.sh

2. Build and install:

   .. code-block:: bash

      cd sdk
      mkdir build
      cd build
      cmake -DCMAKE_BUILD_TYPE=Release \
            -DCMAKE_TOOLCHAIN_FILE=../cmake/toolchains/icpx_toolchain.cmake \
            -DBUILD_TESTING=OFF ..
      make -j
      cmake --install . --config Release --prefix "../out"

Quick Installation (Windows)
-----------------------------

1. Open Intel(R) oneAPI Command Prompt

2. Build and install:

   .. code-block:: batch

      cd sdk
      mkdir build
      cd build
      cmake .. -G Ninja ^
           -DCMAKE_BUILD_TYPE=Release ^
           -DCMAKE_TOOLCHAIN_FILE=../cmake/toolchains/icpx_toolchain.cmake ^
           -DCMAKE_CXX_FLAGS=/EHcs ^
           -DBUILD_TESTING=OFF
      cmake --build . --parallel 4
      cmake --install . --config Release --prefix "../out"

Verification
------------

After installation, verify the build by running a sample:

**Linux:**

.. code-block:: bash

   ./bin/vec_sqadd

**Windows:**

.. code-block:: batch

   bin\vec_sqadd.exe

If the sample runs successfully, your installation is complete.

Detailed Instructions
---------------------

For complete instructions including:

* Detailed prerequisite information
* Troubleshooting common issues
* Build configuration options
* Platform-specific considerations
* Linking PTI SDK in your application

Please refer to the `INSTALL.md <https://github.com/intel/pti-gpu/blob/master/sdk/INSTALL.md>`_ file.
