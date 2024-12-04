/*
################################################

Yigithan Yigit 2024

################################################
*/

#include <cugraph/algorithms.hpp>
#include <cugraph/graph.hpp>
#include <cugraph/utilities/high_res_timer.hpp>

#include <raft/core/handle.hpp>
#include <raft/util/cudart_utils.hpp>

#include <rmm/device_uvector.hpp>
#include <rmm/mr/device/cuda_memory_resource.hpp>

#include <algorithm>
#include <iterator>
#include <limits>
#include <numeric>
#include <vector>
#include <iostream>
#include <fstream>

#include "utils/test_graphs.hpp"
#include "utils/conversion_utilities.hpp"


int main(int argc, char** argv) {
    
    int deviceCount;
    cudaGetDeviceCount(&deviceCount);
    if (deviceCount == 0) {
        std::cerr << "No CUDA devices found!" << std::endl;
        exit(1);
    }

    std::cout << "Available CUDA devices: " << deviceCount << std::endl;
    for (int i = 0; i < deviceCount; i++) {
        cudaDeviceProp prop;
        cudaGetDeviceProperties(&prop, i);
        std::cout << "Device " << i << ": " << prop.name << std::endl;
    }

    // Set default device
    cudaError_t error = cudaSetDevice(0);
    if (error != cudaSuccess) {
        std::cerr << "cudaSetDevice failed with error: " << cudaGetErrorString(error) << std::endl;
        exit(EXIT_FAILURE);
    }

    //size_t stackSize = 1 << 24; // Set to 1 MB or appropriate size
    //cudaDeviceSetLimit(cudaLimitStackSize, stackSize);

    //cudaStream_t stream{};
    //cudaStreamCreate(&stream);

    // Device Handle/Context
    //raft::handle_t handle{stream};
    raft::handle_t handle{};
    HighResTimer hr_timer{};

    if (argc < 2) {
        std::cerr << std::endl
        << "Usage: " << argv[0] << " <path to mtx file>" << std::endl
        //<< "Max Level: " 
        << "Example: " << argv[0] << " ../../datasets/karate.mtx" << std::endl;
        exit(1);
    } else {
        std::cout << "Reading graph from file: " << argv[1] << std::endl;
    }

    std::string file_path = argv[1];

    // Check file_path is a valid file path
    std::ifstream
    file(file_path);
    if (!file.good()) {
        std::cerr << "Error: Invalid file path" << std::endl;
        exit(1);
    }

    auto usecase = cugraph::utilities::File_Usecase(file_path);

    RAFT_CUDA_TRY(cudaDeviceSynchronize());  // for consistent performance measurement
    hr_timer.start("Construct graph");

    auto [graph, edge_weights, d_renumber_map_labels] =
      cugraph::utilities::construct_graph<int64_t, int64_t, float, false, false>(
        handle, usecase, true, false);

    hr_timer.stop();
    hr_timer.display_and_clear(std::cout);

    auto graph_view = graph.view();
    auto edge_weight_view =
      edge_weights ? std::make_optional((*edge_weights).view()) : std::nullopt;

    RAFT_CUDA_TRY(cudaDeviceSynchronize());  // for consistent performance measurement
    hr_timer.start("Louvain");
    std::cout << "Running Louvain algorithm" << std::endl;

    try {
        std::cout << "clustering"<< std::endl;
        rmm::device_uvector<int64_t> clustering(
            graph_view.local_vertex_partition_range_size(), 
            handle.get_stream());

        std::cout << "Running Louvain" << std::endl;
        auto [num_levels, modularity] = cugraph::louvain(
            handle, 
            std::optional<std::reference_wrapper<raft::random::RngState>>{std::nullopt},
            graph.view(),
            edge_weight_view,
            clustering.data(),
            20,    // max_level
            // 1e-7f,  // threshold
            1e-2f,  // threshold
            1.0f    // resolution
        );


        std::cout << "Louvain Finished" << std::endl;
        RAFT_CUDA_TRY(cudaDeviceSynchronize());
        hr_timer.stop();
        hr_timer.display_and_clear(std::cout);

        std::cout << "Number of levels: " << num_levels << std::endl;
        std::cout << "Modularity: " << modularity << std::endl;
        
    } catch (raft::exception const& e) {
        std::cerr << "Exception: " << e.what() << std::endl;
        return EXIT_FAILURE;
    } catch (thrust::system_error const& e) {
        std::cerr << "Thrust exception: " << e.what() << std::endl;
        return EXIT_FAILURE;
    } catch (std::exception const& e) {
        std::cerr << "Standard exception: " << e.what() << std::endl;
        return EXIT_FAILURE;
    }

    return 0;
}