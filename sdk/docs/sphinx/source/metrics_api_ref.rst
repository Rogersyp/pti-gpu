#########################
PTI Metrics API Reference
#########################

.. warning::
   **DRAFT DOCUMENTATION** - This documentation is currently in draft status and subject to change.

This section provides complete API documentation for PTI Metrics and Metrics Scope APIs for hardware performance counter collection.

Overview
========

The PTI SDK provides two complementary metrics APIs:

* **Metrics Scope API** (``pti_metrics_scope.h``) - Per-kernel metrics collection
* **Metrics API** (``pti_metrics.h``) - Device-level metrics collection

Both APIs share common device discovery functions and metric data types.

=================
Metrics Scope API
=================

The Metrics Scope API enables automatic per-kernel hardware metrics collection with minimal code.

Configuration Functions
=======================

ptiMetricsScopeEnable
---------------------

.. doxygenfunction:: ptiMetricsScopeEnable

Allocates and initializes a scope collection handle. This must be called first before any other Metrics Scope functions.

**Example:**

.. code-block:: c++

   pti_scope_collection_handle_t scope_handle;
   pti_result result = ptiMetricsScopeEnable(&scope_handle);
   if (result != PTI_SUCCESS) {
       // Handle error
   }

ptiMetricsScopeConfigure
-------------------------

.. doxygenfunction:: ptiMetricsScopeConfigure

Configures the Metrics Scope collection including target device, collection mode, and metrics to collect.

**Parameters:**

* ``scope_collection_handle`` - Handle from ``ptiMetricsScopeEnable()``
* ``collection_mode`` - Currently only ``PTI_METRICS_SCOPE_AUTO_KERNEL`` supported
* ``devices_to_profile`` - Array of device handles (currently only 1 device supported)
* ``device_count`` - Number of devices (must be 1)
* ``metric_names`` - Array of metric name strings to collect
* ``metric_count`` - Number of metrics in ``metric_names``

**Example:**

.. code-block:: c++

   const char* metrics[] = {"GpuTime", "EuActive", "MemoryRead"};
   pti_result result = ptiMetricsScopeConfigure(
       scope_handle,
       PTI_METRICS_SCOPE_AUTO_KERNEL,
       &device_handle,
       1,
       metrics,
       3);

ptiMetricsScopeQueryCollectionBufferSize
----------------------------------------

.. doxygenfunction:: ptiMetricsScopeQueryCollectionBufferSize

Queries the estimated collection buffer size needed for a given number of kernel launches (scopes).

**Example:**

.. code-block:: c++

   size_t estimated_size = 0;
   ptiMetricsScopeQueryCollectionBufferSize(
       scope_handle,
       1000,  // Estimate for 1000 kernels
       &estimated_size);

ptiMetricsScopeSetCollectionBufferSize
--------------------------------------

.. doxygenfunction:: ptiMetricsScopeSetCollectionBufferSize

Sets the collection buffer size. PTI will allocate additional buffers automatically as needed during collection.

**Example:**

.. code-block:: c++

   ptiMetricsScopeSetCollectionBufferSize(scope_handle, buffer_size);

Collection Functions
====================

ptiMetricsScopeStartCollection
------------------------------

.. doxygenfunction:: ptiMetricsScopeStartCollection

Starts metrics collection. All GPU kernels launched after this call will have metrics collected.

**Example:**

.. code-block:: c++

   ptiMetricsScopeStartCollection(scope_handle);

   // Run GPU workload
   run_kernels();

   ptiMetricsScopeStopCollection(scope_handle);

ptiMetricsScopeStopCollection
------------------------------

.. doxygenfunction:: ptiMetricsScopeStopCollection

Stops metrics collection. No more kernels will be profiled after this call.

Data Retrieval Functions
=========================

ptiMetricsScopeGetCollectionBuffersCount
----------------------------------------

.. doxygenfunction:: ptiMetricsScopeGetCollectionBuffersCount

Returns the number of collection buffers that were filled during the collection phase.

**Example:**

.. code-block:: c++

   size_t buffer_count = 0;
   ptiMetricsScopeGetCollectionBuffersCount(scope_handle, &buffer_count);

ptiMetricsScopeGetCollectionBuffer
-----------------------------------

.. doxygenfunction:: ptiMetricsScopeGetCollectionBuffer

Retrieves a specific collection buffer by index. The buffer contains raw metrics data that must be processed using ``ptiMetricsScopeCalculateMetrics()``.

**Example:**

.. code-block:: c++

   void* collection_buffer = nullptr;
   size_t buffer_size = 0;
   ptiMetricsScopeGetCollectionBuffer(
       scope_handle,
       0,  // Buffer index
       &collection_buffer,
       &buffer_size);

