#!/usr/bin/env bash

MODE=wasm

WASMEDGEC=/home/pi/.wasmedge/bin/wasmedgec
WASMEDGE=/home/pi/.wasmedge/bin/wasmedge
WASMER=/usr/local/bin/wasmer
WAVM=thirdparty/wavm/build/bin/wavm
export WAVM_OBJECT_CACHE_DIR=benchmark/wavm/cache
TIMEFORMAT=%4R
COUNT=100

LANG=(
	  c
	  r  #rust
	  g  #go
)

NAME=(
    nop
#    cat-sync
##    nbody
#    nbody-cpp
##    fannkuch-redux
##    mandelbrot
#    mandelbrot-simd-c
##    binary-trees
##    fasta
)

ARGS=(
    0
#    0
    500000
#	500000
    10
    1000
#    15000
    15
    250000
)

#for interpreter
#ARGS=(
#    0
#    0
#    500000
#    500000
#    9
#    1000
#    1000
#    12
#    250000
#)

function prepare() {
    rm -r benchmark
    mkdir -p benchmark/native
    mkdir -p benchmark/wasmedge_interpreter
    mkdir -p benchmark/wasmedge
    mkdir -p benchmark/wavm
    mkdir -p benchmark/wasmer_singlepass
	mkdir -p benchmark/wasmtime
    mkdir -p benchmark/wasmer_cranelift
    mkdir -p benchmark/wasmer_llvm
    mkdir -p benchmark/wasmer_jit
   # mkdir -p benchmark/v8
    mkdir -p benchmark/docker
    mkdir -p $WAVM_OBJECT_CACHE_DIR
   # dd if=/dev/urandom of=benchmark/random bs=4k count=4k
}

