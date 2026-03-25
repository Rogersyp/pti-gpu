Developer's Guide
###################

.. warning::
   **DRAFT DOCUMENTATION** - This documentation is currently in draft status and subject to change.

This guide explains how to use the PTI SDK API to build profiling tools for GPU applications. It covers the core concepts, API workflow, and best practices for integrating PTI into your applications.

Overview
========

The PTI SDK provides a high-level C API for tracing GPU activities in SYCL and Level-Zero applications. The API abstracts low-level runtime details and provides a consistent interface for collecting profiling data.

Core Concepts
=============

View Types
----------

PTI organizes tracing capabilities into **views**. Each view represents a category of GPU activity:

``PTI_VIEW_DEVICE_GPU_KERNEL``
   Traces GPU kernel execution. Provides kernel name, execution times, and device information.

``PTI_VIEW_DEVICE_GPU_MEM_COPY``
   Traces memory copy operations between host and device. Includes transfer size, direction, and timing.

``PTI_VIEW_DEVICE_GPU_MEM_FILL``
   Traces memory fill operations. Provides pattern, size, and timing information.

``PTI_VIEW_DEVICE_GPU_MEM_COPY_P2P``
   Traces peer-to-peer memory copy operations between GPU devices. Includes source/destination device information, transfer size, and timing.

``PTI_VIEW_DEVICE_SYNCHRONIZATION``
   Traces synchronization operations including barriers, fences, and event waits. Captures both GPU barrier operations and host synchronization API calls with timing information.

``PTI_VIEW_DRIVER_API``
   Traces low-level driver API calls (Level-Zero, OpenCL). Shows driver function names, parameters, and execution times. Useful for understanding runtime behavior and overhead.

``PTI_VIEW_RUNTIME_API``
   Traces runtime API calls (SYCL). Shows API function names, parameters, and execution times.

``PTI_VIEW_COLLECTION_OVERHEAD``
   Traces PTI's own collection overhead. Measures the performance impact of profiling itself, helping you understand and minimize instrumentation costs.

``PTI_VIEW_EXTERNAL_CORRELATION``
   Enables application-level correlation. Associates application events with GPU activities.

You enable views independently based on your profiling needs. Multiple views can be active simultaneously.

Callbacks
---------

PTI uses **callbacks** to deliver profiling data to your application. When a traced event completes, PTI invokes the corresponding callback with event details.

Available callbacks:

* ``buffer_requested`` - Called when PTI needs a buffer for storing records
* ``buffer_completed`` - Called when a buffer is full and ready for processing

Each view type has associated record structures passed to callbacks:

* Kernel view → ``pti_view_record_kernel``
* Memory copy → ``pti_view_record_memory_copy``
* Memory fill → ``pti_view_record_memory_fill``
* P2P memory copy → ``pti_view_record_memory_copy_p2p``
* Synchronization → ``pti_view_record_synchronization``
* API calls → ``pti_view_record_api``
* Collection overhead → ``pti_view_record_overhead``
* External correlation → ``pti_view_record_external_correlation``
* Communication (oneCCL) → ``pti_view_record_comms``

Local Collection
----------------

**Local collection** enables zero-overhead profiling by starting and stopping tracing on demand:

* Outside ``ptiViewEnable()``/``ptiViewDisable()`` regions: **zero overhead**
* Inside enabled regions: full tracing with minimal overhead

On systems with Level-Zero 1.9.0+, overhead is truly zero outside enabled regions. On older systems, some overhead remains but data collection occurs only within enabled regions.

Basic Workflow
==============

The typical PTI SDK usage follows this pattern:

1. **Define callback functions** to process profiling data
2. **Register callbacks** with ``ptiViewSetCallbacks()``
3. **Enable views** with ``ptiViewEnable()``
4. **Run your application** - GPU activities are traced
5. **Disable views** with ``ptiViewDisable()``
6. **Process collected data** in callbacks

Minimal Example
---------------

Here's a complete minimal example:

