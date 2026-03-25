===========================
Code Samples and Examples
===========================

.. warning::
   **DRAFT DOCUMENTATION** - This documentation is currently in draft status and subject to change.

PTI SDK includes a comprehensive set of samples demonstrating various tracing capabilities and use cases. All samples are located in the ``samples/`` directory.

Overview
--------

The samples are organized by functionality and complexity, from basic tracing to advanced features like metrics collection and multi-threading.

Basic Tracing Samples
----------------------

These samples demonstrate fundamental PTI SDK capabilities:

**vector_sq_add**
   Simple vector square-add operation using SYCL. Demonstrates basic kernel tracing with PTI SDK.

   - Traces GPU kernel execution
   - Shows memory copy operations
   - Basic callback implementation
   - Good starting point for new users

**dpc_gemm**
   DPC++ General Matrix Multiply (GEMM) operation with performance tracking.

   - Matrix multiplication kernel tracing
   - Performance data collection
   - Demonstrates real computational workload

**onemkl_gemm**
   GEMM using Intel(R) oneMKL library calls.

   - Traces library function calls
   - Shows integration with Intel optimized libraries
   - Demonstrates tracing of higher-level APIs

Advanced Tracing Samples
-------------------------

These samples showcase more sophisticated PTI SDK features:

**callback** (*Demonstrates experimental Callback API*)
   Advanced callback usage demonstrating the PTI Callback API for real-time GPU operation notifications.

   - **Location:** ``samples/callback/``
   - **Key Features:**
      - PTI Callback API subscriber initialization
      - Real-time callbacks for GPU operations (appended and completed)
      - External correlation ID injection within callbacks
      - Integration of Callback API with View API
      - API filtering to reduce tracing overhead
      - Instance user data passing between callback phases
   - **Use Cases:**
      - Understanding Callback API workflow
      - Building custom correlation systems
      - Real-time GPU operation monitoring
      - Learning advanced PTI features
   - **Running:**

   .. code-block:: bash

      cd build
      ./bin/callback

   **What You'll Learn:**

   - How to subscribe to callback domains and receive synchronous notifications
   - Pushing and popping external correlation IDs in callbacks
   - Processing ``pti_callback_gpu_op_data`` structures
   - Combining Callback API with View API for complete profiling
   - When to use Callback API vs View API

   .. warning::
      The Callback API is experimental and subject to change. See :doc:`callback_api` for complete documentation.

**dpc_gemm_threaded**
   Multi-threaded DPC++ GEMM demonstrating thread-safe tracing.

   - Multi-threaded application tracing
   - Thread-safety considerations
   - Concurrent queue management

**dlworkloads**
   Deep learning workload tracing examples.

   - Real-world AI/ML workload patterns
   - Complex kernel sequences
   - Performance analysis

Metrics Collection Samples
---------------------------

PTI SDK provides powerful hardware metrics collection capabilities through two complementary APIs: Metrics Scope API (per-kernel metrics) and Metrics API (device-level sampling). The following samples demonstrate various aspects of metrics collection.

**metrics_scope** (*Recommended starting point*)
   Per-kernel hardware metrics collection using Metrics Scope API.

   - **Location:** ``samples/metrics_scope/``
   - **Key Features:**
      - Automatic metrics collection for individual GPU kernels
      - Demonstrates complete Metrics Scope API workflow
      - Shows buffer management and data processing
      - Correlates metrics with kernel names and IDs
   - **Use Cases:**
      - Understanding per-kernel performance characteristics
      - Identifying memory-bound vs compute-bound kernels
      - Analyzing cache hit rates for specific kernels
      - Comparing performance across kernel invocations
   - **Running:**

   .. code-block:: bash

      cd build
      ./bin/metrics_scope

   **What You'll Learn:**

   - How to configure specific metrics to collect (GpuTime, EuActive, MemoryBandwidth, etc.)
   - Processing collection buffers and extracting per-kernel metric values
   - Interpreting hardware performance counters
   - Integrating metrics collection with your profiling workflows

**metrics_perf**
   Performance metrics gathering using device-level Metrics API.

   - **Location:** ``samples/metrics_perf/``
   - **Key Features:**
      - Time-based metrics sampling
      - Device and metric group enumeration
      - Continuous collection across application runtime
      - Demonstrates start/stop/pause/resume collection patterns
   - **Use Cases:**
      - System-level performance monitoring
      - Understanding overall GPU behavior
      - Time-series analysis of GPU utilization
      - Steady-state performance characterization
   - **Running:**

   .. code-block:: bash

      cd build
      ./bin/metrics_perf

   **What You'll Learn:**

   - Discovering available devices and metric groups
   - Configuring time-based sampling intervals
   - Retrieving and processing calculated metrics data
   - Working with different metric value types (uint64, float64, etc.)

