PTI Documentation
==================

.. warning::
   **DRAFT DOCUMENTATION** - This documentation is currently in draft status and subject to change.

**Source Repository:** https://github.com/intel/pti-gpu/tree/master/sdk

Overview
--------

The Profiling Tools Interfaces (PTI) SDK provides a high-level API for developing profiling tools for oneAPI applications running on Intel GPUs. PTI simplifies GPU profiling by providing unified tracing capabilities across SYCL and Level-Zero runtimes.

The PTI SDK abstracts the complexity of low-level runtime APIs and offers a consistent interface for:

* Tracing GPU kernel execution
* Monitoring memory transfers
* Tracking API calls
* Collecting hardware metrics
* Analyzing application performance

Key Features
~~~~~~~~~~~~

**High-Level Tracing API**
  Abstract low-level runtime details with a simple, consistent interface for profiling SYCL and Level-Zero applications.

**Local Collection**
  Zero-overhead profiling with on-demand collection. Start and stop tracing anywhere in your application with ``ptiViewEnable()`` and ``ptiViewDisable()``. Outside these regions, PTI maintains zero overhead.

**Flexible Callback System**
  Register custom callbacks to handle profiling data in real-time as events occur during application execution.

**External Correlation IDs**
  Associate application-level operations with GPU activities for detailed performance analysis and debugging.

**Hardware Metrics Collection**
  Collect GPU hardware performance counters including EU utilization, memory bandwidth, cache statistics, and more. Choose between per-kernel metrics via Metrics Scope API or device-level sampling via Metrics API.

**Communication Tracing**
  Profile collective communication operations in distributed workloads using oneCCL (oneAPI Collective Communications Library). Track allreduce, broadcast, and other collective operations with timing and metadata. Linux only.

**Callback API (Experimental)**
  Low-level subscription mechanism for synchronous notifications about GPU operations. Receive real-time callbacks as operations are appended, dispatched, or completed. Used internally by Metrics Scope API. Advanced feature for custom profiling infrastructure.

**Multi-Threading Support**
  Thread-safe design enables profiling of complex multi-threaded applications.

Use Cases
~~~~~~~~~

PTI SDK is designed for:

* Performance analysis tool developers
* Application performance optimization
* Debugging GPU workloads
* Understanding runtime behavior
* Building custom profilers

.. toctree::
   :maxdepth: 4

.. include:: toctree.rst

Indices and tables
==================

* :ref:`genindex`
* :ref:`search`

----

Notices and Disclaimers
========================

© Intel Corporation. Intel, the Intel logo and other Intel marks are trademarks of Intel Corporation or its subsidiaries. Other names and brands may be claimed as the property of others.

No license (express or implied, by estoppel or otherwise) to any intellectual property rights is granted by this document, with the sole exception that code included in this document is licensed subject to the Zero-Clause BSD open-source license (0BSD), http://opensource.org/licenses/0BSD.
