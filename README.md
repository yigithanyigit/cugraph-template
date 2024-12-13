# Project Build Instructions

This project uses a build script (`build.sh`) to manage the build process. Below are the instructions on how to use the script.

## Prerequisites

Ensure you have the following installed:
- `miniconda/anaconda`
- `cmake`
- `make`

## Install Prerequisites

`conda env create --name cugraph_louvain --file <base_path_of_this_repo>/conda/environments/dependency_cuda_12_x`

`conda activate cugraph_louvain`

## Usage

The `build.sh` script provides the following commands:

### `make`

This command will enter the `src/build` directory and run the `make` command to compile the project.

```sh
./build.sh make
```

### `clean_and_build`

This command will clean the existing build directory (if it exists) and then rebuild the project from scratch.

```sh
./build.sh clean_and_build
```

If the build directory already exists, you will be prompted to confirm whether you want to clean it before proceeding with the build.

## Functions

### `clean()`

Removes the `build` directory.

### `create_dir()`

Creates the `build` directory.

### `enter()`

Changes the current directory to the specified directory (default is `src`).

### `build()`

Enters the `src` directory, creates the `build` directory, and runs `cmake` and `make` to build the project.

### `go_base()`

Changes the current directory to the parent directory.

### `clean_and_build()`

Cleans the build directory (after confirmation) and then builds the project.

### `main()`

The main function that parses the command-line arguments and calls the appropriate function.

## Example

To clean and build the project, run:

```sh
./build.sh clean_and_build
```

To simply build the project without cleaning, run:

```sh
./build.sh make
```

---

## runner-louvain.py

`runner-louvain.py` is a Python script designed to run a specified executable with input files from a given directory, process the output, and profile the execution using `nsys`.

### Prerequisites

- Python 3.x
- NVIDIA Nsight Systems (`nsys`)

### Usage

```sh
python runner-louvain.py <executable> <input_dir> <output_dir>
```

### Arguments

- `<executable>`: The path to the executable file to be run.
- `<input_dir>`: The directory containing the input files.
- `<output_dir>`: The directory where the output files will be saved.

### Description

1. The script checks if the specified input and output directories exist.
   - If the output directory does not exist, it will be created.
2. It lists all files in the input directory.
3. For each input file, the script:
   - Runs the executable with the input file and specified parameters (`max_level`, `threshold`, `resolution`).
   - Saves the output of the executable to a file in the output directory.
   - Profiles the execution using `nsys` and saves the profiling report and output to the output directory.

### Example

```sh
python runner.py /path/to/executable /path/to/input_dir /path/to/output_dir
```

### Notes

- Ensure that the `nsys` tool is installed and available in your system's PATH.
- Modify the `max_level`, `threshold`, and `resolution` lists in the script as needed for your specific use case.

