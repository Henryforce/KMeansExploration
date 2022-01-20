//
//  KMeans.metal
//  KMeansExploration
//
//  Created by Henry Javier Serrano Echeverria on 15/1/22.
//

#include <metal_stdlib>
#include <metal_atomic>
using namespace metal;

kernel void findLabel(
    const device float *data [[ buffer(0) ]],
    device uint32_t *labels [[ buffer(1) ]],
    const device float *centers [[ buffer(2) ]],
    const device uint32_t& cluster_count [[ buffer(3) ]],
    const device uint32_t& data_count [[ buffer(4) ]],
    const device uint32_t& dimensions [[ buffer(5) ]],
    const device float& max_value [[ buffer(6) ]],
    uint id [[ thread_position_in_grid ]]
) {
    if (id >= data_count) { return; }
    
    uint32_t label = 0;
    float kernel_distance = max_value;
    uint32_t index = 0;
    uint32_t centerIndex = 0;
    float distance = 0.0;

    for(uint32_t cluster_id = 0; cluster_id < cluster_count; cluster_id++) {
        distance = 0.0;
        index = id * dimensions;
        centerIndex = cluster_id * dimensions;

        for (uint32_t j = 0; j < dimensions; j++) {
            const float diff = centers[centerIndex] - data[index];
            distance += diff * diff;
            index++;
            centerIndex++;
        }

        if (distance < kernel_distance) {
            kernel_distance = distance;
            label = cluster_id;
        }
    }
    
    labels[id] = label;
}

// There will be 32 threads per threadgroup.
// A maximum of 32 clusters will be supported in this implementation. Each thread in the group will deal
// with one cluster at a time.
// There will be d (dimensions) threadgroups at most. Each threadgroup will only deal with one dimension.
kernel void updateCenters(
    const device float *data [[ buffer(0) ]],
    device uint32_t *labels [[ buffer(1) ]],
    device float *centers [[ buffer(2) ]],
    const device uint32_t& cluster_count [[ buffer(3) ]],
    const device uint32_t& data_count [[ buffer(4) ]],
    const device uint32_t& dimensions [[ buffer(5) ]],
    const device float& threshold [[ buffer(6) ]],
    volatile device atomic_uint& didChange [[ buffer(7) ]],
    uint dimension_id [[ threadgroup_position_in_grid ]],
    uint lane_id [[thread_index_in_simdgroup]]
) {
    const uint max_clusters_count = 32;
    const uint max_elements_per_thread = 32;
    
    // each thread will pick up a maximum of elements to process
    const uint elements_to_process = (data_count + max_elements_per_thread - 1) / max_elements_per_thread;
    
    // allocate clustercount array for each thread
    uint cluster_counts[max_clusters_count];
    float center_means[max_clusters_count];
    
    // update value for each matching cluster in this thread
    const uint base_index = lane_id * elements_to_process;
    for (uint i = 0; i < elements_to_process; i++) {
        // TODO: verify indexes
        const uint label_index = base_index + i;
        const uint data_index = label_index * dimensions + dimension_id;
        
        if (data_index >= data_count * dimensions) { break; } // This can create divergence
        
        const float value = data[data_index];
        const uint label = labels[label_index];
        
        center_means[label] += value;
        cluster_counts[label] += 1;
    }
    
    // loop for each cluster, fetch the mean and count of each cluster in this thread
    // concurrently sum the local mean and local count using simd_sum (sync before this)
    // each corresponding thread will then fetch the sum and assign it if it matches its respective id
    for (uint cluster_id = 0; cluster_id < cluster_count; cluster_id++) {
        // all threads need to be synchronized at this point
        threadgroup_barrier(mem_flags::mem_threadgroup);
        
        const uint local_count = cluster_counts[cluster_id];
        const float local_raw_mean = center_means[cluster_id];
        
        // sum all local counts and means concurrently in this simd group
        const uint32_t count = simd_sum(local_count);
        const float raw_mean = simd_sum(local_raw_mean);
        
        // Only the corresponding lane_id thread can update a center
        if (cluster_id == lane_id) {
            // TODO: verify indexes
            const uint center_index = cluster_id * dimensions + dimension_id;
            
            const float old_center_value = centers[center_index];
            
            const float mean = count > 0 ? raw_mean / float(count) : 0.0f;
            
            const float diff = abs(old_center_value - mean);
            if (diff > threshold) {
                atomic_fetch_add_explicit(&didChange, 1, memory_order_relaxed);
            }
            
            centers[center_index] = mean;
        }
    }
}

//kernel void findLabelOld(
//    const device float *inVector [[ buffer(0) ]],
//    device float *outVector [[ buffer(1) ]],
//    volatile device atomic_int *result [[ buffer(2) ]],
//    const device uint& lengthVector [[ buffer(3) ]],
//    uint id [[ thread_position_in_grid ]]
//) {
//    if ( id >= lengthVector ) {
//        return;
//    }
//    
////    float input = inVector[id];
////    outVector[id] = input * 2.0;
//////    outVector[id] = float(lengthVector);
////    const int val = 1;
////    atomic_fetch_add_explicit(result, val, memory_order_relaxed);
//    
//    
////    simd_prefix_inclusive_sum(inVector[id]);
//    float input = inVector[id];
////    outVector[id] = simd_shuffle_up(input, 1);
////    if (id == 0) {
////        outVector[id] += simd_shuffle_up(input, 1);
////    }
////    outVector[id] = simd_shuffle(input, 5);
////    outVector[id] = simd_prefix_inclusive_sum(input);
////    outVector[id] = simd_broadcast_first(input);
//    outVector[id] = simd_sum(input);
//}