.. code-block:: c++

   #include "pti/pti_view.h"
   #include <iostream>
   #include <vector>

   // Global storage for collected data
   std::vector<pti_view_record_kernel> kernel_records;

   // Buffer management callbacks
   void BufferRequested(unsigned char** buf, size_t* buf_size) {
       *buf_size = 1024 * 1024;  // 1 MB buffer
       *buf = new unsigned char[*buf_size];
   }

   void BufferCompleted(unsigned char* buf, size_t buf_size,
                        size_t valid_buf_size) {
       // Process records in buffer
       if (!buf || !valid_buf_size) return;

       pti_view_record_base* ptr =
           reinterpret_cast<pti_view_record_base*>(buf);

       while (ptr < reinterpret_cast<pti_view_record_base*>(
                        buf + valid_buf_size)) {

           if (ptr->_view_kind == PTI_VIEW_DEVICE_GPU_KERNEL) {
               auto* kernel = reinterpret_cast<pti_view_record_kernel*>(ptr);
               kernel_records.push_back(*kernel);

               std::cout << "Kernel: " << kernel->name
                        << ", Duration: "
                        << (kernel->end_timestamp - kernel->start_timestamp)
                        << " ns" << std::endl;
           }

           ptr = reinterpret_cast<pti_view_record_base*>(
               reinterpret_cast<unsigned char*>(ptr) + ptr->_view_record_size);
       }

       delete[] buf;
   }

   int main() {
       // 1. Set up callbacks
       pti_result result = ptiViewSetCallbacks(BufferRequested, BufferCompleted);
       if (result != PTI_SUCCESS) {
           std::cerr << "Failed to set callbacks" << std::endl;
           return 1;
       }

       // 2. Enable tracing
       ptiViewEnable(PTI_VIEW_DEVICE_GPU_KERNEL);

       // 3. Run your GPU application
       // ... your SYCL/Level-Zero code here ...

       // 4. Disable tracing
       ptiViewDisable(PTI_VIEW_DEVICE_GPU_KERNEL);

       // 5. Print summary
       std::cout << "Total kernels traced: "
                 << kernel_records.size() << std::endl;

       return 0;
   }

API Usage Patterns
==================

Setting Up Callbacks
--------------------

Callbacks must be registered **before** enabling any views:

.. code-block:: c++

   // Set callbacks before enabling views
   ptiViewSetCallbacks(MyBufferRequested, MyBufferCompleted);

   // Now safe to enable views
   ptiViewEnable(PTI_VIEW_DEVICE_GPU_KERNEL);

Callback functions should be thread-safe if your application uses multiple threads.

Enabling and Disabling Views
-----------------------------

Views are enabled and disabled independently:

.. code-block:: c++

   // Enable multiple views
   ptiViewEnable(PTI_VIEW_DEVICE_GPU_KERNEL);
   ptiViewEnable(PTI_VIEW_DEVICE_GPU_MEM_COPY);
   ptiViewEnable(PTI_VIEW_RUNTIME_API);

   // Run traced code
   RunMyApplication();

   // Disable in reverse order (recommended)
   ptiViewDisable(PTI_VIEW_RUNTIME_API);
   ptiViewDisable(PTI_VIEW_DEVICE_GPU_MEM_COPY);
   ptiViewDisable(PTI_VIEW_DEVICE_GPU_KERNEL);

**Nested Enable/Disable:**

PTI tracks enable/disable calls per view. Views remain enabled until all corresponding ``ptiViewDisable()`` calls complete:

.. code-block:: c++

   ptiViewEnable(PTI_VIEW_DEVICE_GPU_KERNEL);  // Enable count: 1
   ptiViewEnable(PTI_VIEW_DEVICE_GPU_KERNEL);  // Enable count: 2

   ptiViewDisable(PTI_VIEW_DEVICE_GPU_KERNEL); // Enable count: 1 (still enabled)
   ptiViewDisable(PTI_VIEW_DEVICE_GPU_KERNEL); // Enable count: 0 (now disabled)

Processing Records in Callbacks
--------------------------------

The ``buffer_completed`` callback receives a buffer containing multiple records. Iterate through records carefully:

.. code-block:: c++

   void BufferCompleted(unsigned char* buf, size_t buf_size,
                        size_t valid_buf_size) {
       if (!buf || !valid_buf_size) return;

       pti_view_record_base* ptr =
           reinterpret_cast<pti_view_record_base*>(buf);

       while (ptr < reinterpret_cast<pti_view_record_base*>(
                        buf + valid_buf_size)) {

           // Check view kind
           switch (ptr->_view_kind) {
               case PTI_VIEW_DEVICE_GPU_KERNEL: {
                   auto* kernel = reinterpret_cast<pti_view_record_kernel*>(ptr);
                   ProcessKernel(kernel);
                   break;
               }
               case PTI_VIEW_DEVICE_GPU_MEM_COPY: {
                   auto* memcpy = reinterpret_cast<pti_view_record_memory_copy*>(ptr);
                   ProcessMemCopy(memcpy);
                   break;
               }
               // Handle other view kinds...
           }

           // Advance to next record
           ptr = reinterpret_cast<pti_view_record_base*>(
               reinterpret_cast<unsigned char*>(ptr) + ptr->_view_record_size);
       }

       delete[] buf;  // Free buffer when done
   }

Always check ``_view_kind`` before casting to specific record types.

External Correlation IDs
-------------------------

**External correlation IDs** associate application-level operations with GPU activities:

.. code-block:: c++

   // Enable external correlation view
   ptiViewEnable(PTI_VIEW_EXTERNAL_CORRELATION);

   // Push correlation ID before operation
   uint64_t my_operation_id = 12345;
   ptiViewPushExternalCorrelationId(
       PTI_VIEW_EXTERNAL_LEVEL_0, my_operation_id);

   // Perform GPU work
   MyGPUOperation();

   // Pop correlation ID after operation
   ptiViewPopExternalCorrelationId(
       PTI_VIEW_EXTERNAL_LEVEL_0, &my_operation_id);

GPU records created between push/pop will have the ``external_id`` field set to ``my_operation_id``.

Use cases:

* Correlating GPU kernels with application functions
* Tracking request IDs through the system
* Associating performance data with user operations

Threading Considerations
========================

Thread Safety
-------------

The PTI API is thread-safe. Multiple threads can enable/disable views and perform GPU operations concurrently.

Callback Invocation
-------------------

Callbacks may be invoked from **any thread**, not necessarily the thread that enabled tracing. Ensure callback implementations are thread-safe:

.. code-block:: c++

   std::mutex data_mutex;
   std::vector<pti_view_record_kernel> shared_data;

   void ThreadSafeCallback(unsigned char* buf, size_t buf_size,
                           size_t valid_buf_size) {
       // Process buffer...

       std::lock_guard<std::mutex> lock(data_mutex);
       // Update shared data safely
       shared_data.push_back(record);
   }

Multi-Threaded Applications
----------------------------

PTI handles multi-threaded applications transparently. Each thread's GPU submissions are traced:

.. code-block:: c++

   ptiViewEnable(PTI_VIEW_DEVICE_GPU_KERNEL);

   // Launch multiple threads performing GPU work
   std::vector<std::thread> threads;
   for (int i = 0; i < 4; ++i) {
       threads.emplace_back([]() {
           // Each thread submits GPU work
           sycl::queue q;
           q.submit(/* kernel */);
       });
   }

   for (auto& t : threads) t.join();

   ptiViewDisable(PTI_VIEW_DEVICE_GPU_KERNEL);

All kernel submissions from all threads are traced.

Performance Overhead
====================

Understanding Overhead
----------------------

PTI SDK introduces minimal overhead:

* **With Local Collection (Level-Zero 1.9.0+):** Zero overhead outside enabled regions
* **Without Local Collection:** Small overhead throughout application lifetime
* **Inside enabled regions:** 5-15% overhead depending on kernel launch frequency

Minimizing Overhead
-------------------

**1. Use Local Collection:**

Only enable tracing for regions of interest:

.. code-block:: c++

   // No overhead here
   Initialization();

   ptiViewEnable(PTI_VIEW_DEVICE_GPU_KERNEL);
   CriticalSection();  // Trace this
   ptiViewDisable(PTI_VIEW_DEVICE_GPU_KERNEL);

   // No overhead here
   Cleanup();

**2. Selective View Enabling:**

Enable only necessary views:

.. code-block:: c++

   // Instead of enabling everything:
   // ptiViewEnable(PTI_VIEW_DEVICE_GPU_KERNEL);
   // ptiViewEnable(PTI_VIEW_DEVICE_GPU_MEM_COPY);
   // ptiViewEnable(PTI_VIEW_RUNTIME_API);

   // Enable only what you need:
   ptiViewEnable(PTI_VIEW_DEVICE_GPU_KERNEL);  // Just kernels

**3. Efficient Callback Implementation:**

