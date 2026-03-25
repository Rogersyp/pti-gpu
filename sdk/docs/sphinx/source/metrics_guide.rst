############################
Hardware Metrics Collection
############################

.. warning::
   **DRAFT DOCUMENTATION** - This documentation is currently in draft status and subject to change.

Overview
========

PTI SDK provides two complementary APIs for collecting hardware performance metrics from Intel GPUs:

1. **PTI Metrics Scope API** - Per-kernel metrics collection (recommended for most use cases)
2. **PTI Metrics API** - Device-level metrics collection with time-based or event-based sampling

Both APIs enable you to gather detailed hardware performance counters such as GPU utilization, memory bandwidth, cache statistics, and execution unit activity.

When to Use Each API
====================

Use Metrics Scope API When
---------------------------

The Metrics Scope API is recommended for most profiling scenarios because it automatically correlates metrics with individual kernel executions.

**Best for:**

* Profiling specific kernels in your application
* Understanding per-kernel performance characteristics
* Correlating metrics with kernel names and IDs
* Analyzing kernels with discrete GPU operations
* Comparing performance across different kernel invocations

**Example use cases:**

* "Which kernel is memory-bound?"
* "What is the cache hit rate for this specific kernel?"
* "How does GPU utilization vary across different kernels?"

Use Metrics API When
--------------------

The device-level Metrics API provides continuous sampling across the entire application runtime.

**Best for:**

* Continuous time-based profiling
* System-level performance monitoring
* Event-based metric triggers
* Analyzing overall GPU behavior without kernel granularity

**Example use cases:**

* "What is the average GPU utilization during application runtime?"
* "How does memory bandwidth change over time?"
* "What are the steady-state performance characteristics?"

Available Metrics
=================

Hardware metrics vary by Intel GPU generation. Common metric categories include:

**Compute Metrics**
   * GPU utilization percentage
   * Execution Unit (EU) active/stall/idle time
   * Thread occupancy
   * Waves per SIMD

**Memory Metrics**
   * Memory read/write bandwidth
   * L1/L3 cache hit rates
   * Memory stalls and wait cycles
   * Uncoalesced memory accesses

**Instruction Metrics**
   * Instructions per clock
   * ALU utilization
   * Send instruction statistics
   * Branch/divergence information

**Sampler Metrics**
   * Sampler throughput
   * Texture cache statistics
   * Sampler stalls

**Power and Frequency**
   * GPU power consumption
   * GPU frequency
   * Temperature (if available)

Use ``ptiMetricsGetMetricGroups()`` to discover the available metrics for your specific device and GPU generation.

Metrics Scope API
=================

The Metrics Scope API enables automatic per-kernel hardware metrics collection. This section describes the complete workflow.

Workflow Overview
-----------------

The Metrics Scope API operates in three phases:

1. **Configuration Phase** - Set up devices and metrics to collect
2. **Collection Phase** - Run your GPU workload while metrics are gathered
3. **Evaluation Phase** - Process collected data and extract per-kernel metrics

Configuration Phase
-------------------

**Step 1: Enable Metrics Scope**

Create a scope collection handle:

.. code-block:: c++

   #include "pti/pti_metrics.h"
   #include "pti/pti_metrics_scope.h"

   pti_scope_collection_handle_t scope_handle;
   pti_result result = ptiMetricsScopeEnable(&scope_handle);
   if (result != PTI_SUCCESS) {
       // Handle error
   }

**Step 2: Discover Devices**

Get available GPU devices:

.. code-block:: c++

   // Query device count
   uint32_t device_count = 0;
   ptiMetricsGetDevices(nullptr, &device_count);

   // Get device properties
   std::vector<pti_device_properties_t> devices(device_count);
   ptiMetricsGetDevices(devices.data(), &device_count);

   // Select device (example: use first device)
   pti_device_handle_t device = devices[0]._handle;

**Step 3: Configure Metrics**

Specify which metrics to collect:

.. code-block:: c++

   // Select metrics to collect
   const char* metric_names[] = {
       "GpuTime",           // GPU execution time
       "GpuCoreClocks",     // GPU core clock cycles
       "EuActive",          // Execution unit active time
       "MemoryRead",        // Memory read bandwidth
       "CacheHit"           // Cache hit rate
   };
   size_t metric_count = 5;

   pti_result result = ptiMetricsScopeConfigure(
       scope_handle,
       PTI_METRICS_SCOPE_AUTO_KERNEL,  // Automatic per-kernel collection
       &device,
       1,                               // Number of devices
       metric_names,
       metric_count);

**Step 4: Set Buffer Size**

Configure collection buffer size:

.. code-block:: c++

   // Query estimated buffer size for N scopes
   size_t estimated_buffer_size = 0;
   ptiMetricsScopeQueryCollectionBufferSize(
       scope_handle,
       1000,  // Estimate for 1000 kernel launches
       &estimated_buffer_size);

   // Set the buffer size
   ptiMetricsScopeSetCollectionBufferSize(
       scope_handle,
       estimated_buffer_size);

Collection Phase
----------------

Start metrics collection before running your GPU workload:

.. code-block:: c++

   // Start collection
   ptiMetricsScopeStartCollection(scope_handle);

   // Run your GPU application
   // All kernel launches will be automatically profiled
   run_sycl_kernels();

   // Stop collection
   ptiMetricsScopeStopCollection(scope_handle);

Evaluation Phase
----------------

After collection stops, process the collected data:

**Step 1: Get Collection Buffers**

.. code-block:: c++

   // Get number of collection buffers
   size_t buffer_count = 0;
   ptiMetricsScopeGetCollectionBuffersCount(scope_handle, &buffer_count);

   for (size_t i = 0; i < buffer_count; ++i) {
       void* collection_buffer = nullptr;
       size_t collection_buffer_size = 0;

       ptiMetricsScopeGetCollectionBuffer(
           scope_handle,
           i,
           &collection_buffer,
           &collection_buffer_size);

       // Process this buffer...
   }

**Step 2: Query Metrics Buffer Size**

.. code-block:: c++

   size_t metrics_buffer_size = 0;
   size_t records_count = 0;

   ptiMetricsScopeQueryMetricsBufferSize(
       scope_handle,
       collection_buffer,
       &metrics_buffer_size,
       &records_count);

**Step 3: Calculate Metrics**

.. code-block:: c++

   // Allocate metrics buffer
   std::vector<uint8_t> metrics_buffer(metrics_buffer_size);

   // Calculate metrics from collection buffer
   ptiMetricsScopeCalculateMetrics(
       scope_handle,
       collection_buffer,
       metrics_buffer.data(),
       metrics_buffer_size,
       &records_count);

**Step 4: Get Metadata**

.. code-block:: c++

   pti_metrics_scope_record_metadata_t metadata{};
   metadata._struct_size = sizeof(metadata);

   ptiMetricsScopeGetMetricsMetadata(scope_handle, &metadata);

   // metadata now contains:
   // - _metrics_count: number of metrics per record
   // - _value_types: array of metric value types
   // - _metric_names: array of metric names
   // - _metric_units: array of metric units

**Step 5: Process Records**

.. code-block:: c++

   auto* records = reinterpret_cast<pti_metrics_scope_record_t*>(
       metrics_buffer.data());

   for (size_t j = 0; j < records_count; ++j) {
       std::cout << "Kernel: " << records[j]._kernel_name << std::endl;
       std::cout << "  Kernel ID: " << records[j]._kernel_id << std::endl;
       std::cout << "  Queue: " << records[j]._queue << std::endl;

       // Print each metric value
       for (size_t m = 0; m < metadata._metrics_count; ++m) {
           std::cout << "  " << metadata._metric_names[m] << ": ";

           // Cast based on value type
           switch (metadata._value_types[m]) {
               case PTI_METRIC_VALUE_TYPE_UINT32:
                   std::cout << records[j]._metrics_values[m].ui32;
                   break;
               case PTI_METRIC_VALUE_TYPE_UINT64:
                   std::cout << records[j]._metrics_values[m].ui64;
                   break;
               case PTI_METRIC_VALUE_TYPE_FLOAT32:
                   std::cout << records[j]._metrics_values[m].fp32;
                   break;
               case PTI_METRIC_VALUE_TYPE_FLOAT64:
                   std::cout << records[j]._metrics_values[m].fp64;
                   break;
               case PTI_METRIC_VALUE_TYPE_BOOL8:
                   std::cout << (records[j]._metrics_values[m].b8 ? "true" : "false");
                   break;
               default:
                   std::cout << "unknown";
           }

           std::cout << " " << metadata._metric_units[m] << std::endl;
       }
   }

