# RISC-V Audiomark Challenge

## Solution Access
* **Source Code:** [q15_axpy_challenge.c](./q15_axpy_challenge.c)
* **Compiler Explorer (Godbolt):** [https://godbolt.org/z/eshjzKGea](https://godbolt.org/z/eshjzKGea)
* **Design Documentation:** For detailed reasoning and speedup calculations, please refer to **[Design-choice-risc-v](https://docs.google.com/document/d/16pkQ0LCTJscsu2C4HSXvsKPXf_hGvkqrWuQx8-RCWPs/edit?usp=sharing)**.

## How to Run (QEMU)

Designed to run on RISC-V supporting the RV64GCV extension. Verified using QEMU.

### 1. Compile
Use `riscv64-linux-gnu-gcc` with the vector extension enabled (`rv64gcv`).
```bash
riscv64-linux-gnu-gcc -march=rv64gcv -static -O3 q15_axpy_challenge.c -o solution.elf
```

#### 2. Run Details
```text
Cycles ref: 310959
Verify RVV: OK (max diff = 0)
Cycles RVV: 734448
```

### 3. Benchmarking
Benchmarking script `benchmark.sh` automate multiple runs and log results.
Test results [benchmark_results.txt](./benchmark_results.txt) show average cycles and speedup achieved.

### 4. Notes
The achieved speedup with QEMU is ~0.45x. Due to QEMU's overhead in emulating RISC-V vector efficiently.
