# THIS FILE DERIVED FROM cuGRAPH's CMakeLists.txt file.
# For more information, please visit:
# https://github.com/yigithanyigit/cugraph/blob/branch-24.12/cpp/CMakeLists.txt

cmake_minimum_required(VERSION 3.26.4 FATAL_ERROR)


# https://stackoverflow.com/questions/13167598/error-cuda-runtime-h-no-such-file-or-directory/75559127#75559127
include(CheckLanguage)
check_language(CUDA)

# Dynamically Check CUDA Architecture
function(detect_cuda_compute_capabilities out_variable)
    set(__cufile "${CMAKE_BINARY_DIR}/detect_cuda_arch.cu")
    set(__cufile_result "${CMAKE_BINARY_DIR}/detect_cuda_arch.txt")
    
    file(WRITE "${__cufile}"
        "#include <stdio.h>\n"
        "int main() {\n"
        "  int count = 0;\n"
        "  if (cudaSuccess != cudaGetDeviceCount(&count)) return -1;\n"
        "  if (count == 0) return -1;\n"
        "  int major = 0, minor = 0;\n"
        "  if (cudaSuccess != cudaDeviceGetAttribute(&major, cudaDevAttrComputeCapabilityMajor, 0)) return -1;\n"
        "  if (cudaSuccess != cudaDeviceGetAttribute(&minor, cudaDevAttrComputeCapabilityMinor, 0)) return -1;\n"
        "  printf(\"%d%d\", major, minor);\n"
        "  return 0;\n"
        "}\n"
    )

    try_run(
        run_result compile_result
        "${CMAKE_BINARY_DIR}" "${__cufile}"
        RUN_OUTPUT_VARIABLE compute_cap
    )

    if(run_result EQUAL 0 AND NOT compute_cap STREQUAL "")
        set(${out_variable} ${compute_cap} PARENT_SCOPE)
    else()
        set(${out_variable} "70" PARENT_SCOPE)  # Default fallback ?????
    endif()
endfunction()

project(louvain_example LANGUAGES CXX CUDA)

enable_language(C)

# Detect and set CUDA architecture
detect_cuda_compute_capabilities(DETECTED_GPU_ARCH)
set(CMAKE_CUDA_ARCHITECTURES ${DETECTED_GPU_ARCH})
message(STATUS "Detected CUDA architecture: ${CMAKE_CUDA_ARCHITECTURES}")

project(louvain_example LANGUAGES CXX CUDA)

# Check compiler versions
if(CMAKE_CUDA_COMPILER_ID STREQUAL "NVIDIA" AND
   CMAKE_CUDA_COMPILER_VERSION VERSION_LESS 11.0)
    message(FATAL_ERROR "CUDA compiler version must be at least 11.0")
endif()

if(CMAKE_CXX_COMPILER_ID STREQUAL "GNU" AND
   CMAKE_CXX_COMPILER_VERSION VERSION_LESS 9.3)
    message(FATAL_ERROR "GCC compiler must be at least 9.3")
endif()

set(CUGRAPH_C_FLAGS "")
set(CUGRAPH_CXX_FLAGS "")
set(CUGRAPH_CUDA_FLAGS "")

if(CMAKE_COMPILER_IS_GNUCXX)
    list(APPEND CUGRAPH_CXX_FLAGS -Werror -Wno-error=deprecated-declarations -Wno-deprecated-declarations -DRAFT_HIDE_DEPRECATION_WARNINGS)
endif(CMAKE_COMPILER_IS_GNUCXX)

message("-- Building for GPU_ARCHS = ${CMAKE_CUDA_ARCHITECTURES}")
list(APPEND CUGRAPH_CUDA_FLAGS --expt-extended-lambda --expt-relaxed-constexpr)
list(APPEND CUGRAPH_CUDA_FLAGS -Werror=cross-execution-space-call -Wno-deprecated-declarations -DRAFT_HIDE_DEPRECATION_WARNINGS -Xptxas=--disable-warnings)
list(APPEND CUGRAPH_CUDA_FLAGS -Xcompiler=-Wall,-Wno-error=sign-compare,-Wno-error=unused-but-set-variable)
#list(APPEND CUGRAPH_CUDA_FLAGS -Xfatbin=-compress-all)

# Find CUDA
find_package(CUDAToolkit REQUIRED)

