####################################
Communication Tracing (oneCCL/ITT)
####################################

.. warning::
   **DRAFT DOCUMENTATION** - This documentation is currently in draft status and subject to change.

Overview
========

PTI SDK provides specialized support for tracing collective communication operations via **oneCCL** (Intel® oneAPI Collective Communications Library). This feature enables profiling of distributed computing workloads that use collective operations like allreduce, broadcast, gather, and scatter.

The communication tracing feature uses **Intel® ITT (Instrumentation and Tracing Technology) API** to intercept oneCCL function calls and provides timing and metadata information through the PTI View API.

.. note::
   Communication tracing is currently **only available on Linux** platforms.

When to Use Communication Tracing
==================================

Use ``PTI_VIEW_COMMUNICATION`` when you need to:

* Profile distributed machine learning training workloads
* Analyze collective communication overhead in multi-GPU applications
* Understand communication patterns in HPC applications using oneCCL
* Correlate computation and communication phases
* Identify communication bottlenecks in scalability studies

Supported Operations
====================

The communication tracer captures all oneCCL collective operations, including:

**Data Movement:**

* ``allreduce`` - Reduce data across all ranks and distribute result
* ``reduce`` - Reduce data to a single rank
* ``broadcast`` - Broadcast data from one rank to all
* ``allgather`` - Gather data from all ranks and distribute to all
* ``allgatherv`` - Allgather with variable data sizes
* ``alltoall`` - All-to-all data exchange
* ``alltoallv`` - All-to-all with variable data sizes

**Synchronization:**

* ``barrier`` - Synchronize all ranks

**Point-to-Point:**

* ``send`` / ``recv`` - Point-to-point communication

Each traced operation provides:

* Function name (e.g., "allreduce", "broadcast")
* Start and end timestamps
* Process ID and thread ID
* Communicator ID
* Metadata size

Basic Usage
===========

Enabling Communication Tracing
-------------------------------

To trace oneCCL operations, enable the ``PTI_VIEW_COMMUNICATION`` view:

.. code-block:: c++

   #include "pti/pti_view.h"

   // Set up callbacks (same as for other views)
   ptiViewSetCallbacks(BufferRequested, BufferCompleted);

   // Enable communication tracing
   ptiViewEnable(PTI_VIEW_COMMUNICATION);

   // Run your oneCCL application
   run_distributed_workload();

   // Disable tracing
   ptiViewDisable(PTI_VIEW_COMMUNICATION);

Processing Communication Records
---------------------------------

Communication records are delivered via the ``buffer_completed`` callback:

.. code-block:: c++

   void BufferCompleted(unsigned char* buf, size_t buf_size,
                        size_t valid_buf_size) {
       if (!buf || !valid_buf_size) return;

       pti_view_record_base* ptr =
           reinterpret_cast<pti_view_record_base*>(buf);

       while (ptr < reinterpret_cast<pti_view_record_base*>(
                        buf + valid_buf_size)) {

           if (ptr->_view_kind == PTI_VIEW_COMMUNICATION) {
               auto* comms_rec =
                   reinterpret_cast<pti_view_record_comms*>(ptr);

               std::cout << "Communication: " << comms_rec->_name << std::endl;
               std::cout << "  Process ID: " << comms_rec->_process_id << std::endl;
               std::cout << "  Thread ID: " << comms_rec->_thread_id << std::endl;
               std::cout << "  Start: " << comms_rec->_start_timestamp << " ns" << std::endl;
               std::cout << "  End: " << comms_rec->_end_timestamp << " ns" << std::endl;
               std::cout << "  Duration: "
                         << (comms_rec->_end_timestamp - comms_rec->_start_timestamp)
                         << " ns" << std::endl;
               std::cout << "  Communicator ID: " << comms_rec->_communicator_id << std::endl;
               std::cout << "  Metadata size: " << comms_rec->_metadata_size << std::endl;
           }

           ptr = reinterpret_cast<pti_view_record_base*>(
               reinterpret_cast<unsigned char*>(ptr) + ptr->_view_record_size);
       }

       delete[] buf;
   }

Complete Example
================

SYCL with oneCCL Allreduce
---------------------------

This example demonstrates tracing a SYCL application using oneCCL for collective operations:

