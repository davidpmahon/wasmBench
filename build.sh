#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

function check_cmake() {
    if ! cmake --version >/dev/null; then
        echo "cmake required!"
        exit 1
    fi
}

function check_clang() {
    if ! clang-11 --version >/dev/null; then
        echo "clang-11 required!"
        exit 1
    fi
    if ! clang++-11 --version >/dev/null; then
        echo "clang++-11 required!"
        exit 1
    fi
}

function check_git() {
    if ! git --version >/dev/null; then
        echo "git required!"
        exit 1
    fi
}

function check_rustup() {
    if ! rustup --version>/dev/null; then
        echo "rustup required!"
        exit 1
    fi
}

function check_golang() {
    if ! go version>/dev/null; then
        echo "golang required!"
        exit 1
    fi
}

function check_tinygo() {
    if ! tinygo version>/dev/null; then
        echo "tinygo required!"
        exit 1
    fi
}

function check_wasmer() {
    if ! wasmer --version>/dev/null; then
        echo "wasmer required!"
        exit 1
    fi
}


function prepare_wasmedge() {
    if [ -e thirdparty/wasmedge/.git ]; then
        pushd thirdparty/wasmedge
        git fetch -a
        git reset --hard origin/HEAD
        git submodule update --init --recursive
        make -C build
        popd
    else
        git clone --depth 1 https://github.com/WasmEdge/WasmEdge.git thirdparty/wasmedge
        pushd thirdparty/wasmedge
        git submodule update --init --recursive
        mkdir build
        cd build
        cmake .. -DCMAKE_BUILD_TYPE=Release
        cd ..
        make -C build -j 8
        popd
    fi
}

function prepare_wavm() {
    if [ -e thirdparty/wavm/.git ]; then
        pushd thirdparty/wavm
        git fetch -a
        git reset --hard origin/HEAD
        git submodule update --init --recursive
        cmake -B build . -DCMAKE_BUILD_TYPE=Release
        cmake --build build
        popd
    else
        git clone --depth 1 https://github.com/WAVM/WAVM.git thirdparty/wavm
        pushd thirdparty/wavm
        git submodule update --init --recursive
        cmake -B build . -DCMAKE_BUILD_TYPE=Release
        cmake --build build
        popd
    fi
}



function invoke_cmake() {
    CC=clang-11 CXX=clang++-11 cmake -B build . -DCMAKE_BUILD_TYPE=Release
    cmake --build build
}


function build_rust(){
   rustup target add wasm32-wasi
   pushd rust/benchmark
   cargo +nightly build --target wasm32-wasi --release --no-default-features --features wasm -v
   cp target/wasm32-wasi/release/*.wasm  ~/wasmBench/build/wasm/
   cargo +nightly build  --release -v
   cp target/release/*-r ~/wasmBench/build/native/
   popd 
}

function build_go(){
   pushd golang/src/wasm
   for i in *.go; do
	echo "Compiling : ${i%.*}"
    tinygo build -o "${i%.*}"-g.wasm -target=wasi -wasm-abi=generic -gc=leaking -no-debug ./"$i"
	tinygo build -o "${i%.*}"-g ./"$i"
   done
   cp *.wasm  ~/wasmBench/build/wasm/
   cp *-g ~/wasmBench/build/native/
   popd 
}

function sed_wasm_module() {
    return
    for i in build/wasm/*.wasm; do
        wasm-dis "$i" -o "$i".wat
        sed -i -e 's@"env" "__wasi_@"wasi_snapshot_preview1" "@' "$i".wat
        wasm-as --detect-features --enable-sign-ext --enable-mutable-globals --enable-nontrapping-float-to-int --enable-simd "$i".wat -g -o "$i"
        rm "$i".wat
    done
}

function run_wasm_opt() {
    return
    for i in build/wasm/*.wasm; do
        mv "$i" "$i".orig
        wasm-opt --detect-features --enable-sign-ext --enable-mutable-globals --enable-nontrapping-float-to-int --enable-simd -g -O3 "$i".orig -o "$i"
    done
}

function build_dockers() {
    for i in build/native/*; do
        if [ -f "$i" -a -x "$i" ]; then
            local NAME=$(basename "$i")
            docker rmi "wasm-benchmark/$NAME" || true
            cp "$i" "docker/$NAME"
            pushd docker/
            docker build --build-arg "NAME=$NAME" -t "wasm-benchmark/$NAME" .
            popd
            rm "docker/$NAME"
        fi
    done
}

check_cmake
check_clang
check_git
check_rustup
check_golang
check_tinygo
check_wasmer

prepare_wavm

invoke_cmake
build_rust
build_go

#sed_wasm_module
#run_wasm_opt
build_dockers