**Step 6: Cleanup**

.. code-block:: c++

   ptiMetricsScopeDisable(scope_handle);

Complete Example
----------------

Here's a complete working example:

.. code-block:: c++

   #include "pti/pti_metrics.h"
   #include "pti/pti_metrics_scope.h"
   #include <iostream>
   #include <vector>

   void print_kernel_metrics(pti_scope_collection_handle_t scope_handle) {
       size_t buffer_count = 0;
       ptiMetricsScopeGetCollectionBuffersCount(scope_handle, &buffer_count);

       // Get metadata (same for all records)
       pti_metrics_scope_record_metadata_t metadata{};
       metadata._struct_size = sizeof(metadata);
       ptiMetricsScopeGetMetricsMetadata(scope_handle, &metadata);

       for (size_t i = 0; i < buffer_count; ++i) {
           void* collection_buffer = nullptr;
           size_t collection_buffer_size = 0;
           ptiMetricsScopeGetCollectionBuffer(
               scope_handle, i, &collection_buffer, &collection_buffer_size);

           size_t metrics_buffer_size = 0;
           size_t records_count = 0;
           ptiMetricsScopeQueryMetricsBufferSize(
               scope_handle, collection_buffer,
               &metrics_buffer_size, &records_count);

           std::vector<uint8_t> metrics_buffer(metrics_buffer_size);
           ptiMetricsScopeCalculateMetrics(
               scope_handle, collection_buffer,
               metrics_buffer.data(), metrics_buffer_size, &records_count);

           auto* records = reinterpret_cast<pti_metrics_scope_record_t*>(
               metrics_buffer.data());

           for (size_t j = 0; j < records_count; ++j) {
               std::cout << "Kernel: " << records[j]._kernel_name << std::endl;
               for (size_t m = 0; m < metadata._metrics_count; ++m) {
                   std::cout << "  " << metadata._metric_names[m] << ": ";
                   if (metadata._value_types[m] == PTI_METRIC_VALUE_TYPE_UINT64) {
                       std::cout << records[j]._metrics_values[m].ui64;
                   } else if (metadata._value_types[m] == PTI_METRIC_VALUE_TYPE_FLOAT64) {
                       std::cout << records[j]._metrics_values[m].fp64;
                   }
                   std::cout << " " << metadata._metric_units[m] << std::endl;
               }
           }
       }
   }

   int main() {
       pti_scope_collection_handle_t scope_handle;
       ptiMetricsScopeEnable(&scope_handle);

       uint32_t device_count = 0;
       ptiMetricsGetDevices(nullptr, &device_count);
       std::vector<pti_device_properties_t> devices(device_count);
       ptiMetricsGetDevices(devices.data(), &device_count);

       const char* metrics[] = {"GpuTime", "GpuCoreClocks"};
       ptiMetricsScopeConfigure(
           scope_handle, PTI_METRICS_SCOPE_AUTO_KERNEL,
           &devices[0]._handle, 1, metrics, 2);

       size_t buffer_size = 0;
       ptiMetricsScopeQueryCollectionBufferSize(scope_handle, 100, &buffer_size);
       ptiMetricsScopeSetCollectionBufferSize(scope_handle, buffer_size);

       ptiMetricsScopeStartCollection(scope_handle);

       // Run your GPU workload here
       run_my_kernels();

       ptiMetricsScopeStopCollection(scope_handle);

       print_kernel_metrics(scope_handle);

       ptiMetricsScopeDisable(scope_handle);
       return 0;
   }