.. code-block:: c++

   #include <CL/sycl.hpp>
   #include <oneapi/ccl.hpp>
   #include "pti/pti_view.h"
   #include <iostream>
   #include <vector>

   // Global storage for communication records
   std::vector<pti_view_record_comms> comms_records;

   void BufferRequested(unsigned char** buf, size_t* buf_size) {
       *buf_size = 1024 * 1024;  // 1 MB
       *buf = new unsigned char[*buf_size];
   }

   void BufferCompleted(unsigned char* buf, size_t buf_size,
                        size_t valid_buf_size) {
       if (!buf || !valid_buf_size) return;

       pti_view_record_base* ptr =
           reinterpret_cast<pti_view_record_base*>(buf);

       while (ptr < reinterpret_cast<pti_view_record_base*>(
                        buf + valid_buf_size)) {
           if (ptr->_view_kind == PTI_VIEW_COMMUNICATION) {
               auto* rec = reinterpret_cast<pti_view_record_comms*>(ptr);
               comms_records.push_back(*rec);
           }
           ptr = reinterpret_cast<pti_view_record_base*>(
               reinterpret_cast<unsigned char*>(ptr) + ptr->_view_record_size);
       }

       delete[] buf;
   }

   int main(int argc, char* argv[]) {
       // Initialize oneCCL
       ccl::init();

       // Get communicator
       auto comm = ccl::create_communicator();
       int rank = comm->rank();
       int size = comm->size();

       // Create SYCL queue
       sycl::queue q;

       // Set up PTI communication tracing
       ptiViewSetCallbacks(BufferRequested, BufferCompleted);

       ptiViewEnable(PTI_VIEW_COMMUNICATION);

       // Prepare data for allreduce
       const size_t count = 1024;
       int* send_buf = sycl::malloc_device<int>(count, q);
       int* recv_buf = sycl::malloc_device<int>(count, q);

       // Initialize data
       q.parallel_for(count, [=](sycl::id<1> i) {
           send_buf[i] = rank + 1;
       }).wait();

       // Create CCL stream
       auto stream = ccl::create_stream(q);

       // Perform allreduce - THIS WILL BE TRACED
       ccl::allreduce(send_buf, recv_buf, count,
                      ccl::reduction::sum, comm, stream).wait();

       // Disable tracing
       ptiViewDisable(PTI_VIEW_COMMUNICATION);

       // Print collected communication records
       std::cout << "Rank " << rank << " traced "
                 << comms_records.size() << " communication operations:" << std::endl;

       for (const auto& rec : comms_records) {
           std::cout << "  " << rec._name
                     << " - Duration: "
                     << (rec._end_timestamp - rec._start_timestamp)
                     << " ns" << std::endl;
       }

       // Cleanup
       sycl::free(send_buf, q);
       sycl::free(recv_buf, q);

       return 0;
   }

Combining with Other Views
===========================

Communication tracing can be combined with kernel and memory tracing to get a complete picture:

.. code-block:: c++

   // Enable multiple views
   ptiViewEnable(PTI_VIEW_DEVICE_GPU_KERNEL);
   ptiViewEnable(PTI_VIEW_DEVICE_GPU_MEM_COPY);
   ptiViewEnable(PTI_VIEW_COMMUNICATION);

   // Run distributed workload with computation and communication
   run_distributed_training();

   // Disable all views
   ptiViewDisable(PTI_VIEW_COMMUNICATION);
   ptiViewDisable(PTI_VIEW_DEVICE_GPU_MEM_COPY);
   ptiViewDisable(PTI_VIEW_DEVICE_GPU_KERNEL);

This allows you to correlate:

* GPU kernel execution times
* Memory transfer times
* Communication operation times
* Overlapping computation and communication

Use Cases
=========

Distributed Machine Learning
-----------------------------

Profile gradient synchronization overhead in distributed training:

.. code-block:: c++

   // Training loop
   for (int epoch = 0; epoch < num_epochs; ++epoch) {
       // Forward pass - kernel tracing
       forward_pass(model, data);

       // Backward pass - kernel tracing
       backward_pass(model, gradients);

       // Gradient synchronization - communication tracing
       ccl::allreduce(gradients, ...);  // Traced!

       // Update weights
       update_weights(model, gradients);
   }

The communication tracing helps identify:

* Time spent in gradient synchronization vs computation
* Communication scalability across ranks
* Potential for computation/communication overlap

HPC Applications
----------------

Analyze collective communication patterns in scientific computing:

.. code-block:: c++

   // Iterative solver with periodic synchronization
   while (!converged) {
       // Local computation
       compute_local_update();

       // Halo exchange
       ccl::alltoall(local_data, neighbor_data, ...);  // Traced!

       // Global reduction
       ccl::allreduce(&local_norm, &global_norm, ...);  // Traced!

       check_convergence(global_norm);
   }

Best Practices
==============

Selective Tracing
-----------------

Enable communication tracing only for the region of interest:

.. code-block:: c++

   // No overhead here
   initialize_data();

   ptiViewEnable(PTI_VIEW_COMMUNICATION);

   // Trace only the communication-intensive phase
   distributed_computation();

   ptiViewDisable(PTI_VIEW_COMMUNICATION);

   // No overhead here
   finalize_results();

Process/Thread Identification
------------------------------

Use process and thread IDs to distinguish communications in multi-process, multi-threaded applications:

.. code-block:: c++

   // Group records by process
   std::map<uint32_t, std::vector<pti_view_record_comms>> per_process;

   for (const auto& rec : comms_records) {
       per_process[rec._process_id].push_back(rec);
   }

   // Analyze per-process communication behavior
   for (const auto& [pid, records] : per_process) {
       analyze_process_communication(pid, records);
   }

Performance Analysis
--------------------

Calculate communication overhead as percentage of total time:

.. code-block:: c++

   uint64_t total_comm_time = 0;
   for (const auto& rec : comms_records) {
       total_comm_time += (rec._end_timestamp - rec._start_timestamp);
   }

   double comm_overhead_pct =
       (100.0 * total_comm_time) / total_application_time;

   std::cout << "Communication overhead: "
             << comm_overhead_pct << "%" << std::endl;

Implementation Details
======================

ITT Integration
---------------

PTI's communication tracing uses the ITT (Instrumentation and Tracing Technology) API:

* **Domain filtering:** Only traces operations in the "oneCCL::API" domain
* **Task tracking:** Uses ITT task begin/end events to capture operation timing
* **Metadata:** Preserves metadata attached to oneCCL operations

The ITT collector intercepts calls at the ITT API level, which sits between the application and oneCCL library.

Overhead Considerations
-----------------------

* **Minimal overhead:** ITT instrumentation adds negligible overhead (~1-2%)
* **Domain-specific:** Only oneCCL operations are traced, other ITT domains are ignored
* **Thread-safe:** Safe to use in multi-threaded MPI+oneCCL applications
* **Local collection:** Zero overhead outside ``ptiViewEnable/Disable`` regions

Linux-Only Limitation
----------------------

Communication tracing is currently Linux-only because:

* ITT library linkage requirements on Linux
* oneCCL primary support on Linux for HPC workloads
* ITT API integration complexity on Windows

Windows support may be added in future versions if there is sufficient demand.

Limitations and Known Issues
=============================

Current Limitations
-------------------

* **Linux only:** Not available on Windows platforms
* **oneCCL specific:** Only traces oneCCL operations (not MPI or other libraries)
* **No payload data:** Records timing and metadata but not communicated data
* **Single domain:** Only monitors "oneCCL::API" ITT domain

Known Issues
------------

* Large-scale runs (1000+ ranks) may generate significant tracing data
* Metadata size field may be zero for some operations
* Communicator ID interpretation depends on oneCCL version

Troubleshooting
===============

No Records Captured
-------------------

If ``PTI_VIEW_COMMUNICATION`` is enabled but no records appear:

1. **Verify Linux platform:**

   .. code-block:: bash

      uname -s  # Should show "Linux"

2. **Check oneCCL is used:**

   Ensure your application actually calls oneCCL functions.

3. **Verify ITT domain:**

   oneCCL must use the "oneCCL::API" ITT domain (default in recent versions).

4. **Enable debug logging:**

   Set ``SPDLOG_LEVEL=debug`` to see ITT collector activity.

Missing Operation Names
-----------------------

If ``_name`` field is NULL or empty:

* Check oneCCL version compatibility
* Ensure ITT instrumentation is enabled in oneCCL build
* Verify string handle creation in ITT

See Also
========

* :doc:`devguide` - PTI View API usage patterns
* :doc:`view_api_ref` - Complete API documentation
* :doc:`samples` - itt_ccl sample demonstrating communication tracing
* `oneCCL Documentation <https://oneapi-src.github.io/oneCCL/>`_ - Learn about collective operations
* `ITT API Reference <https://www.intel.com/content/www/us/en/docs/vtune-profiler/user-guide/>`_ - Instrumentation and Tracing Technology details
