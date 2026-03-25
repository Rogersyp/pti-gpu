PTI View API Reference
######################

.. warning::
   **DRAFT DOCUMENTATION** - This documentation is currently in draft status and subject to change.

This section provides complete API documentation for the PTI View API (tracing and profiling). The documentation is automatically generated from source code headers.

.. note::
   This page documents the **PTI View API** for tracing GPU activities. For hardware metrics collection, see :doc:`metrics_api_ref`.

Overview
========

The PTI View API provides tracing capabilities for GPU operations. The API includes:

* **Core Functions** - Enable/disable tracing, set callbacks, manage views
* **Helper Functions** - Utility functions for string conversion
* **Structures** - Data structures for profiling records
* **Enumerators** - View types, result codes, memory types
* **Function Pointers** - Callback function signatures

Core Functions
==============

* :ref:`ptiViewSetCallbacks <ptiViewSetCallbacks>` - Register callback functions
* :ref:`ptiViewEnable <ptiViewEnable>` - Enable a profiling view
* :ref:`ptiViewDisable <ptiViewDisable>` - Disable a profiling view
* :ref:`ptiViewGPULocalAvailable <ptiViewGPULocalAvailable>` - Check local collection support
* :ref:`ptiFlushAllViews <ptiFlushAllViews>` - Flush all pending records
* :ref:`ptiViewGetNextRecord <ptiViewGetNextRecord>` - Retrieve next record
* :ref:`ptiViewPushExternalCorrelationId <ptiViewPushExternalCorrelationId>` - Push correlation ID
* :ref:`ptiViewPopExternalCorrelationId <ptiViewPopExternalCorrelationId>` - Pop correlation ID
* :ref:`ptiViewGetTimestamp <ptiViewGetTimestamp>` - Get current timestamp
* :ref:`ptiViewSetTimestampCallback <ptiViewSetTimestampCallback>` - Set custom timestamp function
* :ref:`ptiViewGetApiIdName <ptiViewGetApiIdName>` - Get API name from ID
* :ref:`ptiViewEnableDriverApi <ptiViewEnableDriverApi>` - Enable/disable specific driver API
* :ref:`ptiViewEnableRuntimeApi <ptiViewEnableRuntimeApi>` - Enable/disable specific runtime API
* :ref:`ptiViewEnableDriverApiClass <ptiViewEnableDriverApiClass>` - Enable/disable driver API class
* :ref:`ptiViewEnableRuntimeApiClass <ptiViewEnableRuntimeApiClass>` - Enable/disable runtime API class

Helper Functions
================

* :ref:`ptiViewOverheadKindToString <ptiViewOverheadKindToString>` - Convert overhead kind to string
* :ref:`ptiViewMemoryTypeToString <ptiViewMemoryTypeToString>` - Convert memory type to string
* :ref:`ptiViewMemcpyTypeToString <ptiViewMemcpyTypeToString>` - Convert memcpy type to string

Structures
==========

Record structures contain profiling data passed to callbacks:

* :ref:`pti_view_record_base <pti_view_record_base>` - Base record structure
* :ref:`pti_view_record_api <pti_view_record_api>` - Runtime API call record
* :ref:`pti_view_record_kernel <pti_view_record_kernel>` - GPU kernel record
* :ref:`pti_view_record_memory_copy <pti_view_record_memory_copy>` - Memory copy record
* :ref:`pti_view_record_memory_copy_p2p <pti_view_record_memory_copy_p2p>` - Peer-to-peer copy record
* :ref:`pti_view_record_memory_fill <pti_view_record_memory_fill>` - Memory fill record
* :ref:`pti_view_record_synchronization <pti_view_record_synchronization>` - Synchronization record
* :ref:`pti_view_record_external_correlation <pti_view_record_external_correlation>` - External correlation record
* :ref:`pti_view_record_overhead <pti_view_record_overhead>` - Overhead record
* :ref:`pti_view_record_comms <pti_view_record_comms>` - Communication record (oneCCL, Linux only)

Enumerators
===========

* :ref:`pti_result <pti_result>` - Function return status codes
* :ref:`pti_view_kind <pti_view_kind>` - View type identifiers
* :ref:`pti_view_external_kind <pti_view_external_kind>` - External correlation types
* :ref:`pti_view_overhead_kind <pti_view_overhead_kind>` - Overhead types
* :ref:`pti_view_memory_type <pti_view_memory_type>` - Memory location types
* :ref:`pti_view_memcpy_type <pti_view_memcpy_type>` - Memory copy direction types
* :ref:`pti_view_synchronization_type <pti_view_synchronization_type>` - Synchronization operation types
* :ref:`pti_api_group_id <pti_api_group_id>` - API group identifiers (Level-Zero, SYCL, OpenCL)
* :ref:`pti_api_class <pti_api_class>` - API class categories for filtering

Function Pointer Typedefs
==========================

Callback function signatures:

* :ref:`pti_fptr_buffer_completed <pti_fptr_buffer_completed>` - Buffer completed callback
* :ref:`pti_fptr_buffer_requested <pti_fptr_buffer_requested>` - Buffer requested callback

----

Detailed API Documentation
===========================

