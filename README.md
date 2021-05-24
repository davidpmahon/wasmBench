# wasm-benchmark

wasm32-wasi benchmarks

all benchmarking C/C++ source are comming from [The Computer Langeuage Benchmarks Game](https://benchmarksgame-team.pages.debian.net/benchmarksgame/index.html).

# Requirement

Use the `configure.sh` to install the following dependencies for this benchmark.
Or you can follow the installation intructions from these website to setup your working environment.

* [Clang 11](https://clang.llvm.org/)
* [LLD 11](https://lld.llvm.org/)
* [emscripten](https://github.com/emscripten-core/emsdk)
* [nodejs v16.1.0](https://nodejs.org/en/)

# Recent Benchmark Results

Runs on Intel(R) Xeon(R) CPU E5-2673 v4 @ 2.30GHz, 5.8.0-1027-azure

| compile time      | WasmEdge | lucet | WAVM  | WasmerSinglePass | WasmerCranelift | WasmerLLVM |
| ----------------: | -------: | ----: | ----: | ---------------: | --------------: | ---------: |
| nop               | 0.430    | 0.039 | 0.228 | 0.017            | 0.025           | 0.215      |
| cat-sync          | 0.562    | 0.049 | 0.315 | 0.019            | 0.025           | 0.219      |
| nbody-c           | 1.921    | 0.207 | 1.478 | 0.029            | 0.106           | 1.425      |
| nbody-cpp         | 8.476    | 0.313 | 5.779 | 0.099            | 0.172           | 1.723      |
| fannkuch-redux-c  | 2.415    | 0.206 | 1.468 | 0.028            | 0.106           | 1.407      |
| mandelbrot-c      | 1.930    | 0.198 | 1.480 | 0.031            | 0.104           | 1.441      |
| mandelbrot-simd-c | 1.941    | 0.004 | 1.500 | 0.022            | 0.115           | 1.471      |
| binary-trees-c    | 1.908    | 0.209 | 1.372 | 0.024            | 0.090           | 1.323      |
| fasta             | 0.496    | 0.039 | 0.279 | 0.016            | 0.021           | 0.187      |

| execution time    | native        | WasmEdge      | lucet         | WAVM          | WasmerSinglePass | WasmerCranelift  | WasmerLLVM      | WasmerJIT     | node16        |
| ----------------: | ------------: | ------------: | ------------: | ------------: | ---------------: | ---------------: | --------------: | ------------: | ------------: |
| nop               | 0.001(0.000)  | 0.009(0.002)  | 0.010(0.012)  | 0.028(0.006)  | 0.008(0.003)     | 0.006(0.000)     | 0.006(0.001)    | 0.010(0.007)  | 0.061(0.001)  |
| cat-sync          | 0.003(0.001)  | 0.012(0.001)  | 0.012(0.002)  | 0.030(0.001)  | 0.013(0.002)     | 0.013(0.001)     | 0.012(0.002)    | 0.015(0.006)  | 0.062(0.003)  |
| nbody-c           | 4.409(0.030)  | 4.977(0.169)  | 7.146(0.125)  | 4.917(0.142)  | 17.572(0.318)    | 6.964(0.057)     | 5.301(0.127)    | 6.919(0.141)  | 4.253(0.054)  |
| nbody-cpp         | 4.149(0.056)  | 4.941(0.111)  | 7.832(0.068)  | 4.362(0.046)  | 17.029(0.264)    | 7.146(0.091)     | 6.160(0.171)    | 7.425(0.154)  | 5.536(0.072)  |
| fannkuch-redux-c  | 34.207(0.633) | 40.827(0.568) | 84.599(1.197) | 38.752(0.638) | 95.409(1.886)    | 88.059(0.460)    | 49.302(1.163)   | 88.617(1.881) | 39.999(0.905) |
| mandelbrot-c      | 10.377(0.193) | 16.545(0.297) | failed        | 15.761(0.245) | 61.805(0.854)    | 24.382(0.409)    | 25.620(0.258)   | 24.403(0.440) | 13.921(0.271) |
| mandelbrot-simd-c | 4.979(0.111)  | 6.510(0.061)  | failed        | 6.243(0.092)  | failed           | 7.682(0.098)     | 17.444(0.093)   | 0.007(0.001)  | 5.284(0.064)  |
| binary-trees-c    | 21.669(0.267) | 17.418(0.414) | failed        | 19.841(0.493) | 56.769(0.505)    | 42.824(0.432)    | 19.469(0.304)   | 43.933(0.442) | 24.055(0.425) |
| fasta-c           | 2.043(0.038)  | 2.896(0.058)  | 5.316(0.130)  | 2.230(0.043)  | 7.529(0.118)     | 7.818(0.066)     | 2.280(0.056)    | 8.049(0.057)  | 4.703(0.068)  |