# Explicitly find cccl
#find_package(CCCL REQUIRED)

# Find RAFT
find_package(raft REQUIRED)

# Find RMM
find_package(rmm REQUIRED)

# Option to enable line info in CUDA device compilation to allow introspection when profiling /
# memchecking
if (CMAKE_CUDA_LINEINFO)
    list(APPEND CUGRAPH_CUDA_FLAGS -lineinfo)
endif()

# Debug options
if(CMAKE_BUILD_TYPE MATCHES Debug)
    message(STATUS "Building with debugging flags")
    list(APPEND CUGRAPH_CUDA_FLAGS -G -Xcompiler=-rdynamic)
endif()

# Set paths to RAPIDS installations
set(RAPIDS_PATH "/home/yigit/miniconda3/envs/cugraph_dev")
set(CUGRAPH_PATH "/home/yigit/cugraph/build")
#set(MMIO_PATH "/home/yigit/cugraph/thirdparty/mmio")
set(MMIO_PATH ${CMAKE_CURRENT_SOURCE_DIR}/thirdparty/mmio)
set(SOURCE_DIR ${CMAKE_CURRENT_SOURCE_DIR}/src)

message(STATUS "MMIO_PATH: ${MMIO_PATH}")

# Include directories
include_directories(
    ${RAPIDS_PATH}/include
    ${CUGRAPH_PATH}/include
    ${CUDAToolkit_INCLUDE_DIRS}
    ${CUGRAPH_PATH}/../thirdparty
    ${MMIO_PATH}
)

# Link directories
link_directories(
    ${RAPIDS_PATH}/lib
    ${CUGRAPH_PATH}/lib
)


add_library(utils STATIC
    ${SOURCE_DIR}/utils/matrix_market_file_utilities.cu
    ${SOURCE_DIR}/utils/csv_file_utilities.cu
    ${SOURCE_DIR}/utils/thrust_wrapper.cu
    ${SOURCE_DIR}/utils/conversion_utilities_mg.cu
    ${SOURCE_DIR}/utils/conversion_utilities_sg.cu
    ${SOURCE_DIR}/utils/thrust_wrapper.cu
    ${SOURCE_DIR}/utils/device_comm_wrapper.cu
    ${MMIO_PATH}/mmio.c
)

target_compile_options(utils
    PRIVATE
    "$<$<COMPILE_LANGUAGE:CXX>:${CUGRAPH_CXX_FLAGS}>"
    "$<$<COMPILE_LANGUAGE:CUDA>:${CUGRAPH_CUDA_FLAGS}>"
)

set_target_properties(utils PROPERTIES
    POSITION_INDEPENDENT_CODE ON
)

target_include_directories(utils PUBLIC
    ${MMIO_PATH}
    ${SOURCE_DIR}/utils
    ${CUGRAPH_PATH}/include
)

target_link_libraries(utils
    PUBLIC
    cugraph
    cudart
    rmm::rmm
    raft::raft
)

# Add executable
add_executable(louvain_example src/louvain.cu)

target_compile_options(louvain_example
            PRIVATE "$<$<COMPILE_LANGUAGE:CXX>:${CUGRAPH_CXX_FLAGS}>"
                    "$<$<COMPILE_LANGUAGE:CUDA>:${CUGRAPH_CUDA_FLAGS}>"                    
)

# Add CUDA runtime API per thread default stream
target_compile_definitions(louvain_example 
                            PRIVATE 
                            CUDA_API_PER_THREAD_DEFAULT_STREAM
                            RAFT_EXPLICIT_INSTANTIATE=ON
                            RMM_CUDA_STREAM_PER_THREAD
                            CUDA_HAS_ATOMICS=1
                            )

set_target_properties(louvain_example 
                        PROPERTIES 
                        CXX_STANDARD 17
                        CXX_STANDARD_REQUIRED ON
                        CUDA_STANDARD 17
                        CUDA_STANDARD_REQUIRED ON
                        CUDA_SEPARABLE_COMPILATION ON
                        CUDA_RESOLVE_DEVICE_SYMBOLS ON
                        POSITION_INDEPENDENT_CODE ON
                        INTERFACE_POSITION_INDEPENDENT_CODE ON
                        )

# Link libraries
target_link_libraries(louvain_example
    PUBLIC
    utils
    cugraph
    cudart
    rmm::rmm
    raft::raft
)