Functions
---------

.. _ptiViewSetCallbacks:
.. doxygenfunction:: ptiViewSetCallbacks

.. _ptiViewEnable:
.. doxygenfunction:: ptiViewEnable

.. _ptiViewDisable:
.. doxygenfunction:: ptiViewDisable

.. _ptiViewGPULocalAvailable:
.. doxygenfunction:: ptiViewGPULocalAvailable

.. _ptiFlushAllViews:
.. doxygenfunction:: ptiFlushAllViews

.. _ptiViewGetNextRecord:
.. doxygenfunction:: ptiViewGetNextRecord

.. _ptiViewPushExternalCorrelationId:
.. doxygenfunction:: ptiViewPushExternalCorrelationId

.. _ptiViewPopExternalCorrelationId:
.. doxygenfunction:: ptiViewPopExternalCorrelationId

.. _ptiViewGetTimestamp:
.. doxygenfunction:: ptiViewGetTimestamp

.. _ptiViewSetTimestampCallback:
.. doxygenfunction:: ptiViewSetTimestampCallback

.. _ptiViewGetApiIdName:
.. doxygenfunction:: ptiViewGetApiIdName

.. _ptiViewEnableDriverApi:
.. doxygenfunction:: ptiViewEnableDriverApi

.. _ptiViewEnableRuntimeApi:
.. doxygenfunction:: ptiViewEnableRuntimeApi

.. _ptiViewEnableDriverApiClass:
.. doxygenfunction:: ptiViewEnableDriverApiClass

.. _ptiViewEnableRuntimeApiClass:
.. doxygenfunction:: ptiViewEnableRuntimeApiClass

Helper Functions
----------------

.. _ptiViewOverheadKindToString:
.. doxygenfunction:: ptiViewOverheadKindToString

.. _ptiViewMemoryTypeToString:
.. doxygenfunction:: ptiViewMemoryTypeToString

.. _ptiViewMemcpyTypeToString:
.. doxygenfunction:: ptiViewMemcpyTypeToString

Structures
----------

.. _pti_view_record_base:
.. doxygenstruct::   pti_view_record_base
   :members:

.. _pti_view_record_api:
.. doxygenstruct::   pti_view_record_api
   :members:

.. _pti_view_record_kernel:
.. doxygenstruct::   pti_view_record_kernel
   :members:

.. _pti_view_record_memory_copy:
.. doxygenstruct::   pti_view_record_memory_copy
   :members:

.. _pti_view_record_memory_copy_p2p:
.. doxygenstruct::   pti_view_record_memory_copy_p2p
   :members:

.. _pti_view_record_memory_fill:
.. doxygenstruct::   pti_view_record_memory_fill
   :members:

.. _pti_view_record_synchronization:
.. doxygenstruct::   pti_view_record_synchronization
   :members:

.. _pti_view_record_external_correlation:
.. doxygenstruct::   pti_view_record_external_correlation
   :members:

.. _pti_view_record_overhead:
.. doxygenstruct::   pti_view_record_overhead
   :members:

.. _pti_view_record_comms:
.. doxygenstruct::   pti_view_record_comms
   :members:

Enumerators
-----------

.. _pti_result:
.. doxygenenum:: pti_result

.. _pti_view_kind:
.. doxygenenum:: pti_view_kind

.. _pti_view_external_kind:
.. doxygenenum:: pti_view_external_kind

.. _pti_view_overhead_kind:
.. doxygenenum:: pti_view_overhead_kind

.. _pti_view_memory_type:
.. doxygenenum:: pti_view_memory_type

.. _pti_view_memcpy_type:
.. doxygenenum:: pti_view_memcpy_type

.. _pti_view_synchronization_type:
.. doxygenenum:: _pti_view_synchronization_type

.. _pti_api_group_id:
.. doxygenenum:: _pti_api_group_id

.. _pti_api_class:
.. doxygenenum:: _pti_api_class

Function Pointer Typedefs
--------------------------

.. _pti_fptr_buffer_completed:
.. doxygentypedef:: pti_fptr_buffer_completed

.. _pti_fptr_buffer_requested:
.. doxygentypedef:: pti_fptr_buffer_requested

----

API ID Headers
==============

PTI provides header files containing enumeration definitions that map API function names to integer identifiers. These IDs are used in ``pti_view_record_api`` records and with API filtering functions.

pti_driver_levelzero_api_ids.h
-------------------------------

**Header:** ``#include "pti/pti_driver_levelzero_api_ids.h"``

Defines ``_pti_api_id_driver_levelzero`` enum with Level-Zero API function identifiers.

**Enum Type:** ``_pti_api_id_driver_levelzero``

**Example Values:**

* ``zeInit_id`` - zeInit API function
* ``zeCommandListCreate_id`` - zeCommandListCreate API function
* ``zeCommandListAppendLaunchKernel_id`` - zeCommandListAppendLaunchKernel API function
* ``zeCommandListAppendMemoryCopy_id`` - zeCommandListAppendMemoryCopy API function
* ``zeCommandQueueExecuteCommandLists_id`` - zeCommandQueueExecuteCommandLists API function
* ``zeMemAllocDevice_id`` - zeMemAllocDevice API function
* And 300+ more Level-Zero API functions