**metrics_iso3dfd_dpcpp**
   Hardware metrics in a realistic computational workload (ISO3DFD stencil computation).

   - **Location:** ``samples/metrics_iso3dfd_dpcpp/``
   - **Key Features:**
      - Metrics collection in production-quality workload
      - Integration with complex SYCL kernels
      - Performance analysis of stencil computation patterns
      - Demonstrates real-world profiling scenarios
   - **Use Cases:**
      - Profiling scientific computing applications
      - Understanding performance of structured grid computations
      - Optimizing memory access patterns
   - **Running:**

   .. code-block:: bash

      cd build
      ./bin/metrics_iso3dfd_dpcpp

For detailed API documentation and usage patterns, see :doc:`metrics_guide` and :doc:`metrics_api_ref`.

Additional Samples
------------------

**iso3dfd_dpcpp**
   3D finite difference operation (ISO3DFD benchmark).

   - Production-quality kernel tracing
   - Demonstrates realistic workload profiling
   - Stencil computation pattern

**omp_vec_add**
   OpenMP vector addition with GPU offload tracing.

   - OpenMP offload model support
   - Hybrid CPU-GPU tracing
   - Alternative programming model

**itt_ccl**
   Communication tracing for oneCCL (oneAPI Collective Communications Library) operations.

   - **Location:** ``samples/itt_ccl/``
   - **Platform:** Linux only
   - **Key Features:**
      - Traces oneCCL collective operations (allreduce, broadcast, etc.)
      - Uses Intel® ITT (Instrumentation and Tracing Technology) API
      - Demonstrates ``PTI_VIEW_COMMUNICATION`` view type
      - SYCL + oneCCL integration example
   - **Use Cases:**
      - Profiling distributed machine learning training
      - Analyzing communication overhead in multi-GPU applications
      - Understanding collective communication patterns
      - Correlating computation and communication phases
   - **Running:**

   .. code-block:: bash

      cd build
      # Requires oneCCL to be installed
      ./bin/itt_ccl

   **What You'll Learn:**

   - How to enable communication tracing with ``PTI_VIEW_COMMUNICATION``
   - Processing ``pti_view_record_comms`` records
   - Timing collective operations in distributed workloads
   - Identifying communication bottlenecks

   See :doc:`communication_tracing` for complete documentation.

Building and Running Samples
-----------------------------

All samples are built automatically with PTI SDK.

**Building:**

From the SDK root directory:

.. code-block:: bash

   cd sdk
   mkdir build
   cd build
   cmake -DCMAKE_BUILD_TYPE=Release \
         -DCMAKE_TOOLCHAIN_FILE=../cmake/toolchains/icpx_toolchain.cmake ..
   make -j

**Running on Linux:**

From the ``build`` directory:

.. code-block:: bash

   # Basic samples
   ./bin/vec_sqadd
   ./bin/dpc_gemm
   ./bin/onemkl_gemm

   # Advanced samples
   ./bin/callback
   ./bin/dpc_gemm_threaded

   # Metrics samples
   ./bin/metrics_scope
   ./bin/metrics_perf

**Running on Windows:**

From the ``build`` directory:

.. code-block:: batch

   REM Basic samples
   bin\vec_sqadd.exe
   bin\dpc_gemm.exe
   bin\onemkl_gemm.exe

   REM Advanced samples
   bin\callback.exe
   bin\dpc_gemm_threaded.exe

Sample Output
-------------

Each sample produces output showing:

- GPU device information
- Kernel execution traces
- Memory operation traces
- Timing and performance data
- Runtime API calls (if enabled)

Example output from ``vec_sqadd``:

.. code-block:: text

   Device: Intel(R) Data Center GPU Max 1550
   >>>> Kernel: VecSq
        Start: 123456789 ns
        End:   123456890 ns
        Duration: 101 ns
   >>>> Memory Copy: Host->Device
        Size: 20000 bytes
        Duration: 234 ns

Using Samples as Templates
---------------------------

The samples serve as templates for your own profiling tools:

1. **Start with vector_sq_add** for basic tracing patterns
2. **Study callback sample** for advanced callback techniques
3. **Examine dpc_gemm_threaded** for multi-threaded applications
4. **Use metrics samples** when hardware counters are needed

Each sample includes:

- Complete source code with comments
- CMakeLists.txt for building
- Example output
- Key concepts demonstrated

Source Code Location
--------------------

All sample source code is available in the repository:

- Local: ``sdk/samples/``
- GitHub: https://github.com/intel/pti-gpu/tree/master/sdk/samples

.. tip::
   You can also refer to the `oneAPI Samples Catalog <https://oneapi-src.github.io/oneAPI-samples/>`_ to learn more about the oneAPI ecosystem and find additional examples of GPU programming and profiling.

Next Steps
----------

After exploring the samples:

1. Review the :doc:`devguide` for detailed tracing API usage patterns
2. Read the :doc:`metrics_guide` for hardware metrics collection workflows
3. Check the :doc:`view_api_ref` for complete tracing API documentation
4. See :doc:`metrics_api_ref` for complete metrics API documentation
5. Modify samples to experiment with different profiling configurations
6. Build your own profiling tools using samples as templates
