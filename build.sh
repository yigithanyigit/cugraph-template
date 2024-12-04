clean() {
    rm -rf build
}

create_dir() {
    mkdir -p build
}

enter() {
    local dir=${1:-src}
    cd "$dir"
}

build() {
    enter src
    create_dir
    enter build
    cmake ../.. -DCMAKE_EXPORT_COMPILE_COMMANDS=1
    make
}

go_base() {
    cd ..
}

clean_and_build() {
    if [ "$(pwd)" = "$(pwd)/build" ]; then
        go_base
    fi
    if [ -d build ]; then
        read -p "Build directory exists. Are you sure you want to clean it? (y/n): " choice
        case "$choice" in 
            y|Y ) echo "Cleaning build directory...";;
            n|N ) echo "Aborting."; exit 1;;
            * ) echo "Invalid choice. Aborting."; exit 1;;
        esac
    fi
    clean
    build
}

main() {
    if [ "$1" = "make" ]; then
        enter src
        enter build
        make
    elif [ "$1" = "clean_and_build" ]; then
        clean_and_build
    else
        echo "Usage: $0 {make|clean_and_build}"
        exit 1
    fi
}

main "$@"
