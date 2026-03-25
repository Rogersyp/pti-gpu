==============
What's New
==============

.. warning::
   **DRAFT DOCUMENTATION** - This documentation is currently in draft status and subject to change.

Version 0.17.0
---------------

*Current development version*

* Improved SYCL callback handling for better performance.
* Support for Intel oneAPI Compiler 2026.
* Fixed building without oneCCL installed.
* Fixed PTI_VIEW_COLLECTION_OVERHEAD not returned when scope profiler enabled.
* Fixed access event pool nullptr issues.
* Disabled tracing on ZeCollector destruction to prevent cleanup issues.
* Various bug fixes and performance improvements.

Version 0.16.1
---------------

* Fixed stream metrics calculation hang on BMG (Battlemage) platforms.
* Improved stability of performance tests.
* Fixed submit/append timestamp for immediate command list operations.
* Multi-threaded PTI Metrics Library support (PTI-145, PTI-335).
* Fixed potential integer overflow with overhead records.
* Fixed occasional hang in ZeCollector's destructor.
* Regenerated API IDs for latest Intel LLVM SYCL Runtime.
* Updated Level Zero Loader to version 1.28.0.
* Updated GTest to version 1.17.0.
* Various minor bug fixes and improvements.

Version 0.16.0
---------------

**Major Features:**

* **Metrics Scope API Implementation (PTI-225)** - New per-kernel hardware metrics collection API enabling automatic metrics gathering for individual GPU kernels. See :doc:`metrics_guide` for details.
* **SYCL Graph Support** - Initial support for SYCL Graph tracing and profiling.
* **KMD (Kernel Mode Driver) Profiling** - Added support for kernel-level profiling with page fault tracing examples.
* **Multi-threaded PTI Metrics Library** - Enhanced metrics library with thread-safe collection (PTI-145, PTI-335).

**Improvements:**

* Fixed and improved start-stop test functionality.
* Launch kernel with argument/parameter support.
* Changed method for handling swap events.
* Support for Level-Zero APIs v1.26.1 and higher.
* Improved compatibility with oneAPI 2025.3.
* Added OMP (OpenMP) sample demonstrating offload tracing.
* Allow optional data in KMD tracing.
* Upgraded Level Zero Loader to version 1.26.3.

**Bug Fixes:**

* Fixed ASan and Coverity builds.
* Fixed compilation on Rocky 8 containers.
* Fixed various metrics concurrent collection issues.
* Temporarily disabled unstable features for stability.
* Various test improvements and quarantined sporadic tests.

Version 0.15.0
---------------

* Support for new Level-Zero extension APIs.
* Improved extension API tracing infrastructure with code generation.
* Enhanced error handling and reporting.
* Various performance optimizations.

Version 0.14.0
---------------

* Support for Intel oneAPI Compiler 2025.2.
* Improved UR (Unified Runtime) API support.
* Enhanced SYCL runtime API ID generation.
* Various stability improvements.

Version 0.13.1
---------------

**Major Changes:**

* **PTI Metrics Library Merged** (PTI-260) - The PTI Metrics Library has been fully integrated into the main PTI Library, providing unified access to hardware performance counters. See :doc:`metrics_api_ref` for API documentation.
* **Level-Zero Core Extension Support** - Added support for querying PCI properties using L0 core extensions.
* **zeCommandListImmediateAppendCommandListsExp Support** - Support for immediate command list append experimental API.

**Improvements:**

* Simplified PTI error-to-string conversion.
* Optimized context switch impact on start time.
* Removed unnecessary event status query calls for better performance.
* Fixed kernel timestamp queries when using counter-based signal events (PTI-264).
* Compute metrics can now be queried out of process on Windows.
* Fixed metric sampling hang conditions.
* Added ``--devices-to-sample`` flag for selective device profiling.
* Addressed warnings with -pedantic -Wall -Wextra compilation flags.

**Bug Fixes:**

* Fixed build issues with older drivers.
* Fixed conflicts with unitrace for SYCL runtime.
* Fixed Rocky 8 compilation issues.
* Various test improvements and fixes.

Version 0.13.0
---------------

* Enhanced metrics collection capabilities.
* Improved device and metrics enumeration.
* Support for Panther Lake platform validation (PTI-263).
* Various bug fixes and stability improvements.

Version 0.12.4
---------------

* Set default PTI_DEVICE_SYNC_DELTA to 1 for improved timestamp accuracy.
* Fixed compilation warnings on older MSVC versions.
* Set Sysman environment variables automatically.
* Fixed ISO metrics test failures with oneAPI 2025.2.
* Improved NoKernelOverlap test reliability.
* Fixed dynamic tracing with zesInit on BMG and later platforms.
* Adjusted default PTI_DEVICE_SYNC_DELTA for better performance.
* Wrote out device process info and thread info as soon as available.
* Fixed GTPin utilities assertions.
* Fixed tests on older driver versions.
* Quarantined performance tests for stability.

Version 0.12.3
---------------

* Various bug fixes and improvements.
* Enhanced stability for production environments.

Version 0.12.2
---------------

* Fixed missing libpti.so from intel-pti runtime package (PTI-257).
* Package installation improvements.

Version 0.12.1
---------------

* Improved timestamp handling with better control and testing (PTI-218).
* Fixed no-time-conversion for zero timestamps.
* Extended NoKernelOverlap test to validate intervals between kernel events.
* Fixed and improved multi-threaded submission test.
* Updated Level Zero Loader to version 1.20.2.
* Used major version as SOVERSION for better library versioning.