Device-Level Metrics API
=========================

The device-level Metrics API provides time-based and event-based sampling across your entire application runtime.

Workflow Overview
-----------------

1. Discover devices and available metric groups
2. Configure metric group collection parameters
3. Start collection
4. Run your workload
5. Stop collection
6. Retrieve calculated data

Discovering Devices and Metrics
--------------------------------

**Get Devices:**

.. code-block:: c++

   uint32_t device_count = 0;
   ptiMetricsGetDevices(nullptr, &device_count);

   std::vector<pti_device_properties_t> devices(device_count);
   ptiMetricsGetDevices(devices.data(), &device_count);

   // Print device information
   for (const auto& device : devices) {
       std::cout << "Device: " << device._model_name << std::endl;
       std::cout << "  PCI: " << (int)device._address._domain << ":"
                 << (int)device._address._bus << ":"
                 << (int)device._address._device << "."
                 << (int)device._address._function << std::endl;
   }

**Get Metric Groups:**

.. code-block:: c++

   pti_device_handle_t device = devices[0]._handle;

   uint32_t group_count = 0;
   ptiMetricsGetMetricGroups(device, nullptr, &group_count);

   std::vector<pti_metrics_group_properties_t> groups(group_count);
   ptiMetricsGetMetricGroups(device, groups.data(), &group_count);

   // Print metric groups
   for (auto& group : groups) {
       std::cout << "Metric Group: " << group._name << std::endl;
       std::cout << "  Description: " << group._description << std::endl;
       std::cout << "  Type: " << group._type << std::endl;
       std::cout << "  Metric Count: " << group._metric_count << std::endl;
   }

**Get Metrics in a Group:**

.. code-block:: c++

   auto& group = groups[0];

   // Allocate buffer for metric properties
   group._metric_properties = new pti_metric_properties_t[group._metric_count];

   ptiMetricsGetMetricsProperties(
       group._handle,
       group._metric_properties);

   // Print metrics
   for (uint32_t i = 0; i < group._metric_count; ++i) {
       auto& metric = group._metric_properties[i];
       std::cout << "  Metric: " << metric._name << std::endl;
       std::cout << "    Description: " << metric._description << std::endl;
       std::cout << "    Units: " << metric._units << std::endl;
   }

Configuring Collection
-----------------------

.. code-block:: c++

   pti_metrics_group_collection_params_t params{};
   params._struct_size = sizeof(params);
   params._group_handle = groups[0]._handle;
   params._sampling_interval = 1000000;  // 1ms in nanoseconds
   params._time_aggr_window = 0;

   ptiMetricsConfigureCollection(device, &params, 1);

Starting and Stopping Collection
---------------------------------

.. code-block:: c++

   // Start collection
   ptiMetricsStartCollection(device);

   // Run your workload
   run_application();

   // Stop collection
   ptiMetricsStopCollection(device);

**With Pause/Resume:**

.. code-block:: c++

   // Start paused
   ptiMetricsStartCollectionPaused(device);

   // Resume when ready
   ptiMetricsResumeCollection(device);

   // Can pause anytime
   ptiMetricsPauseCollection(device);

   // Resume again
   ptiMetricsResumeCollection(device);

   // Stop
   ptiMetricsStopCollection(device);

Retrieving Calculated Data
---------------------------

.. code-block:: c++

   pti_metrics_group_handle_t group_handle = groups[0]._handle;

   // Query data size
   uint32_t value_count = 0;
   ptiMetricsGetCalculatedData(device, group_handle, nullptr, &value_count);

   // Allocate buffer
   std::vector<pti_value_t> values(value_count);

   // Get data
   ptiMetricsGetCalculatedData(
       device,
       group_handle,
       values.data(),
       &value_count);

   // Process values
   uint32_t metric_count = groups[0]._metric_count;
   uint32_t sample_count = value_count / metric_count;

   for (uint32_t s = 0; s < sample_count; ++s) {
       std::cout << "Sample " << s << ":" << std::endl;
       for (uint32_t m = 0; m < metric_count; ++m) {
           auto& metric = groups[0]._metric_properties[m];
           pti_value_t& value = values[s * metric_count + m];

           std::cout << "  " << metric._name << ": ";

           switch (metric._value_type) {
               case PTI_METRIC_VALUE_TYPE_UINT64:
                   std::cout << value.ui64;
                   break;
               case PTI_METRIC_VALUE_TYPE_FLOAT64:
                   std::cout << value.fp64;
                   break;
               // Handle other types...
           }

           std::cout << " " << metric._units << std::endl;
       }
   }