Keep callbacks fast and defer expensive processing:

.. code-block:: c++

   std::queue<RecordBuffer> processing_queue;
   std::mutex queue_mutex;

   void BufferCompleted(unsigned char* buf, size_t buf_size,
                        size_t valid_buf_size) {
       // Quick: just queue the buffer
       std::lock_guard<std::mutex> lock(queue_mutex);
       processing_queue.push({buf, valid_buf_size});
   }

   // Process buffers in separate thread
   void ProcessingThread() {
       while (running) {
           RecordBuffer buffer;
           {
               std::lock_guard<std::mutex> lock(queue_mutex);
               if (processing_queue.empty()) continue;
               buffer = processing_queue.front();
               processing_queue.pop();
           }

           // Expensive processing here
           AnalyzeRecords(buffer);
       }
   }

**4. Buffer Sizing:**

Use appropriately sized buffers to reduce callback frequency:

.. code-block:: c++

   void BufferRequested(unsigned char** buf, size_t* buf_size) {
       // Larger buffers reduce callback frequency
       *buf_size = 4 * 1024 * 1024;  // 4 MB
       *buf = new unsigned char[*buf_size];
   }

Checking Local Collection Support
----------------------------------

Check if zero-overhead local collection is available:

.. code-block:: c++

   if (ptiViewGPULocalAvailable() == PTI_SUCCESS) {
       std::cout << "Local collection available - zero overhead!" << std::endl;
   } else {
       std::cout << "Local collection not available - minimal overhead" << std::endl;
   }

Advanced Topics
===============

Custom Timestamps
-----------------

Provide your own timestamp source:

.. code-block:: c++

   uint64_t MyTimestampCallback() {
       // Return custom timestamp
       return std::chrono::steady_clock::now().time_since_epoch().count();
   }

   ptiViewSetTimestampCallback(MyTimestampCallback);

Useful for synchronizing PTI timestamps with other profiling tools.

Flushing Views
--------------

Force PTI to flush all pending records:

.. code-block:: c++

   ptiFlushAllViews();

Useful before critical synchronization points or when you need immediate access to recent data.

Getting Current Timestamp
--------------------------

Get PTI's current timestamp:

.. code-block:: c++

   uint64_t timestamp = ptiViewGetTimestamp();

Useful for correlating application events with PTI timestamps.

Fine-Grained API Filtering
---------------------------

When ``PTI_VIEW_DRIVER_API`` or ``PTI_VIEW_RUNTIME_API`` is enabled, you can selectively enable or disable specific APIs to reduce tracing overhead and focus on relevant operations.

**API Group and Class Overview:**

PTI organizes APIs into:

* **API Groups** (``pti_api_group_id``): Level-Zero, OpenCL, SYCL
* **API Classes** (``pti_api_class``): Categorizes APIs by purpose

  - ``PTI_API_CLASS_GPU_OPERATION_CORE`` - Memory and kernel operations that submit work to GPU
  - ``PTI_API_CLASS_HOST_OPERATION_SYNCHRONIZATION`` - Host synchronization operations
  - ``PTI_API_CLASS_ALL`` - All API classes (use with caution)

**Filtering by API Class (Coarse-Grain):**

Enable or disable entire categories of APIs:

.. code-block:: c++

   // Enable driver API tracing
   ptiViewEnable(PTI_VIEW_DRIVER_API);

   // Only trace GPU core operations (kernels, memcpy)
   ptiViewEnableDriverApiClass(1,  // enable
                              PTI_API_CLASS_GPU_OPERATION_CORE,
                              PTI_API_GROUP_LEVELZERO);

   // Disable synchronization APIs
   ptiViewEnableDriverApiClass(0,  // disable
                              PTI_API_CLASS_HOST_OPERATION_SYNCHRONIZATION,
                              PTI_API_GROUP_LEVELZERO);

   // Run workload - only GPU operations traced
   run_kernels();

**Filtering by Individual API (Fine-Grain):**

Enable or disable specific API functions:

.. code-block:: c++

   #include "pti/pti_driver_levelzero_api_ids.h"

   // Enable driver API tracing
   ptiViewEnable(PTI_VIEW_DRIVER_API);

   // Enable only zeCommandListAppendLaunchKernel
   ptiViewEnableDriverApi(1,  // enable
                         PTI_API_GROUP_LEVELZERO,
                         zeCommandListAppendLaunchKernel_id);

   // Disable zeCommandListAppendMemoryCopy
   ptiViewEnableDriverApi(0,  // disable
                         PTI_API_GROUP_LEVELZERO,
                         zeCommandListAppendMemoryCopy_id);