Version 0.12.0
---------------

* Significant improvements to timestamp accuracy and handling.
* Enhanced multi-threaded application support.
* Various bug fixes and performance improvements.

Version 0.11.0
---------------

* Improved collection overhead tracking and reporting.
* Enhanced API tracing capabilities.
* Support for additional Level-Zero APIs.
* Various bug fixes.

Version 0.10.3
---------------

* Control and test timestamps with improved accuracy.
* Better timestamp handling for zero values.
* Enhanced validation of kernel event intervals.
* Improved multi-threaded submission handling.

Version 0.10.2
---------------

* Various stability improvements.
* Bug fixes for edge cases.

Version 0.10.1
---------------

* Support for ``zeInitDrivers`` API (PTI-489).
* Enhanced driver initialization handling.
* Various bug fixes.

Version 0.10.0
---------------

* Improved API coverage and tracing capabilities.
* Enhanced error handling.
* Various performance optimizations.

Version 0.9.0
---------------

* Added function call(s) providing the timestamp and allowing the user to provide their own timestamp via a callback.
* Windows 11 support added.
* Various bug fixes and improvements.

Version 0.8.0
---------------

* Added the ability to link against older, unsupported L0 loader and gracefully report unsupported.
* Various bug fixes and improvements.

Version 0.7.0
---------------

**Local Collection Feature:**

Implements the new functionality of Local collection. It enables starting and stopping collection anytime-anywhere in an application when run on the system with installed Level-Zero runtime supporting `1.9.0 specification <https://spec.oneapi.io/releases/index.html#level-zero-v1-9-0>`_ and higher.

Local collection functionality is transparent and controlled via ``ptiViewEnable`` and ``ptiViewDisable`` calls, where the first ``ptiViewEnable`` (or several of them) called at any place start the Local collection and the last ``ptiViewDisable`` (or several of them, paired with preceding ``ptiViewEnable`` calls) stop the Local collection.

Outside of Local collection regions of interest, PTI SDK maintains **zero overhead** by not issuing any calls or collecting any data.

On systems with Level-Zero version lower than 1.9.0, PTI SDK still operates as before version 0.7.0: tracing runtime calls and causing overhead outside of ``ptiViewEnable`` - ``ptiViewDisable`` regions, but reporting data only for ``ptiViewEnable`` - ``ptiViewDisable`` regions.

----

Migration Notes
===============

Version 0.16.0
--------------

**Metrics Scope API:**

If you were using experimental metrics collection APIs, you should migrate to the new Metrics Scope API which provides:

* Automatic per-kernel metrics collection
* Simplified buffer management
* Better integration with PTI View tracing

See :doc:`metrics_guide` for complete documentation and examples.

**SYCL Graph Support:**

Applications using SYCL Graph features will now be traced automatically. Review graph-related records in your profiling data.

Version 0.13.1
--------------

**PTI Metrics Library Integration:**

The PTI Metrics Library is now part of the main PTI Library. If you were using the separate metrics library:

* Update your CMake scripts to link against the unified ``pti`` library
* Remove separate metrics library dependencies
* API remains the same, no code changes required

Version 0.7.0
-------------

**Local Collection:**

Applications can now take advantage of zero-overhead profiling on systems with Level-Zero 1.9.0+. Simply use ``ptiViewEnable``/``ptiViewDisable`` to mark regions of interest.

To check if local collection is available:

.. code-block:: c++

   if (ptiViewGPULocalAvailable() == PTI_SUCCESS) {
       // Local collection available - zero overhead!
   }

----

Compatibility Notes
===================

Level-Zero Requirements
-----------------------

* **PTI SDK 0.16.0+:** Level-Zero 1.26.0+ recommended for full feature support
* **PTI SDK 0.13.0+:** Level-Zero 1.20.0+ recommended
* **PTI SDK 0.7.0+:** Level-Zero 1.9.0+ for zero-overhead local collection

Intel oneAPI Compiler
---------------------

* **PTI SDK 0.17.0:** Compatible with Intel oneAPI Compiler 2026
* **PTI SDK 0.16.0+:** Compatible with Intel oneAPI 2025.2 and 2025.3
* **PTI SDK 0.13.0+:** Compatible with Intel oneAPI 2025.1+

Platform Support
----------------

* **BMG (Battlemage):** Fully supported since version 0.16.0
* **Panther Lake:** Support added in version 0.13.0
* **Windows 11:** Fully supported since version 0.9.0
* **Linux:** All recent distributions supported (Ubuntu, Rocky, RHEL, SLES)

----

Known Issues
============

Version 0.16.1
--------------

* Some metrics tests may be sporadic on certain platforms - these have been quarantined
* NoKernelOverlap tests disabled on Windows with oneAPI 2025.3 pending investigation

Version 0.16.0
--------------

* Only one metric group per device currently supported
* Metrics Scope USER mode not yet implemented (only AUTO_KERNEL mode available)

See :doc:`knownissues` for complete list of known issues and workarounds.

----

Deprecation Notices
===================

Deprecated in 0.16.0
--------------------

* Some legacy tools (one-trace, one-prof) are no longer in active development and have been removed from CI testing

Future Deprecations
-------------------

* Support for Level-Zero versions older than 1.9.0 may be removed in future versions
* Legacy metrics collection methods will be deprecated in favor of Metrics Scope API
