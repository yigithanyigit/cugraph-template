# Project Build Instructions

This project uses a build script (`build.sh`) to manage the build process. Below are the instructions on how to use the script.

## Prerequisites

Ensure you have the following installed:
- `cugraph_dev` envirioment
- `cccl=2.5.0` cccl for conda envirion
- `cmake`
- `make`


## Install Prerequisites

- Check [Build from source link](https://github.com/yigithanyigit/cugraph/blob/branch-24.12/docs/cugraph/source/installation/source_build.md) for cugraph_env

- `conda install -c conda-forge cccl=2.5.0`

You are done!


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

## License

This project is licensed under the APACHE2.0 License.