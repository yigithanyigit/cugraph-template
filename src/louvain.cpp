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

struct arg_usecase {
  std::string path;
  int max_level;
  float threshold;
  float resolution;
};


int main(int argc, char** argv) {
    arg_usecase au;
    raft::handle_t handle{};
    HighResTimer hr_timer{};

   if (argc < 5) {
         std::cerr << std::endl
         << "Usage: " << argv[0] << " <path to mtx file> <max level> <threshold> <resolution>" << std::endl
         << "Example: " << argv[0] << " ../../datasets/karate.mtx 10 0.5 1.0" << std::endl;
         exit(1);
   } else {
         std::cout << "Reading graph from file: " << argv[1] << std::endl;
         
         au.max_level = std::stoi(argv[2]);
         au.threshold = std::stof(argv[3]);
         au.resolution = std::stof(argv[4]);
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
            au.max_level,
            au.threshold,
            au.resolution     
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