**API Version:** Generated from Level-Zero v1.28.0 (``ze_api.h``)

**Usage:**

.. code-block:: c++

   #include "pti/pti_driver_levelzero_api_ids.h"

   // Filter to specific Level-Zero API
   ptiViewEnableDriverApi(1, PTI_API_GROUP_LEVELZERO,
                         zeCommandListAppendLaunchKernel_id);

   // Check API ID in record
   if (api_record->_api_id == zeCommandListAppendMemoryCopy_id) {
       // Process memory copy API
   }

.. note::
   This is an auto-generated file. Do not modify manually.

pti_runtime_sycl_api_ids.h
---------------------------

**Header:** ``#include "pti/pti_runtime_sycl_api_ids.h"``

Defines ``_pti_api_id_runtime_sycl`` enum with SYCL runtime (Unified Runtime) API function identifiers.

**Enum Type:** ``_pti_api_id_runtime_sycl``

**Example Values:**

* ``urContextCreate_id`` - urContextCreate API function
* ``urDeviceGet_id`` - urDeviceGet API function
* ``urEnqueueKernelLaunch_id`` - urEnqueueKernelLaunch API function
* ``urEnqueueUSMMemcpy_id`` - urEnqueueUSMMemcpy API function
* ``urEnqueueMemBufferRead_id`` - urEnqueueMemBufferRead API function
* ``urKernelCreate_id`` - urKernelCreate API function
* And 150+ more Unified Runtime API functions

**API Version:** Generated from Unified Runtime v0.12-r0 (``ur_api.h``)

**Usage:**

.. code-block:: c++

   #include "pti/pti_runtime_sycl_api_ids.h"

   // Filter to specific SYCL runtime API
   ptiViewEnableRuntimeApi(1, PTI_API_GROUP_SYCL,
                          urEnqueueKernelLaunch_id);

   // Check API ID in record
   if (api_record->_api_id == urEnqueueUSMMemcpy_id) {
       // Process USM memcpy API
   }

.. note::
   This is an auto-generated file. Do not modify manually.

Common Usage Patterns
----------------------

**Filtering Specific APIs:**

.. code-block:: c++

   #include "pti/pti_view.h"
   #include "pti/pti_driver_levelzero_api_ids.h"

   ptiViewEnable(PTI_VIEW_DRIVER_API);

   // Only trace kernel launches and memory copies
   ptiViewEnableDriverApi(1, PTI_API_GROUP_LEVELZERO,
                         zeCommandListAppendLaunchKernel_id);
   ptiViewEnableDriverApi(1, PTI_API_GROUP_LEVELZERO,
                         zeCommandListAppendMemoryCopy_id);

**Decoding API IDs:**

.. code-block:: c++

   void ProcessRecord(pti_view_record_api* rec) {
       const char* api_name = nullptr;
       ptiViewGetApiIdName(rec->_api_group_id, rec->_api_id, &api_name);

       if (api_name) {
           std::cout << "API: " << api_name << std::endl;
       }

       // Or check specific API
       if (rec->_api_group_id == PTI_API_GROUP_LEVELZERO &&
           rec->_api_id == zeCommandListAppendLaunchKernel_id) {
           std::cout << "Found kernel launch!" << std::endl;
       }
   }

**API ID Naming Convention:**

* **Level-Zero:** ``ze<FunctionName>_id``

  - ``zeInit`` → ``zeInit_id``
  - ``zeCommandListCreate`` → ``zeCommandListCreate_id``

* **SYCL/UR:** ``ur<FunctionName>_id``

  - ``urContextCreate`` → ``urContextCreate_id``
  - ``urEnqueueKernelLaunch`` → ``urEnqueueKernelLaunch_id``

----

.. _callback_api_functions:

Callback API Reference (Experimental)
======================================

.. warning::
   The Callback API is experimental and subject to change. See :doc:`callback_api` for usage guide.

Core Functions
--------------

.. doxygenfunction:: ptiCallbackSubscribe

.. doxygenfunction:: ptiCallbackUnsubscribe

.. doxygenfunction:: ptiCallbackEnableDomain

.. doxygenfunction:: ptiCallbackDisableDomain

.. doxygenfunction:: ptiCallbackDisableAllDomains

Helper Functions
----------------

.. doxygenfunction:: ptiCallbackDomainTypeToString

.. doxygenfunction:: ptiCallbackPhaseTypeToString

Structures
----------

.. doxygenstruct:: _pti_callback_gpu_op_data
   :members:

.. doxygenstruct:: _pti_gpu_op_details
   :members:

.. doxygenstruct:: _pti_internal_callback_data
   :members:

Enumerators
-----------

.. doxygenenum:: _pti_callback_domain

.. doxygenenum:: _pti_callback_phase

.. doxygenenum:: _pti_backend_command_list_type

.. doxygenenum:: _pti_internal_event_type

.. doxygenenum:: _pti_gpu_operation_kind

Typedefs
--------

.. doxygentypedef:: pti_callback_subscriber_handle

.. doxygentypedef:: pti_callback_function