**Runtime API Filtering:**

Similarly filter SYCL runtime APIs:

.. code-block:: c++

   #include "pti/pti_runtime_sycl_api_ids.h"

   // Enable runtime API tracing
   ptiViewEnable(PTI_VIEW_RUNTIME_API);

   // Only trace queue submit operations
   ptiViewEnableRuntimeApiClass(1,
                               PTI_API_CLASS_GPU_OPERATION_CORE,
                               PTI_API_GROUP_SYCL);

**Retrieving API Names:**

Get human-readable names for API IDs found in records:

.. code-block:: c++

   void ProcessApiRecord(pti_view_record_api* rec) {
       const char* api_name = nullptr;

       pti_result result = ptiViewGetApiIdName(rec->_api_group_id,
                                              rec->_api_id,
                                              &api_name);

       if (result == PTI_SUCCESS && api_name) {
           std::cout << "API: " << api_name << std::endl;
       }
   }

**Use Cases:**

* **Reduce overhead** - Trace only APIs of interest
* **Focus analysis** - Filter out noise from synchronization calls
* **Debug specific paths** - Enable only APIs in problematic code sections
* **Performance tuning** - Isolate kernel launch vs memory transfer APIs

.. note::
   API filtering only affects ``PTI_VIEW_DRIVER_API`` and ``PTI_VIEW_RUNTIME_API`` views. Other views (kernels, memory operations) are unaffected.

.. tip::
   Use API filtering in combination with local collection (``ptiViewEnable/Disable``) for maximum control over profiling scope and overhead.

API ID Headers
--------------

PTI provides header files that define enumerations mapping API function names to their integer IDs. These IDs appear in ``pti_view_record_api`` records and are used with API filtering functions.

**Available Headers:**

* ``pti/pti_driver_levelzero_api_ids.h`` - Level-Zero driver API identifiers
* ``pti/pti_runtime_sycl_api_ids.h`` - SYCL runtime (Unified Runtime) API identifiers

**Using Level-Zero API IDs:**

.. code-block:: c++

   #include "pti/pti_driver_levelzero_api_ids.h"
   #include "pti/pti_view.h"

   // Enable tracing of specific Level-Zero APIs
   ptiViewEnable(PTI_VIEW_DRIVER_API);

   // Filter to only trace kernel launch
   ptiViewEnableDriverApi(1,
                         PTI_API_GROUP_LEVELZERO,
                         zeCommandListAppendLaunchKernel_id);

   // Also trace memory copy
   ptiViewEnableDriverApi(1,
                         PTI_API_GROUP_LEVELZERO,
                         zeCommandListAppendMemoryCopy_id);

**Using SYCL API IDs:**

.. code-block:: c++

   #include "pti/pti_runtime_sycl_api_ids.h"
   #include "pti/pti_view.h"

   // Enable tracing of specific SYCL runtime APIs
   ptiViewEnable(PTI_VIEW_RUNTIME_API);

   // Filter to only trace kernel enqueue
   ptiViewEnableRuntimeApi(1,
                          PTI_API_GROUP_SYCL,
                          urEnqueueKernelLaunch_id);

   // Also trace USM memcpy
   ptiViewEnableRuntimeApi(1,
                          PTI_API_GROUP_SYCL,
                          urEnqueueUSMMemcpy_id);

**Decoding API IDs in Records:**

When processing ``pti_view_record_api`` records, use ``ptiViewGetApiIdName()`` to convert IDs to names:

.. code-block:: c++

   void ProcessApiRecord(pti_view_record_api* rec) {
       const char* api_name = nullptr;

       // Get human-readable API name
       ptiViewGetApiIdName(rec->_api_group_id, rec->_api_id, &api_name);

       if (api_name) {
           std::cout << "API: " << api_name << std::endl;
       }

       // Or manually check against enum values
       if (rec->_api_group_id == PTI_API_GROUP_LEVELZERO) {
           if (rec->_api_id == zeCommandListAppendLaunchKernel_id) {
               std::cout << "Found kernel launch API" << std::endl;
           } else if (rec->_api_id == zeCommandListAppendMemoryCopy_id) {
               std::cout << "Found memory copy API" << std::endl;
           }
       }
   }