ptiMetricsScopeGetCollectionBufferProperties
--------------------------------------------

.. doxygenfunction:: ptiMetricsScopeGetCollectionBufferProperties

Gets information about a collection buffer including device, number of scopes, and timestamps.

**Example:**

.. code-block:: c++

   pti_metrics_scope_collection_buffer_properties_t props{};
   props._struct_size = sizeof(props);

   ptiMetricsScopeGetCollectionBufferProperties(
       scope_handle,
       collection_buffer,
       &props);

   std::cout << "Scopes in buffer: " << props._num_scopes << std::endl;
   std::cout << "Device: " << props._device_handle << std::endl;

ptiMetricsScopeQueryMetricsBufferSize
--------------------------------------

.. doxygenfunction:: ptiMetricsScopeQueryMetricsBufferSize

Calculates the exact size needed for a metrics buffer to hold all calculated metrics records from a collection buffer.

**Example:**

.. code-block:: c++

   size_t metrics_buffer_size = 0;
   size_t records_count = 0;

   ptiMetricsScopeQueryMetricsBufferSize(
       scope_handle,
       collection_buffer,
       &metrics_buffer_size,
       &records_count);

ptiMetricsScopeCalculateMetrics
--------------------------------

.. doxygenfunction:: ptiMetricsScopeCalculateMetrics

Processes a collection buffer and populates a metrics buffer with calculated per-kernel metrics records.

**Example:**

.. code-block:: c++

   std::vector<uint8_t> metrics_buffer(metrics_buffer_size);
   size_t records_count = 0;

   ptiMetricsScopeCalculateMetrics(
       scope_handle,
       collection_buffer,
       metrics_buffer.data(),
       metrics_buffer_size,
       &records_count);

   // Access records
   auto* records = reinterpret_cast<pti_metrics_scope_record_t*>(
       metrics_buffer.data());

ptiMetricsScopeGetMetricsMetadata
----------------------------------

.. doxygenfunction:: ptiMetricsScopeGetMetricsMetadata

Retrieves metadata describing the metrics in all records, including metric names, types, and units.

**Example:**

.. code-block:: c++

   pti_metrics_scope_record_metadata_t metadata{};
   metadata._struct_size = sizeof(metadata);

   ptiMetricsScopeGetMetricsMetadata(scope_handle, &metadata);

   for (size_t i = 0; i < metadata._metrics_count; ++i) {
       std::cout << metadata._metric_names[i] << " ("
                 << metadata._metric_units[i] << ")" << std::endl;
   }

Cleanup Functions
=================

ptiMetricsScopeDisable
----------------------

.. doxygenfunction:: ptiMetricsScopeDisable

Disables Metrics Scope and frees all associated resources. Must be called when done with metrics collection.

**Example:**

.. code-block:: c++

   ptiMetricsScopeDisable(scope_handle);

Metrics Scope Structures
=========================

pti_metrics_scope_record_t
---------------------------

.. doxygenstruct:: pti_metrics_scope_record_t
   :members:

Contains per-kernel metrics data. The ``_metrics_values`` array contains one value per configured metric.

**Usage:**

.. code-block:: c++

   pti_metrics_scope_record_t* record = /* from metrics buffer */;

   std::cout << "Kernel: " << record->_kernel_name << std::endl;
   std::cout << "Kernel ID: " << record->_kernel_id << std::endl;

   // Access metric values using metadata for interpretation

pti_metrics_scope_record_metadata_t
------------------------------------

.. doxygenstruct:: pti_metrics_scope_record_metadata_t
   :members:

Describes the metrics stored in ``pti_metrics_scope_record_t`` records. Provides metric names, types, and units.

**Important:** User must set ``_struct_size`` before calling ``ptiMetricsScopeGetMetricsMetadata()``.

**Usage:**

.. code-block:: c++

   pti_metrics_scope_record_metadata_t metadata{};
   metadata._struct_size = sizeof(metadata);

   ptiMetricsScopeGetMetricsMetadata(scope_handle, &metadata);

   // metadata._metrics_count now contains the number of metrics
   // metadata._value_types points to array of types
   // metadata._metric_names points to array of names
   // metadata._metric_units points to array of units

pti_metrics_scope_collection_buffer_properties_t
-------------------------------------------------

.. doxygenstruct:: pti_metrics_scope_collection_buffer_properties_t
   :members:

Provides information about a collection buffer.

**Usage:**

