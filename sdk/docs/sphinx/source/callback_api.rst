##################################
PTI Callback API (Experimental)
##################################

.. warning::
   **DRAFT DOCUMENTATION** - This documentation is currently in draft status and subject to change.

.. warning::
   The Callback API is **EXPERIMENTAL** and subject to change. APIs and data structures in this document may change in future releases without notice. Use with caution in production environments.

Overview
========

The PTI Callback API provides a low-level subscription mechanism for receiving synchronous notifications about GPU operations as they are appended, dispatched, or completed. Unlike the View API which delivers buffered profiling records, the Callback API delivers real-time callbacks during specific GPU operation lifecycle events.

The Callback API is primarily designed for:

* **Internal PTI infrastructure** - Used internally by Metrics Scope API for per-kernel metrics collection
* **Advanced profiling tools** - Tools requiring immediate notification of GPU operations
* **Custom correlation systems** - Applications needing to inject custom correlation IDs at precise moments
* **Low-latency monitoring** - Systems requiring minimal delay between operation and notification

.. note::
   Most users should use the :doc:`devguide` (View API) instead. The Callback API is only necessary when you need synchronous callbacks during GPU operation lifecycle events.

Callback API vs View API
=========================

Understanding when to use each API:

**View API (Recommended for most users)**

* Buffered delivery - Records delivered in batches via ``buffer_completed`` callback
* Zero overhead outside ``ptiViewEnable/Disable`` regions
* Post-execution data - Receives complete timing information after operations finish
* Simpler programming model - Just set callbacks and enable views
* Production-ready and stable

**Callback API (Advanced users only)**

* Synchronous delivery - Callbacks invoked immediately during operation lifecycle
* Real-time notifications - Notified as operations are appended, not after completion
* Fine-grained control - Subscribe to specific domains and phases
* Complex programming model - Must handle callbacks during application execution
* Experimental and subject to change

**When to use Callback API:**

* You need to inject external correlation IDs at precise moments
* You're building infrastructure similar to Metrics Scope API
* You need immediate notification when kernels are appended to command lists
* You're implementing custom monitoring that can't tolerate buffering delays

**When to use View API:**

* Standard profiling and tracing needs
* Post-execution performance analysis
* Building profiling tools for end users
* Any use case that can work with buffered delivery

Callback Domains
=================

The Callback API supports multiple domains representing different GPU operation lifecycle events. Each domain can be independently enabled or disabled.

Implemented Domains
-------------------

Only 2 domains are currently implemented:

**PTI_CB_DOMAIN_DRIVER_GPU_OPERATION_APPENDED**
  Synchronous callback invoked when GPU operations are appended to a command list.

  * **Phases:** ``PTI_CB_PHASE_API_ENTER`` and ``PTI_CB_PHASE_API_EXIT``
  * **Data type:** ``pti_callback_gpu_op_data``
  * **Use cases:**

    - Inject external correlation IDs before operations execute
    - Track command list structure and submission patterns
    - Monitor which kernels are being queued

  * **Special behavior:** For Immediate Command Lists, this also serves as ``PTI_CB_DOMAIN_DRIVER_GPU_OPERATION_DISPATCHED`` since append implicitly dispatches.

**PTI_CB_DOMAIN_DRIVER_GPU_OPERATION_COMPLETED**
  Asynchronous callback invoked when GPU operations complete execution.

  * **Phases:** Only ``PTI_CB_PHASE_API_EXIT`` (no enter phase)
  * **Data type:** ``pti_callback_gpu_op_data``
  * **Use cases:**

    - Process completed operations immediately
    - Collect per-kernel metrics (used by Metrics Scope API)
    - Real-time performance monitoring

Not Yet Implemented Domains
----------------------------

The following domains are defined but not yet implemented. Attempting to enable them returns ``PTI_ERROR_NOT_IMPLEMENTED``:

* ``PTI_CB_DOMAIN_DRIVER_CONTEXT_CREATED`` - Context lifecycle tracking
* ``PTI_CB_DOMAIN_DRIVER_MODULE_LOADED`` - Module load notifications
* ``PTI_CB_DOMAIN_DRIVER_MODULE_UNLOADED`` - Module unload notifications
* ``PTI_CB_DOMAIN_DRIVER_GPU_OPERATION_DISPATCHED`` - Operation dispatch (merged with APPENDED for immediate lists)
* ``PTI_CB_DOMAIN_DRIVER_HOST_SYNCHRONIZATION`` - Host sync operations
* ``PTI_CB_DOMAIN_DRIVER_API`` - All driver API calls
* ``PTI_CB_DOMAIN_INTERNAL_THREADS`` - PTI internal thread notifications
* ``PTI_CB_DOMAIN_INTERNAL_EVENT`` - PTI internal events

Basic Usage
===========

Minimal Callback Example
-------------------------

.. code-block:: c++

   #include "pti/pti_callback.h"
   #include "pti/pti_view.h"
   #include <iostream>

   // Define callback function
   void MyCallback(pti_callback_domain domain,
                   pti_api_group_id driver_api_group_id,
                   uint32_t driver_api_id,
                   pti_backend_ctx_t backend_context,
                   void* cb_data,
                   void* global_user_data,
                   void** instance_user_data) {

       if (domain == PTI_CB_DOMAIN_DRIVER_GPU_OPERATION_APPENDED) {
           auto* gpu_data = static_cast<pti_callback_gpu_op_data*>(cb_data);

           std::cout << "GPU operation appended: "
                     << gpu_data->_operation_details[0]._name
                     << std::endl;
       }
   }

   int main() {
       // IMPORTANT: Callback API requires at least one View to be enabled
       ptiViewSetCallbacks(BufferRequested, BufferCompleted);
       ptiViewEnable(PTI_VIEW_DEVICE_GPU_KERNEL);

       // Create callback subscriber
       pti_callback_subscriber_handle subscriber = nullptr;
       void* user_data = nullptr;
       ptiCallbackSubscribe(&subscriber, MyCallback, user_data);

       // Enable domain
       ptiCallbackEnableDomain(subscriber,
                              PTI_CB_DOMAIN_DRIVER_GPU_OPERATION_APPENDED,
                              1,  // enable enter callback
                              1); // enable exit callback

       // Run GPU workload - callbacks will be invoked
       run_gpu_kernels();

       // Cleanup
       ptiCallbackUnsubscribe(subscriber);
       ptiViewDisable(PTI_VIEW_DEVICE_GPU_KERNEL);

       return 0;
   }

Complete Workflow
=================

Step 1: Enable View API
------------------------

The Callback API requires at least one PTI View to be enabled:

.. code-block:: c++

   // Set up View API (required for Callback API to work)
   ptiViewSetCallbacks(BufferRequested, BufferCompleted);
   ptiViewEnable(PTI_VIEW_DEVICE_GPU_KERNEL);
   ptiViewEnable(PTI_VIEW_DEVICE_GPU_MEM_COPY);

.. note::
   This is a current implementation requirement. The Callback API needs View API infrastructure to function.

Step 2: Create Subscriber
--------------------------

Initialize a callback subscriber with your callback function:

.. code-block:: c++

   pti_callback_subscriber_handle subscriber = nullptr;

   // Optional: user data passed to every callback
   MyUserData* user_data = new MyUserData();

   pti_result result = ptiCallbackSubscribe(&subscriber,
                                            MyCallbackFunction,
                                            user_data);
   if (result != PTI_SUCCESS) {
       std::cerr << "Failed to subscribe: " << result << std::endl;
       return;
   }

   std::cout << "Subscriber handle: " << subscriber << std::endl;

Step 3: Enable Callback Domains
--------------------------------

Enable specific domains you want to monitor:

.. code-block:: c++

   // Enable GPU operation appended callbacks (enter and exit)
   ptiCallbackEnableDomain(subscriber,
                          PTI_CB_DOMAIN_DRIVER_GPU_OPERATION_APPENDED,
                          1,  // enable_enter: receive PTI_CB_PHASE_API_ENTER
                          1); // enable_exit: receive PTI_CB_PHASE_API_EXIT

   // Enable GPU operation completed callbacks (only exit phase exists)
   ptiCallbackEnableDomain(subscriber,
                          PTI_CB_DOMAIN_DRIVER_GPU_OPERATION_COMPLETED,
                          0,  // no enter phase for completion domain
                          1); // enable_exit: receive PTI_CB_PHASE_API_EXIT

