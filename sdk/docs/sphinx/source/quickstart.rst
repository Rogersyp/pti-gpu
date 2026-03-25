=============
Quick Start
=============

.. warning::
   **DRAFT DOCUMENTATION** - This documentation is currently in draft status and subject to change.

This guide will help you get started with PTI SDK. By the end, you'll be able to trace GPU kernels and understand the basic API workflow.

Prerequisites
-------------

Before starting, ensure PTI SDK is installed. See :doc:`install` for installation instructions.

Environment Setup
-----------------

Set up the Intel(R) oneAPI environment:

**Linux:**

.. code-block:: bash

   source <path_to_oneapi>/setvars.sh

**Windows:**

Open the Intel(R) oneAPI Command Prompt.

Basic Usage Pattern
-------------------

The PTI SDK API follows a simple pattern:

1. **Define callbacks** to handle profiling data
2. **Register callbacks** with ``ptiViewSetCallbacks()``
3. **Enable tracing** with ``ptiViewEnable()``
4. **Run your application**
5. **Disable tracing** with ``ptiViewDisable()``

Running Your First Sample
--------------------------

Let's run the vector square-add sample to see PTI SDK in action.

**Step 1: Navigate to the build directory**

.. code-block:: bash

   cd build

**Step 2: Run the sample**

**Linux:**

.. code-block:: bash

   ./bin/vec_sqadd

**Windows:**

.. code-block:: batch

   bin\vec_sqadd.exe

Understanding the Output
------------------------

The sample will display:

1. **Device Information**: GPU device being used
2. **Kernel Traces**: Information about GPU kernels executed
3. **Memory Operations**: Data transfers between host and device
4. **Timing Information**: Timestamps and durations

Example output:

.. code-block:: text

   >>>> [123456789] zeKernelCreate: zeKernel = 0xdeadbeef
   >>>> [123456790] zeCommandListAppendLaunchKernel
   Kernel: VecSq, Duration: 1234 ns
   >>>> [123456800] zeCommandListAppendMemoryCopy
   Memory Copy: Host->Device, Size: 20000 bytes, Duration: 567 ns

Basic API Example
-----------------

Here's a minimal example showing the PTI SDK API usage:

.. code-block:: c++

   #include "pti/pti_view.h"
   #include <iostream>

   // Callback to allocate buffer
   void BufferRequested(unsigned char** buf, size_t* buf_size) {
       *buf_size = 1024 * 1024;  // 1 MB
       *buf = new unsigned char[*buf_size];
   }

   // Callback to process collected data
   void BufferCompleted(unsigned char* buf, size_t buf_size, size_t valid_buf_size) {
       if (!buf || !valid_buf_size) return;

       pti_view_record_base* ptr = reinterpret_cast<pti_view_record_base*>(buf);
       while (ptr < reinterpret_cast<pti_view_record_base*>(buf + valid_buf_size)) {
           if (ptr->_view_kind == PTI_VIEW_DEVICE_GPU_KERNEL) {
               auto* kernel = reinterpret_cast<pti_view_record_kernel*>(ptr);
               std::cout << "Kernel: " << kernel->_name
                         << ", Duration: " << (kernel->_end_timestamp - kernel->_start_timestamp)
                         << " ns" << std::endl;
           }
           ptr = reinterpret_cast<pti_view_record_base*>(
               reinterpret_cast<unsigned char*>(ptr) + ptr->_view_record_size);
       }
       delete[] buf;
   }

   int main() {
       // 1. Set up callbacks
       ptiViewSetCallbacks(BufferRequested, BufferCompleted);

       // 2. Enable tracing for kernels
       ptiViewEnable(PTI_VIEW_DEVICE_GPU_KERNEL);

       // 3. Run your SYCL/Level-Zero application
       // ... your GPU workload here ...

       // 4. Disable tracing
       ptiViewDisable(PTI_VIEW_DEVICE_GPU_KERNEL);

       return 0;
   }

Available Tracing Views
-----------------------

PTI SDK supports tracing different types of activities:

* ``PTI_VIEW_DEVICE_GPU_KERNEL`` - GPU kernel execution
* ``PTI_VIEW_DEVICE_GPU_MEM_COPY`` - Memory copy operations
* ``PTI_VIEW_DEVICE_GPU_MEM_FILL`` - Memory fill operations
* ``PTI_VIEW_RUNTIME_API`` - Runtime API calls (SYCL/Level-Zero)
* ``PTI_VIEW_EXTERNAL_CORRELATION`` - Application-level correlation IDs

You can enable multiple views simultaneously:

.. code-block:: c++

   ptiViewEnable(PTI_VIEW_DEVICE_GPU_KERNEL);
   ptiViewEnable(PTI_VIEW_DEVICE_GPU_MEM_COPY);
   ptiViewEnable(PTI_VIEW_RUNTIME_API);

Running Tests
-------------

To verify your PTI SDK installation, run the test suite:

**Linux:**

.. code-block:: bash

   cd build
   make test

Or with CTest for detailed output:

.. code-block:: bash

   ctest --output-on-failure

**Windows:**

.. code-block:: batch

   cd build
   ninja test

Or with CTest:

.. code-block:: batch

   ctest --output-on-failure

Local Collection
----------------

PTI SDK supports **local collection** for zero-overhead profiling:

.. code-block:: c++

   // Application initialization
   setup_callbacks();

   // No overhead here - tracing is not enabled
   some_work();

   // Start tracing - this is where collection begins
   ptiViewEnable(PTI_VIEW_DEVICE_GPU_KERNEL);

   // Trace this section
   important_work();

   // Stop tracing - zero overhead resumes
   ptiViewDisable(PTI_VIEW_DEVICE_GPU_KERNEL);

   // No overhead here again
   more_work();

With Level-Zero 1.9.0+, the overhead is **truly zero** outside the enabled regions.

Next Steps
----------

Now that you've run your first sample, explore more:

1. **Examine the samples** in ``samples/`` directory:

   * ``vector_sq_add`` - Basic tracing
   * ``dpc_gemm`` - GEMM with performance tracking
   * ``callback`` - Advanced callback usage
   * ``metrics_scope`` - Hardware metrics collection

2. **Read the Developer Guide** (:doc:`devguide`) for:

   * Callback implementation patterns
   * Threading considerations
   * External correlation IDs
   * Performance optimization

3. **Check the API Reference** (:doc:`view_api_ref`) for:

   * Complete API documentation
   * Function signatures
   * Data structure definitions

4. **Browse sample code** at ``samples/`` for real-world usage patterns

Troubleshooting
---------------

**No output from sample:**
   - Ensure oneAPI environment is set up (``setvars.sh``)
   - Verify GPU drivers are installed
   - Check that Level-Zero loader is available

**Callbacks not called:**
   - Ensure ``ptiViewSetCallbacks()`` is called **before** ``ptiViewEnable()``
   - Verify callbacks are properly registered
   - Check that you're enabling the correct view types

**Build errors:**
   - See the :doc:`install` guide for build requirements
   - Ensure C++17 support is available

**Performance issues:**
   - Use local collection (``ptiViewEnable``/``ptiViewDisable``) to reduce overhead
   - Consider reducing callback complexity
   - Profile only regions of interest

For more help, see the `GitHub repository <https://github.com/intel/pti-gpu>`_ or submit an issue.

   