.. code-block:: c++

   pti_metrics_scope_collection_buffer_properties_t props{};
   props._struct_size = sizeof(props);

   ptiMetricsScopeGetCollectionBufferProperties(
       scope_handle, collection_buffer, &props);

   std::cout << "Number of scopes: " << props._num_scopes << std::endl;
   std::cout << "Buffer size: " << props._buffer_size << " bytes" << std::endl;

Metrics Scope Enumerations
===========================

pti_metrics_scope_mode_t
-------------------------

.. doxygenenum:: pti_metrics_scope_mode_t

Defines the collection mode for Metrics Scope.

**Values:**

* ``PTI_METRICS_SCOPE_INVALID_MODE`` - Invalid mode (0)
* ``PTI_METRICS_SCOPE_AUTO_KERNEL`` - Automatic per-kernel collection (currently only supported mode)
* ``PTI_METRICS_SCOPE_USER`` - User-controlled scopes (not yet implemented)

----

==========================
Device-Level Metrics API
==========================

The device-level Metrics API provides time-based and event-based metrics sampling across the entire application runtime.

Device Discovery Functions
===========================

ptiMetricsGetDevices
--------------------

.. doxygenfunction:: ptiMetricsGetDevices

Enumerates all devices on the system that support metrics collection.

**Usage Pattern:**

.. code-block:: c++

   // Step 1: Query count
   uint32_t device_count = 0;
   ptiMetricsGetDevices(nullptr, &device_count);

   // Step 2: Allocate buffer
   std::vector<pti_device_properties_t> devices(device_count);

   // Step 3: Get device properties
   ptiMetricsGetDevices(devices.data(), &device_count);

   for (const auto& device : devices) {
       std::cout << "Device: " << device._model_name << std::endl;
   }

Metric Discovery Functions
===========================

ptiMetricsGetMetricGroups
--------------------------

.. doxygenfunction:: ptiMetricsGetMetricGroups

Retrieves all available metric groups for a specific device.

**Usage Pattern:**

.. code-block:: c++

   // Step 1: Query count
   uint32_t group_count = 0;
   ptiMetricsGetMetricGroups(device_handle, nullptr, &group_count);

   // Step 2: Allocate buffer
   std::vector<pti_metrics_group_properties_t> groups(group_count);

   // Step 3: Get group properties
   ptiMetricsGetMetricGroups(device_handle, groups.data(), &group_count);

ptiMetricsGetMetricsProperties
-------------------------------

.. doxygenfunction:: ptiMetricsGetMetricsProperties

Retrieves properties for all metrics in a specific metric group.

**Usage Pattern:**

.. code-block:: c++

   auto& group = groups[0];

   // Allocate buffer for metrics
   group._metric_properties = new pti_metric_properties_t[group._metric_count];

   // Get metric properties
   ptiMetricsGetMetricsProperties(
       group._handle,
       group._metric_properties);

   // Access metric info
   for (uint32_t i = 0; i < group._metric_count; ++i) {
       std::cout << "Metric: " << group._metric_properties[i]._name << std::endl;
   }

Collection Control Functions
=============================

ptiMetricsConfigureCollection
------------------------------

.. doxygenfunction:: ptiMetricsConfigureCollection

Configures metric groups for collection on a specific device.

**Important:** Currently only one metric group per device is supported.

**Example:**

.. code-block:: c++

   pti_metrics_group_collection_params_t params{};
   params._struct_size = sizeof(params);
   params._group_handle = group_handle;
   params._sampling_interval = 1000000;  // 1ms in nanoseconds
   params._time_aggr_window = 0;

   ptiMetricsConfigureCollection(device_handle, &params, 1);

ptiMetricsStartCollection
--------------------------

.. doxygenfunction:: ptiMetricsStartCollection

Starts metrics collection on the specified device.

**Example:**

.. code-block:: c++

   ptiMetricsStartCollection(device_handle);
   run_workload();
   ptiMetricsStopCollection(device_handle);

ptiMetricsStartCollectionPaused
--------------------------------

.. doxygenfunction:: ptiMetricsStartCollectionPaused

Starts metrics collection in paused state. Use ``ptiMetricsResumeCollection()`` to begin actual collection.

**Example:**

.. code-block:: c++

   ptiMetricsStartCollectionPaused(device_handle);
   // Collection is paused

   ptiMetricsResumeCollection(device_handle);
   // Now collecting

ptiMetricsPauseCollection
--------------------------

.. doxygenfunction:: ptiMetricsPauseCollection

Pauses an active metrics collection. Collection can be resumed with ``ptiMetricsResumeCollection()``.

ptiMetricsResumeCollection
---------------------------

.. doxygenfunction:: ptiMetricsResumeCollection