Best Practices
==============

Choosing Metrics
----------------

* **Start small** - Begin with a few key metrics (GpuTime, EuActive, MemoryBandwidth)
* **Understand overhead** - More metrics = more overhead (typically 10-30%)
* **Check availability** - Use ``ptiMetricsGetMetricGroups()`` to see what's available
* **Read descriptions** - Metric descriptions explain what they measure

Buffer Management
-----------------

* **Size appropriately** - Query estimated size, then add 20% margin
* **Multiple buffers** - PTI allocates new buffers as needed during collection
* **Process promptly** - Process collection buffers after stopping collection

Performance Considerations
--------------------------

* **Metrics overhead** - Expect 10-30% performance impact during collection
* **Sampling interval** - Lower intervals (more frequent sampling) = more overhead
* **Metric selection** - Fewer metrics = lower overhead
* **Buffer size** - Larger buffers reduce internal processing frequency

Integration with Tracing
-------------------------

You can combine metrics collection with PTI View tracing:

.. code-block:: c++

   // Enable both tracing and metrics
   ptiViewSetCallbacks(buffer_requested, buffer_completed);
   ptiViewEnable(PTI_VIEW_DEVICE_GPU_KERNEL);

   ptiMetricsScopeEnable(&scope_handle);
   ptiMetricsScopeConfigure(/* ... */);
   ptiMetricsScopeStartCollection(scope_handle);

   // Run workload - both tracing and metrics active
   run_kernels();

   ptiViewDisable(PTI_VIEW_DEVICE_GPU_KERNEL);
   ptiMetricsScopeStopCollection(scope_handle);

   // Correlate data using kernel_id fields

Error Handling
--------------

Always check return codes:

.. code-block:: c++

   pti_result result = ptiMetricsScopeEnable(&scope_handle);
   if (result != PTI_SUCCESS) {
       std::cerr << "Failed to enable metrics scope: " << result << std::endl;
       return 1;
   }

Limitations and Known Issues
=============================

Current Limitations
-------------------

* **One metric group per device** - Currently only one metric group can be configured per device
* **AUTO_KERNEL mode only** - USER mode for Metrics Scope is not yet implemented
* **Mutually exclusive metrics** - Some metrics cannot be collected simultaneously
* **Hardware dependencies** - Metric availability varies by GPU generation

Hardware Requirements
---------------------

* Intel GPU with Level Zero driver support
* Level Zero version 1.9.0+ for optimal performance
* Appropriate permissions for accessing performance counters

Troubleshooting
===============

No Metrics Available
--------------------

If ``ptiMetricsGetMetricGroups()`` returns zero groups:

* Check Level Zero driver installation
* Verify GPU hardware support
* Ensure application runs with appropriate permissions
* Check for conflicting profiling tools

Collection Fails
----------------

If ``ptiMetricsScopeStartCollection()`` fails:

* Verify configuration was successful
* Check buffer size is adequate
* Ensure no other tool is using performance counters
* Try reducing number of metrics

Missing Data
------------

If ``records_count`` is zero:

* Ensure kernels actually executed during collection
* Check that collection started before kernel launches
* Verify buffer size is sufficient

Next Steps
==========

* Explore :doc:`samples` for complete working examples
* Review :doc:`metrics_api_ref` for detailed API documentation
* See :doc:`devguide` for integration with tracing
* Check sample code in ``samples/metrics_scope/`` and ``samples/metrics_perf/``