Step 4: Implement Callback Function
------------------------------------

Process callback data based on domain:

.. code-block:: c++

   void MyCallbackFunction(pti_callback_domain domain,
                          pti_api_group_id driver_api_group_id,
                          uint32_t driver_api_id,
                          pti_backend_ctx_t backend_context,
                          void* cb_data,
                          void* global_user_data,
                          void** instance_user_data) {

       switch (domain) {
           case PTI_CB_DOMAIN_DRIVER_GPU_OPERATION_APPENDED: {
               auto* gpu_data = static_cast<pti_callback_gpu_op_data*>(cb_data);

               std::cout << "Phase: "
                         << ptiCallbackPhaseTypeToString(gpu_data->_phase)
                         << std::endl;
               std::cout << "Operations: " << gpu_data->_operation_count
                         << std::endl;

               for (uint32_t i = 0; i < gpu_data->_operation_count; ++i) {
                   auto& op = gpu_data->_operation_details[i];
                   std::cout << "  Operation " << i << ": "
                             << op._name << std::endl;
                   std::cout << "    Kind: " << op._operation_kind << std::endl;
                   std::cout << "    ID: " << op._operation_id << std::endl;
               }
               break;
           }

           case PTI_CB_DOMAIN_DRIVER_GPU_OPERATION_COMPLETED: {
               auto* gpu_data = static_cast<pti_callback_gpu_op_data*>(cb_data);

               // Process completed operations
               for (uint32_t i = 0; i < gpu_data->_operation_count; ++i) {
                   std::cout << "Completed: "
                             << gpu_data->_operation_details[i]._name
                             << std::endl;
               }
               break;
           }

           default:
               std::cerr << "Unexpected domain: " << domain << std::endl;
               break;
       }
   }

Step 5: Run Workload
--------------------

Execute your GPU workload. Callbacks will be invoked automatically:

.. code-block:: c++

   // Callbacks are invoked synchronously as operations are appended
   run_gpu_kernels();

   // Wait for completion (completion callbacks invoked asynchronously)
   queue.wait();

Step 6: Cleanup
---------------

Unsubscribe and disable views:

.. code-block:: c++

   // Unsubscribe from all domains and invalidate handle
   ptiCallbackUnsubscribe(subscriber);

   // Disable views
   ptiViewDisable(PTI_VIEW_DEVICE_GPU_KERNEL);
   ptiViewDisable(PTI_VIEW_DEVICE_GPU_MEM_COPY);

   // Flush any remaining View records
   ptiFlushAllViews();

   // Cleanup user data
   delete static_cast<MyUserData*>(user_data);

Advanced Features
=================

External Correlation Integration
---------------------------------

The Callback API integrates seamlessly with External Correlation for precise correlation ID injection:

.. code-block:: c++

   #include <atomic>

   std::atomic<uint64_t> correlation_id_counter{0};

   void CallbackWithCorrelation(pti_callback_domain domain,
                               pti_api_group_id driver_api_group_id,
                               uint32_t driver_api_id,
                               pti_backend_ctx_t backend_context,
                               void* cb_data,
                               void* global_user_data,
                               void** instance_user_data) {

       if (domain == PTI_CB_DOMAIN_DRIVER_GPU_OPERATION_APPENDED) {
           auto* gpu_data = static_cast<pti_callback_gpu_op_data*>(cb_data);

           if (gpu_data->_phase == PTI_CB_PHASE_API_ENTER) {
               // Push correlation ID before operation executes
               uint64_t id = correlation_id_counter.fetch_add(1);
               ptiViewPushExternalCorrelationId(
                   PTI_VIEW_EXTERNAL_KIND_CUSTOM_0, id);

               // Store ID in instance_user_data to retrieve on exit
               *instance_user_data = reinterpret_cast<void*>(id);

               std::cout << "Pushed correlation ID: " << id << std::endl;

           } else if (gpu_data->_phase == PTI_CB_PHASE_API_EXIT) {
               // Pop correlation ID after operation appended
               uint64_t popped_id = 0;
               ptiViewPopExternalCorrelationId(
                   PTI_VIEW_EXTERNAL_KIND_CUSTOM_0, &popped_id);

               uint64_t stored_id =
                   reinterpret_cast<uint64_t>(*instance_user_data);

               if (popped_id == stored_id) {
                   std::cout << "Popped correlation ID: " << popped_id
                             << std::endl;
               } else {
                   std::cerr << "Correlation ID mismatch!" << std::endl;
               }
           }
       }
   }