function compile() {
    rm -f benchmark/*/*compile.time 
    for ((i=0; i<"${#NAME[@]}"; ++i)); do
	  for ((j=0; j<"${#LANG[@]}"; ++j)); do
       (time "$WASMEDGEC" --enable-all --generic-binary build/"$MODE"/"${NAME[i]}"-"${LANG[j]}".wasm benchmark/wasmedge/"${NAME[i]}"-"${LANG[j]}".so 2>&1) 2>> benchmark/wasmedge/"${NAME[i]}"-"${LANG[j]}"-compile.time || true
	   #(time "$WASMEDGEC"  build/"$MODE"/"${NAME[i]}"-"${LANG[j]}".wasm benchmark/wasmedge/"${NAME[i]}"-"${LANG[j]}".so 2>&1) 2>> benchmark/wasmedge/"${NAME[i]}"-"${LANG[j]}"-compile.time || true
        echo "Built : " benchmark/wasmedge/"${NAME[i]}"-"${LANG[j]}".so
   
       (time "$WAVM" compile --enable simd --format=precompiled-wasm build/"$MODE"/"${NAME[i]}"-"${LANG[j]}".wasm benchmark/wavm/"${NAME[i]}"-"${LANG[j]}".wasm 2>&1) 2>> benchmark/wavm/"${NAME[i]}"-"${LANG[j]}"-compile.time || true
       #(time "$WAVM" compile  --format=precompiled-wasm build/"$MODE"/"${NAME[i]}"-"${LANG[j]}".wasm benchmark/wavm/"${NAME[i]}"-"${LANG[j]}".wasm 2>&1) 2>> benchmark/wavm/"${NAME[i]}"-"${LANG[j]}"-compile.time || true
		echo "Built : " benchmark/wavm/"${NAME[i]}"-"${LANG[j]}".wasm 
       
	   "$WASMER" cache clean 2>&1
       (time "$WASMER" compile --enable-all --singlepass  build/"$MODE"/"${NAME[i]}"-"${LANG[j]}".wasm -o benchmark/wasmer_singlepass/"${NAME[i]}"-"${LANG[j]}".wasmu 2>&1) 2>> benchmark/wasmer_singlepass/"${NAME[i]}"-"${LANG[j]}"-compile.time || true
       #(time "$WASMER" compile --singlepass  build/"$MODE"/"${NAME[i]}"-"${LANG[j]}".wasm -o benchmark/wasmer_singlepass/"${NAME[i]}"-"${LANG[j]}".wasmu 2>&1) 2>> benchmark/wasmer_singlepass/"${NAME[i]}"-"${LANG[j]}"-compile.time || true
       echo "Built : " benchmark/wasmer_singlepass/"${NAME[i]}"-"${LANG[j]}".wasmu
       
	   "$WASMER" cache clean 2>&1
       (time "$WASMER" compile --enable-all --cranelift  build/"$MODE"/"${NAME[i]}"-"${LANG[j]}".wasm -o benchmark/wasmer_cranelift/"${NAME[i]}"-"${LANG[j]}".wasmu 2>&1) 2>> benchmark/wasmer_cranelift/"${NAME[i]}"-"${LANG[j]}"-compile.time || true
       #(time "$WASMER" compile --cranelift  build/"$MODE"/"${NAME[i]}"-"${LANG[j]}".wasm -o benchmark/wasmer_cranelift/"${NAME[i]}"-"${LANG[j]}".wasmu 2>&1) 2>> benchmark/wasmer_cranelift/"${NAME[i]}"-"${LANG[j]}"-compile.time || true
        echo  "Built : " benchmark/wasmer_cranelift/"${NAME[i]}"-"${LANG[j]}".wasmu 
		
	    "$WASMER" cache clean 2>&1
       (time "$WASMER" compile --enable-all --llvm build/"$MODE"/"${NAME[i]}"-"${LANG[j]}".wasm -o benchmark/wasmer_llvm/"${NAME[i]}"-"${LANG[j]}".wasmu 2>&1) 2>> benchmark/wasmer_llvm/"${NAME[i]}"-"${LANG[j]}"-compile.time || true
	   #(time "$WASMER" compile --llvm build/"$MODE"/"${NAME[i]}"-"${LANG[j]}".wasm -o benchmark/wasmer_llvm/"${NAME[i]}"-"${LANG[j]}".wasmu 2>&1) 2>> benchmark/wasmer_llvm/"${NAME[i]}"-"${LANG[j]}"-compile.time || true
		echo  "Built : " benchmark/wasmer_llvm/"${NAME[i]}"-"${LANG[j]}".wasmu 
  
	   (time wasmtime compile --wasm-features all --wasi-modules default -o benchmark/wasmtime/"${NAME[i]}"-"${LANG[j]}".cwasm  build/"$MODE"/"${NAME[i]}"-"${LANG[j]}".wasm 2>&1) 2>> benchmark/wasmtime/"${NAME[i]}"-"${LANG[j]}"-compile.time || true
	   #(time wasmtime compile --wasi-modules default -o benchmark/wasmtime/"${NAME[i]}"-"${LANG[j]}".cwasm  build/"$MODE"/"${NAME[i]}"-"${LANG[j]}".wasm 2>&1) 2>> benchmark/wasmtime/"${NAME[i]}"-"${LANG[j]}"-compile.time || true
	    echo  "Built : " benchmark/wasmtime/"${NAME[i]}"-"${LANG[j]}".cwasm
		
	done  
    done
}

function benchmark_native() {
    echo benchmark_native
    for ((i=0; i<"${#NAME[@]}"; ++i)); do
	for ((k=0; k<"${#LANG[@]}"; ++k)); do
        LOG="benchmark/native/"${NAME[i]}"-"${LANG[k]}".log"
        rm -f "$LOG"
        touch "$LOG"
        for ((j=0; j<$COUNT; ++j)); do
            time "build/native/${NAME[i]}"-"${LANG[k]}" "${ARGS[i]}" >&/dev/null 
        done 2> "$LOG" 
		echo -n "${NAME[i]}"-"${LANG[k]} "
		echo "$(cat "$LOG")" | tr '\n' ' '
		echo
    done
	done
}

function benchmark_wasmedge_interpreter() {
    echo benchmark_wasmedge_interpreter
    for ((i=0; i<"${#NAME[@]}"; ++i)); do
	for ((k=0; k<"${#LANG[@]}"; ++k)); do
        LOG="benchmark/wasmedge_interpreter/"${NAME[i]}"-"${LANG[k]}".log"
        rm -f "$LOG"
        touch "$LOG"
        for ((j=0; j<$COUNT; ++j)); do
            time "$WASMEDGE"  build/"$MODE"/"${NAME[i]}"-"${LANG[k]}".wasm "${ARGS[i]}" >&/dev/null 
        done 2> "$LOG"
		echo -n "${NAME[i]}"-"${LANG[k]} "
		echo "$(cat "$LOG")" | tr '\n' ' '
		echo
    done
	done
}

function benchmark_wasmedge() {
    echo benchmark_wasmedge
    for ((i=0; i<"${#NAME[@]}"; ++i)); do
	 for ((k=0; k<"${#LANG[@]}"; ++k)); do
        LOG="benchmark/wasmedge/"${NAME[i]}"-"${LANG[k]}".log"
        rm -f "$LOG"
        touch "$LOG"
        for ((j=0; j<$COUNT; ++j)); do
            time "$WASMEDGE" --enable-all benchmark/wasmedge/"${NAME[i]}"-"${LANG[k]}".so "${ARGS[i]}" >&/dev/null 
        done 2> "$LOG"
		echo -n "${NAME[i]}"-"${LANG[k]} "
		echo "$(cat "$LOG")" | tr '\n' ' '
		echo
     done
	done
}

function benchmark_wavm() {
    echo benchmark_wavm
    for ((i=0; i<"${#NAME[@]}"; ++i)); do
	for ((k=0; k<"${#LANG[@]}"; ++k)); do

        LOG="benchmark/wavm/"${NAME[i]}"-"${LANG[k]}".log"
        rm -f "$LOG"
        touch "$LOG"
        for ((j=0; j<$COUNT; ++j)); do
            time "$WAVM" run --enable simd --precompiled --abi=wasi benchmark/wavm/"${NAME[i]}"-"${LANG[k]}".wasm "${ARGS[i]}" >&/dev/null 
			#time "$WAVM" run --precompiled --abi=wasi benchmark/wavm/"${NAME[i]}"-"${LANG[k]}".wasm "${ARGS[i]}" >&/dev/null 

        done 2> "$LOG"
		echo -n "${NAME[i]}"-"${LANG[k]} "
		echo "$(cat "$LOG")" | tr '\n' ' '
		echo
    done
	done
}

function benchmark_wasmer_singlepass() {
    echo benchmark_wasmer_singlepass
    for ((i=0; i<"${#NAME[@]}"; ++i)); do
	for ((k=0; k<"${#LANG[@]}"; ++k)); do

        LOG="benchmark/wasmer_singlepass/"${NAME[i]}"-"${LANG[k]}".log"
        rm -f "$LOG"
        touch "$LOG"
        for ((j=0; j<$COUNT; ++j)); do
		    "$WASMER" cache clean >&/dev/null
           time "$WASMER" run --enable-all benchmark/wasmer_singlepass/"${NAME[i]}"-"${LANG[k]}".wasmu "${ARGS[i]}" >&/dev/null 
		  #time benchmark/wasmer_singlepass/"${NAME[i]}"-"${LANG[k]}" "${ARGS[i]}" >&/dev/null 
        done 2> "$LOG"
		echo -n "${NAME[i]}"-"${LANG[k]} "
		echo "$(cat "$LOG")" | tr '\n' ' '
		echo
    done
	done
}


function benchmark_wasmer_cranelift() {
    echo benchmark_wasmer_cranelift
    for ((i=0; i<"${#NAME[@]}"; ++i)); do
	for ((k=0; k<"${#LANG[@]}"; ++k)); do

        LOG="benchmark/wasmer_cranelift/"${NAME[i]}"-"${LANG[k]}".log"
        rm -f "$LOG"
        touch "$LOG"
        for ((j=0; j<$COUNT; ++j)); do
		    "$WASMER" cache clean >&/dev/null
			time "$WASMER" run --enable-all benchmark/wasmer_cranelift/"${NAME[i]}"-"${LANG[k]}".wasmu "${ARGS[i]}" >&/dev/null 
            #time "$WASMER" run benchmark/wasmer_cranelift/"${NAME[i]}"-"${LANG[k]}".wasmu "${ARGS[i]}" >&/dev/null 
			#time benchmark/wasmer_cranelift/"${NAME[i]}"-"${LANG[k]}" "${ARGS[i]}" >&/dev/null
        done 2> "$LOG"
		echo -n "${NAME[i]}"-"${LANG[k]} "
		echo "$(cat "$LOG")" | tr '\n' ' '
		echo
    done
	done
}

function benchmark_wasmer_llvm() {
    echo benchmark_wasmer_llvm
    for ((i=0; i<"${#NAME[@]}"; ++i)); do
	for ((k=0; k<"${#LANG[@]}"; ++k)); do
        LOG="benchmark/wasmer_llvm/"${NAME[i]}"-"${LANG[k]}".log"
        rm -f "$LOG"
        touch "$LOG"
        for ((j=0; j<$COUNT; ++j)); do
		    "$WASMER" cache clean >&/dev/null
			time "$WASMER" run --enable-all benchmark/wasmer_cranelift/"${NAME[i]}"-"${LANG[k]}".wasmu "${ARGS[i]}" >&/dev/null 
            #time "$WASMER" run benchmark/wasmer_llvm/"${NAME[i]}"-"${LANG[k]}".wasmu "${ARGS[i]}" >&/dev/null 
			#time benchmark/wasmer_llvm/"${NAME[i]}"-"${LANG[k]}" "${ARGS[i]}" >&/dev/null
        done 2> "$LOG"
		echo -n "${NAME[i]}"-"${LANG[k]} "
		echo "$(cat "$LOG")" | tr '\n' ' '
		echo
    done
	done
}

function benchmark_wasmer_jit() {
    echo benchmark_wasmer_jit
    for ((i=0; i<"${#NAME[@]}"; ++i)); do
		for ((k=0; k<"${#LANG[@]}"; ++k)); do
			LOG="benchmark/wasmer_jit/"${NAME[i]}"-"${LANG[k]}".log"
			rm -f "$LOG"
			touch "$LOG"
			for ((j=0; j<$COUNT; ++j)); do
			    "$WASMER" cache clean >&/dev/null
				time "$WASMER" run --enable-all  build/"$MODE"/"${NAME[i]}"-"${LANG[k]}".wasm "${ARGS[i]}" >&/dev/null 
				#time "$WASMER" run build/"$MODE"/"${NAME[i]}"-"${LANG[k]}".wasm "${ARGS[i]}" >&/dev/null 
			done 2> "$LOG"	
		echo -n "${NAME[i]}"-"${LANG[k]} "
		echo "$(cat "$LOG")" | tr '\n' ' '
		echo
		done
	done
}

function benchmark_wasmtime() {
    echo benchmark_wasmtime
    for ((i=0; i<"${#NAME[@]}"; ++i)); do
		for ((k=0; k<"${#LANG[@]}"; ++k)); do
			LOG="benchmark/wasmtime/"${NAME[i]}"-"${LANG[k]}".log"
			rm -f "$LOG"
			touch "$LOG"
			for ((j=0; j<$COUNT; ++j)); do
				time wasmtime run --wasm-features all --wasi-modules default --allow-precompiled benchmark/wasmtime/"${NAME[i]}"-"${LANG[k]}".cwasm "${ARGS[i]}" >&/dev/null 
				#time wasmtime run --wasi-modules default --allow-precompiled benchmark/wasmtime/"${NAME[i]}"-"${LANG[k]}".cwasm "${ARGS[i]}" >&/dev/null 
			done 2> "$LOG" 
		echo -n "${NAME[i]}"-"${LANG[k]} "
		echo "$(cat "$LOG")" | tr '\n' ' '
		echo
		done
	done
}



function benchmark_v8() {
    echo benchmark_v8
    for ((i=0; i<"${#NAME[@]}"; ++i)); do
        echo node --experimental-wasi-unstable-preview1 --experimental-wasm-simd v8/index.js build/"$MODE"/"${NAME[i]}".wasm "${ARGS[i]}"
        LOG="benchmark/v8/"${NAME[i]}".log"
        rm -f "$LOG"
        touch "$LOG"
        for ((j=0; j<$COUNT; ++j)); do
            time node --experimental-wasi-unstable-preview1 --experimental-wasm-simd v8/index.js build/"$MODE"/"${NAME[i]}".wasm "${ARGS[i]}" #<benchmark/random 
        done 2> "$LOG"
     #   /usr/bin/time -o "benchmark/v8/"${NAME[i]}".time" --verbose node --experimental-wasi-unstable-preview1 --experimental-wasm-simd v8/index.js build/"$MODE"/"${NAME[i]}".wasm "${ARGS[i]}" <benchmark/random >&/dev/null
    done
}

function benchmark_docker() {
    echo benchmark_docker
    for ((i=0; i<"${#NAME[@]}"; ++i)); do
	 for ((k=0; k<"${#LANG[@]}"; ++k)); do
        LOG="benchmark/docker/"${NAME[i]}"-"${LANG[k]}".log"
        rm -f "$LOG"
        touch "$LOG"
        for ((j=0; j<$COUNT; ++j)); do
            time docker run --rm -a stdin -a stdout -a stderr wasm-benchmark/"${NAME[i]}"-"${LANG[k]}" /root/"${NAME[i]}"-"${LANG[k]}" "${ARGS[i]}" >&/dev/null 
        done 2> "$LOG"
	 echo -n "${NAME[i]}"-"${LANG[k]} "
	 echo "$(cat "$LOG")" | tr '\n' ' '
	 echo
	 done	
    done
}


function print_compileTime() {
    CURRENT_TIME=$(date)
	echo -n " , , " 
    for name in "${NAME[@]}"; do
        echo -n ,"$name"
    done
    echo
    for lang in "${LANG[@]}"; do 
		for type in  wasmedge wavm wasmer_singlepass wasmer_cranelift wasmer_llvm wasmtime; do
		    echo -n "$CURRENT_TIME "
			echo -n ,"$type "
			echo -n ,"$lang " 
			for name in "${NAME[@]}"; do
				echo -n , "$(awk 'function abs(x){return ((x < 0.0) ? -x : x)} {sum+=$0; sumsq+=($0)^2} END {mean = sum / NR; error = sqrt(abs(sumsq / NR - mean^2)); printf("%.3f,%.3f", mean, error)}' benchmark/"$type"/"$name"-"$lang"-compile.time)"
			done
			echo
		done
        echo
    done | tee -a compile.csv
}


function print_result() {
    CURRENT_TIME=$(date)
	echo -n " , , " 
    for name in "${NAME[@]}"; do
        echo -n ,"$name"
    done
    echo
    for lang in "${LANG[@]}"; do 
		#for type in native docker; do
		for type in native docker wasmedge wavm wasmer_singlepass wasmer_cranelift wasmer_jit wasmer_llvm wasmtime; do
		    echo -n "$CURRENT_TIME "
			echo -n ,"$type "
			echo -n ,"$lang " 
			for name in "${NAME[@]}"; do
				echo -n , "$(awk 'function abs(x){return ((x < 0.0) ? -x : x)} {sum+=$0; sumsq+=($0)^2} END {mean = sum / NR; error = sqrt(abs(sumsq / NR - mean^2)); printf("%.3f,%.3f", mean, error)}' benchmark/"$type"/"$name"-"$lang".log)"
			done
			echo
		done
        echo
    done | tee -a result.csv
}

prepare
#compile
benchmark_native
benchmark_docker
#benchmark_wasmedge
#benchmark_wavm
#benchmark_wasmer_singlepass
#benchmark_wasmer_cranelift
#benchmark_wasmer_llvm
#benchmark_wasmer_jit
#benchmark_wasmtime

#print_compileTime
print_result