Resumes a paused metrics collection.

ptiMetricsStopCollection
-------------------------

.. doxygenfunction:: ptiMetricsStopCollection

Stops metrics collection. After this, use ``ptiMetricsGetCalculatedData()`` to retrieve results.

Data Retrieval Functions
=========================

ptiMetricsGetCalculatedData
----------------------------

.. doxygenfunction:: ptiMetricsGetCalculatedData

Retrieves calculated metrics data after collection has stopped.

**Usage Pattern:**

.. code-block:: c++

   // Step 1: Query data size
   uint32_t value_count = 0;
   ptiMetricsGetCalculatedData(
       device_handle,
       group_handle,
       nullptr,
       &value_count);

   // Step 2: Allocate buffer
   std::vector<pti_value_t> values(value_count);

   // Step 3: Get data
   ptiMetricsGetCalculatedData(
       device_handle,
       group_handle,
       values.data(),
       &value_count);

   // Process: value_count = num_samples * num_metrics
   uint32_t num_metrics = /* from group properties */;
   uint32_t num_samples = value_count / num_metrics;

Metrics Structures
==================

pti_device_properties_t
------------------------

.. doxygenstruct:: pti_device_properties_t
   :members:

Contains device information including handle, PCI address, model name, and UUID.

pti_pci_properties_t
--------------------

.. doxygenstruct:: pti_pci_properties_t
   :members:

PCI address structure identifying device location.

**Note:** Fields use ``uint8_t`` but domain values can be 0-65535 in practice.

pti_metric_properties_t
------------------------

.. doxygenstruct:: pti_metric_properties_t
   :members:

Describes a single hardware metric including its name, type, value type, and units.

pti_metrics_group_properties_t
-------------------------------

.. doxygenstruct:: pti_metrics_group_properties_t
   :members:

Describes a metric group containing multiple related metrics.

**Important:** The ``_metric_properties`` pointer is initially NULL. User must allocate buffer and call ``ptiMetricsGetMetricsProperties()`` to populate it.

pti_metrics_group_collection_params_t
--------------------------------------

.. doxygenstruct:: pti_metrics_group_collection_params_t
   :members:

Configuration parameters for metric group collection.

**Fields:**

* ``_struct_size`` - Set to ``sizeof(pti_metrics_group_collection_params_t)``
* ``_group_handle`` - Handle of metric group to collect
* ``_sampling_interval`` - For time-based groups, sampling interval in nanoseconds
* ``_time_aggr_window`` - For trace-based groups, aggregation window in nanoseconds

pti_value_t
-----------

.. doxygenstruct:: _pti_value_t
   :members:

Union containing metric value. Cast based on ``pti_metric_value_type``.

**Usage:**

.. code-block:: c++

   pti_value_t value = /* from calculated data */;
   pti_metric_value_type type = /* from metric properties */;

   switch (type) {
       case PTI_METRIC_VALUE_TYPE_UINT64:
           std::cout << value.ui64;
           break;
       case PTI_METRIC_VALUE_TYPE_FLOAT64:
           std::cout << value.fp64;
           break;
       // Handle other types...
   }

Metrics Enumerations
====================

pti_metrics_group_type
-----------------------

.. doxygenenum:: pti_metrics_group_type

Defines the sampling type for a metric group.

**Values:**

* ``PTI_METRIC_GROUP_TYPE_EVENT_BASED`` - Event-based sampling (Query mode)
* ``PTI_METRIC_GROUP_TYPE_TIME_BASED`` - Time-based sampling (Stream mode)
* ``PTI_METRIC_GROUP_TYPE_TRACE_BASED`` - Trace-based sampling (Trace mode)

pti_metric_type
----------------

.. doxygenenum:: pti_metric_type

Categorizes the type of measurement a metric represents.

**Values:**

* ``PTI_METRIC_TYPE_DURATION`` - Time duration measurement
* ``PTI_METRIC_TYPE_EVENT`` - Event count
* ``PTI_METRIC_TYPE_EVENT_WITH_RANGE`` - Event count with min/max range
* ``PTI_METRIC_TYPE_THROUGHPUT`` - Rate measurement
* ``PTI_METRIC_TYPE_TIMESTAMP`` - Timestamp value
* ``PTI_METRIC_TYPE_FLAG`` - Boolean flag
* ``PTI_METRIC_TYPE_RATIO`` - Ratio or percentage
* ``PTI_METRIC_TYPE_RAW`` - Raw counter value
* ``PTI_METRIC_TYPE_IP`` - Instruction pointer

pti_metric_value_type
----------------------

.. doxygenenum:: pti_metric_value_type