This pattern allows you to:

* Associate application-level operations with GPU kernels
* Track operations across different profiling tools
* Build custom correlation hierarchies
* Link GPU operations to higher-level framework calls

.. note::
   Remember to enable ``PTI_VIEW_EXTERNAL_CORRELATION`` to receive correlation records in View API buffers.

Instance User Data
------------------

Use ``instance_user_data`` to pass information between ENTER and EXIT phases:

.. code-block:: c++

   void CallbackWithInstanceData(pti_callback_domain domain,
                                 pti_api_group_id driver_api_group_id,
                                 uint32_t driver_api_id,
                                 pti_backend_ctx_t backend_context,
                                 void* cb_data,
                                 void* global_user_data,
                                 void** instance_user_data) {

       auto* gpu_data = static_cast<pti_callback_gpu_op_data*>(cb_data);

       if (gpu_data->_phase == PTI_CB_PHASE_API_ENTER) {
           // Allocate per-call data
           auto* call_data = new CallData();
           call_data->start_time = std::chrono::steady_clock::now();
           *instance_user_data = call_data;

       } else if (gpu_data->_phase == PTI_CB_PHASE_API_EXIT) {
           // Retrieve per-call data
           auto* call_data = static_cast<CallData*>(*instance_user_data);
           auto end_time = std::chrono::steady_clock::now();

           auto duration = std::chrono::duration_cast<std::chrono::microseconds>(
               end_time - call_data->start_time);

           std::cout << "Append took: " << duration.count() << " us"
                     << std::endl;

           delete call_data;
           *instance_user_data = nullptr;
       }
   }

Selective Domain Control
-------------------------

Enable or disable domains dynamically:

.. code-block:: c++

   // Initially enable only append domain
   ptiCallbackEnableDomain(subscriber,
                          PTI_CB_DOMAIN_DRIVER_GPU_OPERATION_APPENDED,
                          1, 1);

   // Run some workload
   run_warmup_kernels();

   // Now also enable completion domain
   ptiCallbackEnableDomain(subscriber,
                          PTI_CB_DOMAIN_DRIVER_GPU_OPERATION_COMPLETED,
                          0, 1);

   // Run main workload with both domains
   run_main_workload();

   // Disable specific domain
   ptiCallbackDisableDomain(subscriber,
                           PTI_CB_DOMAIN_DRIVER_GPU_OPERATION_APPENDED);

   // Or disable all domains
   ptiCallbackDisableAllDomains(subscriber);

Multiple Operations in Single Callback
---------------------------------------

Callbacks may receive multiple operations at once:

.. code-block:: c++

   void HandleMultipleOperations(pti_callback_gpu_op_data* gpu_data) {
       if (gpu_data->_operation_count > 1) {
           std::cout << "Batch of " << gpu_data->_operation_count
                     << " operations:" << std::endl;
       }

       for (uint32_t i = 0; i < gpu_data->_operation_count; ++i) {
           const auto& op = gpu_data->_operation_details[i];

           switch (op._operation_kind) {
               case PTI_GPU_OPERATION_KIND_KERNEL:
                   std::cout << "  Kernel: " << op._name << std::endl;
                   break;
               case PTI_GPU_OPERATION_KIND_MEMORY:
                   std::cout << "  Memory op: " << op._name << std::endl;
                   break;
               case PTI_GPU_OPERATION_KIND_OTHER:
                   std::cout << "  Other op: " << op._name << std::endl;
                   break;
               default:
                   break;
           }
       }
   }

Command List Type Detection
----------------------------

Determine whether operations are appended to immediate or mutable command lists:

.. code-block:: c++

   void AnalyzeCommandListType(pti_callback_gpu_op_data* gpu_data) {
       if (gpu_data->_cmd_list_properties &
           PTI_BACKEND_COMMAND_LIST_TYPE_IMMEDIATE) {
           std::cout << "Immediate command list (auto-dispatch)" << std::endl;
       } else if (gpu_data->_cmd_list_properties &
                  PTI_BACKEND_COMMAND_LIST_TYPE_MUTABLE) {
           std::cout << "Mutable command list (explicit submit)" << std::endl;
       } else {
           std::cout << "Unknown command list type" << std::endl;
       }

       std::cout << "Command list handle: " << gpu_data->_cmd_list_handle
                 << std::endl;
       std::cout << "Queue handle: " << gpu_data->_queue_handle << std::endl;
   }

Data Structures
===============

pti_callback_gpu_op_data
--------------------------

Primary data structure for GPU operation callbacks:

.. code-block:: c++

   typedef struct _pti_callback_gpu_op_data {
       pti_callback_domain             _domain;
       pti_backend_command_list_type   _cmd_list_properties;
       pti_backend_command_list_t      _cmd_list_handle;
       pti_backend_queue_t             _queue_handle;
       pti_device_handle_t             _device_handle;
       pti_callback_phase              _phase;
       uint32_t                        _return_code;
       uint32_t                        _correlation_id;
       uint32_t                        _operation_count;
       pti_gpu_op_details*             _operation_details;
   } pti_callback_gpu_op_data;

**Fields:**

* ``_domain`` - Which callback domain triggered this callback
* ``_cmd_list_properties`` - Command list type (immediate, mutable, etc.)
* ``_cmd_list_handle`` - Backend command list handle (may be nullptr)
* ``_queue_handle`` - Backend queue handle (may be nullptr)
* ``_device_handle`` - Device handle
* ``_phase`` - API phase (ENTER or EXIT)
* ``_return_code`` - Level-Zero return code (valid only for EXIT phase)
* ``_correlation_id`` - Correlates with View API records
* ``_operation_count`` - Number of operations in this callback
* ``_operation_details`` - Array of operation details

pti_gpu_op_details
-------------------

Details about individual GPU operations:

.. code-block:: c++

   typedef struct _pti_gpu_op_details {
       pti_gpu_operation_kind  _operation_kind;
       uint64_t                _operation_id;
       uint64_t                _kernel_handle;
       const char*             _name;
   } pti_gpu_op_details;

**Fields:**

* ``_operation_kind`` - Type: KERNEL, MEMORY, or OTHER
* ``_operation_id`` - Unique operation instance ID (process-wide)
* ``_kernel_handle`` - Kernel object handle (0 for memory operations)
* ``_name`` - Symbolic kernel or memcpy operation name

Best Practices
==============

Callback Function Guidelines
-----------------------------

**DO:**

* Keep callbacks fast - they execute synchronously during application flow
* Use atomic operations for thread-safe data access
* Check for null pointers (``cb_data``, ``_operation_details``, handles)
* Use helper functions (``ptiCallbackDomainTypeToString``, etc.)

**DON'T:**

* Call PTI API functions from within callbacks (except helper functions)
* Perform heavy computation in callbacks
* Allocate large amounts of memory
* Call blocking operations (I/O, locks that might deadlock)

.. warning::
   **CRITICAL:** Do not call PTI API functions (like ``ptiViewEnable``, ``ptiCallbackEnableDomain``, etc.) from within callback functions. This can cause deadlocks or undefined behavior. Only helper functions that return string representations are safe to call.

Thread Safety
-------------

The Callback API is thread-safe:

.. code-block:: c++

   // Global subscriber can be accessed from multiple threads
   pti_callback_subscriber_handle g_subscriber = nullptr;

   void SetupProfiling() {
       ptiCallbackSubscribe(&g_subscriber, MyCallback, nullptr);
       ptiCallbackEnableDomain(g_subscriber, /* ... */);
   }

   // Callback may be invoked from any thread
   void MyCallback(/* ... */) {
       // Use thread-safe operations
       std::lock_guard<std::mutex> lock(g_mutex);
       g_operation_count++;
   }