**Enum Naming Convention:**

* Level-Zero: ``ze<FunctionName>_id`` (e.g., ``zeCommandListCreate_id``)
* SYCL/UR: ``ur<FunctionName>_id`` (e.g., ``urEnqueueKernelLaunch_id``)

**Auto-Generated Headers:**

These headers are automatically generated from API specifications:

* Level-Zero from ``ze_api.h`` (v1.28.0)
* SYCL/UR from ``ur_api.h`` (v0.12-r0)

Do not modify these files manually. They are regenerated when PTI updates to newer API versions.

**Complete Example:**

.. code-block:: c++

   #include "pti/pti_view.h"
   #include "pti/pti_driver_levelzero_api_ids.h"
   #include <iostream>

   void BufferCompleted(unsigned char* buf, size_t buf_size,
                       size_t valid_buf_size) {
       // Process API records
       pti_view_record_base* ptr =
           reinterpret_cast<pti_view_record_base*>(buf);

       while (ptr < reinterpret_cast<pti_view_record_base*>(
                        buf + valid_buf_size)) {

           if (ptr->_view_kind == PTI_VIEW_DRIVER_API) {
               auto* api_rec = reinterpret_cast<pti_view_record_api*>(ptr);

               // Decode API name
               const char* name = nullptr;
               ptiViewGetApiIdName(api_rec->_api_group_id,
                                  api_rec->_api_id,
                                  &name);

               std::cout << "Driver API: " << (name ? name : "unknown")
                         << ", Duration: "
                         << (api_rec->_end_timestamp - api_rec->_start_timestamp)
                         << " ns" << std::endl;
           }

           ptr = reinterpret_cast<pti_view_record_base*>(
               reinterpret_cast<unsigned char*>(ptr) +
               ptr->_view_record_size);
       }

       delete[] buf;
   }

   int main() {
       // Set up tracing
       ptiViewSetCallbacks(BufferRequested, BufferCompleted);

       // Enable only kernel launch API tracing
       ptiViewEnable(PTI_VIEW_DRIVER_API);
       ptiViewEnableDriverApi(1, PTI_API_GROUP_LEVELZERO,
                             zeCommandListAppendLaunchKernel_id);

       // Run workload
       run_sycl_kernels();

       // Cleanup
       ptiViewDisable(PTI_VIEW_DRIVER_API);
       ptiFlushAllViews();

       return 0;
   }

Linking PTI in Your Application
================================

See the :doc:`linking` section for details on integrating PTI SDK into your build system using CMake's ``find_package`` or manual linking.

Error Handling
==============

PTI functions return ``pti_result`` status codes:

.. code-block:: c++

   pti_result result = ptiViewEnable(PTI_VIEW_DEVICE_GPU_KERNEL);

   if (result != PTI_SUCCESS) {
       switch (result) {
           case PTI_ERROR_BAD_ARGUMENT:
               std::cerr << "Invalid argument" << std::endl;
               break;
           case PTI_ERROR_NOT_INITIALIZED:
               std::cerr << "PTI not initialized (missing callbacks?)" << std::endl;
               break;
           default:
               std::cerr << "PTI error: " << result << std::endl;
       }
       return 1;
   }

Always check return values, especially for ``ptiViewSetCallbacks()`` and ``ptiViewEnable()``.

Best Practices
==============

1. **Set callbacks before enabling views** - Required for proper operation
2. **Use local collection** - Enable tracing only where needed
3. **Check error codes** - Handle failures gracefully
4. **Keep callbacks fast** - Defer expensive processing
5. **Use appropriate buffer sizes** - Balance memory and callback frequency
6. **Enable only needed views** - Reduce overhead
7. **Disable views in reverse order** - Clean shutdown pattern
8. **Make callbacks thread-safe** - Use synchronization primitives
9. **Free buffers after processing** - Prevent memory leaks
10. **Test with different workloads** - Verify performance and correctness

Next Steps
==========

* Explore the :doc:`samples` for complete working examples
* Review the :doc:`view_api_ref` for detailed function documentation
* Check :doc:`linking` for integration with your build system

For additional help, see the `GitHub repository <https://github.com/intel/pti-gpu>`_.