Specifies the data type of a metric's value.

**Values:**

* ``PTI_METRIC_VALUE_TYPE_UINT32`` - 32-bit unsigned integer
* ``PTI_METRIC_VALUE_TYPE_UINT64`` - 64-bit unsigned integer
* ``PTI_METRIC_VALUE_TYPE_FLOAT32`` - 32-bit floating point
* ``PTI_METRIC_VALUE_TYPE_FLOAT64`` - 64-bit floating point
* ``PTI_METRIC_VALUE_TYPE_BOOL8`` - 8-bit boolean
* ``PTI_METRIC_VALUE_TYPE_STRING`` - C string (rarely used)
* ``PTI_METRIC_VALUE_TYPE_UINT8`` - 8-bit unsigned integer
* ``PTI_METRIC_VALUE_TYPE_UINT16`` - 16-bit unsigned integer

----

Common Patterns
===============

Pattern: Enumerate All Available Metrics
-----------------------------------------

.. code-block:: c++

   // Get devices
   uint32_t device_count = 0;
   ptiMetricsGetDevices(nullptr, &device_count);
   std::vector<pti_device_properties_t> devices(device_count);
   ptiMetricsGetDevices(devices.data(), &device_count);

   for (const auto& device : devices) {
       std::cout << "Device: " << device._model_name << std::endl;

       // Get metric groups
       uint32_t group_count = 0;
       ptiMetricsGetMetricGroups(device._handle, nullptr, &group_count);
       std::vector<pti_metrics_group_properties_t> groups(group_count);
       ptiMetricsGetMetricGroups(device._handle, groups.data(), &group_count);

       for (auto& group : groups) {
           std::cout << "  Group: " << group._name << std::endl;

           // Get metrics in group
           group._metric_properties = new pti_metric_properties_t[group._metric_count];
           ptiMetricsGetMetricsProperties(group._handle, group._metric_properties);

           for (uint32_t i = 0; i < group._metric_count; ++i) {
               auto& metric = group._metric_properties[i];
               std::cout << "    Metric: " << metric._name
                        << " (" << metric._units << ")" << std::endl;
           }
       }
   }

Pattern: Collect and Process Scope Metrics
-------------------------------------------

.. code-block:: c++

   void collect_and_process_metrics(const char** metrics, size_t metric_count) {
       pti_scope_collection_handle_t scope;
       ptiMetricsScopeEnable(&scope);

       uint32_t device_count = 0;
       ptiMetricsGetDevices(nullptr, &device_count);
       std::vector<pti_device_properties_t> devices(device_count);
       ptiMetricsGetDevices(devices.data(), &device_count);

       ptiMetricsScopeConfigure(
           scope, PTI_METRICS_SCOPE_AUTO_KERNEL,
           &devices[0]._handle, 1, metrics, metric_count);

       size_t buffer_size = 0;
       ptiMetricsScopeQueryCollectionBufferSize(scope, 100, &buffer_size);
       ptiMetricsScopeSetCollectionBufferSize(scope, buffer_size);

       ptiMetricsScopeStartCollection(scope);
       run_workload();
       ptiMetricsScopeStopCollection(scope);

       // Process results
       size_t buffer_count = 0;
       ptiMetricsScopeGetCollectionBuffersCount(scope, &buffer_count);

       pti_metrics_scope_record_metadata_t metadata{};
       metadata._struct_size = sizeof(metadata);
       ptiMetricsScopeGetMetricsMetadata(scope, &metadata);

       for (size_t i = 0; i < buffer_count; ++i) {
           void* collection_buffer;
           size_t collection_buffer_size;
           ptiMetricsScopeGetCollectionBuffer(
               scope, i, &collection_buffer, &collection_buffer_size);

           size_t metrics_buffer_size, records_count;
           ptiMetricsScopeQueryMetricsBufferSize(
               scope, collection_buffer, &metrics_buffer_size, &records_count);

           std::vector<uint8_t> metrics_buffer(metrics_buffer_size);
           ptiMetricsScopeCalculateMetrics(
               scope, collection_buffer,
               metrics_buffer.data(), metrics_buffer_size, &records_count);

           auto* records = reinterpret_cast<pti_metrics_scope_record_t*>(
               metrics_buffer.data());

           for (size_t j = 0; j < records_count; ++j) {
               process_kernel_record(&records[j], &metadata);
           }
       }

       ptiMetricsScopeDisable(scope);
   }

See Also
========

* :doc:`metrics_guide` - Comprehensive guide to metrics collection
* :doc:`samples` - Complete working examples
* :doc:`devguide` - Integration with PTI tracing