Error Handling
--------------

Always check return values:

.. code-block:: c++

   pti_result result;

   result = ptiCallbackSubscribe(&subscriber, MyCallback, nullptr);
   if (result != PTI_SUCCESS) {
       std::cerr << "Subscribe failed: " << result << std::endl;
       return;
   }

   result = ptiCallbackEnableDomain(subscriber, domain, 1, 1);
   if (result == PTI_ERROR_NOT_IMPLEMENTED) {
       std::cerr << "Domain not implemented: "
                 << ptiCallbackDomainTypeToString(domain) << std::endl;
       return;
   } else if (result != PTI_SUCCESS) {
       std::cerr << "EnableDomain failed: " << result << std::endl;
       return;
   }

Cleanup Order
-------------

Proper cleanup sequence:

.. code-block:: c++

   // 1. Unsubscribe from callbacks
   ptiCallbackUnsubscribe(subscriber);

   // 2. Disable views
   ptiViewDisable(PTI_VIEW_DEVICE_GPU_KERNEL);

   // 3. Flush remaining view records
   ptiFlushAllViews();

   // 4. Free user data
   delete user_data;

Performance Considerations
==========================

Callback Overhead
-----------------

* **Appended callbacks:** Synchronous - adds latency to kernel submission
* **Completed callbacks:** Asynchronous - minimal impact on submission
* **Overhead scales:** With number of operations and callback complexity

Minimize overhead:

.. code-block:: c++

   void FastCallback(/* ... */) {
       // BAD: Heavy processing
       // for (int i = 0; i < 1000000; ++i) { /* ... */ }

       // GOOD: Quick processing, defer heavy work
       if (cb_data) {
           auto* gpu_data = static_cast<pti_callback_gpu_op_data*>(cb_data);

           // Just collect essential data
           g_operation_queue.push({
               gpu_data->_operation_details[0]._operation_id,
               gpu_data->_operation_details[0]._name
           });
       }
   }

   // Process collected data later in separate thread
   void ProcessingThread() {
       while (running) {
           auto op_data = g_operation_queue.pop();
           // Heavy processing here
       }
   }

When to Disable Callbacks
--------------------------

For performance-critical sections:

.. code-block:: c++

   // Enable for initialization
   ptiCallbackEnableDomain(subscriber, domain, 1, 1);
   run_initialization();

   // Disable for performance-critical loop
   ptiCallbackDisableAllDomains(subscriber);
   for (int i = 0; i < 1000; ++i) {
       run_hot_path_kernel();
   }

   // Re-enable for finalization
   ptiCallbackEnableDomain(subscriber, domain, 1, 1);
   run_finalization();

Use Cases and Examples
======================

Use Case 1: Custom Metrics Collection
--------------------------------------

Similar to how Metrics Scope API uses callbacks internally:

.. code-block:: c++

   struct MetricsCollector {
       std::map<uint64_t, KernelMetrics> pending_kernels;

       void OnAppended(pti_callback_gpu_op_data* data) {
           if (data->_phase == PTI_CB_PHASE_API_ENTER) {
               // Start metrics collection for this kernel
               uint64_t op_id = data->_operation_details[0]._operation_id;
               pending_kernels[op_id] = StartMetricsCollection();
           }
       }

       void OnCompleted(pti_callback_gpu_op_data* data) {
           // Finalize metrics for completed kernel
           uint64_t op_id = data->_operation_details[0]._operation_id;
           auto metrics = StopMetricsCollection(pending_kernels[op_id]);
           ReportMetrics(data->_operation_details[0]._name, metrics);
           pending_kernels.erase(op_id);
       }
   };

Use Case 2: Operation Flow Visualization
-----------------------------------------

Track kernel submission and execution flow:

.. code-block:: c++

   struct FlowTracker {
       void OnAppended(pti_callback_gpu_op_data* data) {
           if (data->_phase == PTI_CB_PHASE_API_ENTER) {
               std::cout << "[APPEND START] "
                         << data->_operation_details[0]._name << std::endl;
           } else {
               std::cout << "[APPEND END  ] "
                         << data->_operation_details[0]._name
                         << " -> correlation_id=" << data->_correlation_id
                         << std::endl;
           }
       }

       void OnCompleted(pti_callback_gpu_op_data* data) {
           std::cout << "[COMPLETED   ] "
                     << data->_operation_details[0]._name
                     << " correlation_id=" << data->_correlation_id
                     << std::endl;
       }
   };

Use Case 3: Command List Analysis
----------------------------------

Analyze command list submission patterns:

.. code-block:: c++

   struct CommandListAnalyzer {
       std::map<pti_backend_command_list_t, std::vector<std::string>> lists;

       void OnAppended(pti_callback_gpu_op_data* data) {
           if (data->_cmd_list_handle) {
               lists[data->_cmd_list_handle].push_back(
                   data->_operation_details[0]._name);
           }
       }

       void Report() {
           for (const auto& [handle, ops] : lists) {
               std::cout << "Command List " << handle << ":" << std::endl;
               std::cout << "  Operations: " << ops.size() << std::endl;
               for (const auto& op : ops) {
                   std::cout << "    - " << op << std::endl;
               }
           }
       }
   };

Sample Code
===========

The ``samples/callback/`` directory contains a complete working example demonstrating:

* Subscriber initialization
* Domain enablement
* External correlation ID injection
* Processing both appended and completed callbacks
* Integration with View API
* Proper cleanup

**Running the sample:**

.. code-block:: bash

   cd pti/sdk/build
   ./bin/callback

**Key files:**

* ``client.cc`` - Callback implementation and View API integration
* ``main.cc`` - SYCL workload (matrix multiplication)
* ``client.h`` - Public interface

The sample demonstrates advanced patterns like:

* Using ``instance_user_data`` to pass correlation IDs between phases
* Combining Callback API with View API for complete profiling
* API filtering to reduce noise
* Proper error handling and cleanup

Limitations and Known Issues
=============================

Current Limitations
-------------------

* **Requires View API:** Cannot use Callback API standalone - must enable at least one View
* **Limited domains:** Only 2 of 12 domains are implemented
* **Level-Zero only:** Currently only supports Level-Zero backend
* **Experimental status:** API may change in future releases

Known Issues
------------

* ``_cmd_list_handle`` and ``_queue_handle`` may be nullptr in some cases
* ``_operation_count`` may be greater than 1, requiring array processing
* No explicit flush mechanism for pending callbacks
* Error recovery from within callbacks is undefined

Troubleshooting
===============

No Callbacks Received
---------------------

**Problem:** Callbacks are not being invoked.

**Solutions:**

1. Verify at least one View is enabled:

   .. code-block:: c++

      ptiViewEnable(PTI_VIEW_DEVICE_GPU_KERNEL);

2. Check domain is implemented:

   .. code-block:: c++

      pti_result result = ptiCallbackEnableDomain(subscriber, domain, 1, 1);
      if (result == PTI_ERROR_NOT_IMPLEMENTED) {
          std::cerr << "Domain not implemented" << std::endl;
      }

3. Verify subscriber is valid:

   .. code-block:: c++

      if (subscriber == nullptr) {
          std::cerr << "Subscriber not initialized" << std::endl;
      }

Application Hangs or Crashes
-----------------------------

**Problem:** Application hangs or crashes when using callbacks.

**Solutions:**

* Don't call PTI API functions from within callbacks
* Check for null pointers before dereferencing
* Avoid heavy computation in callbacks
* Use atomic operations for shared data

Missing Operation Names
-----------------------

**Problem:** ``_name`` field in ``pti_gpu_op_details`` is null or empty.

**Solutions:**

* Check if kernel has debug information
* Verify symbolic names are preserved during compilation
* Some internal operations may not have names

See Also
========

* :doc:`devguide` - View API usage patterns
* :doc:`metrics_guide` - Metrics Scope API (built on Callback API)
* :doc:`view_api_ref` - Complete View API documentation
* :doc:`samples` - Callback sample walkthrough

API Function Reference
======================

For detailed function signatures, parameters, and return values, see the full Doxygen-generated documentation in :ref:`callback_api_functions`.
