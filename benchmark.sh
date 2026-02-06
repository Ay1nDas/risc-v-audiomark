#!/bin/bash
# Gemini Generated Benchmark Script
# --- Configuration ---
SOURCE="q15_axpy_challenge.c"
OUTPUT="solution.elf"
RUNS=100
LOGFILE="benchmark_results.txt"
TEMP_DATA="runs_buffer.tmp"

# 1. Compile the code
echo "[*] Compiling..."
riscv64-linux-gnu-gcc -march=rv64gcv -static -O3 "$SOURCE" -o "$OUTPUT"

if [ $? -ne 0 ]; then
    echo "[!] Compilation failed."
    exit 1
fi

# Initialize Stats
total_ref=0
total_rvv=0
count=0

# Initialize Min/Max tracking
min_speedup=1000.0
max_speedup=0.0
best_rvv_cycles=0
worst_rvv_cycles=0

# Clear temp file
> "$TEMP_DATA"

echo "[*] Running $RUNS iterations..."

# 2. Benchmark Loop
for ((i=1; i<=RUNS; i++)); do
    # Capture QEMU output
    out=$(qemu-riscv64 -cpu rv64,v=true,vext_spec=v1.0 ./"$OUTPUT")
    
    # Parse Cycles
    ref=$(echo "$out" | grep "Cycles ref:" | awk '{print $3}')
    rvv=$(echo "$out" | grep "Cycles RVV:" | awk '{print $3}')
    
    # Check Verification Status per run
    if echo "$out" | grep -q "Verify RVV: OK"; then
        verify_status="PASS"
    else
        verify_status="FAIL"
    fi
    
    if [[ -n "$ref" && -n "$rvv" && "$rvv" -ne 0 ]]; then
        # Accumulate totals
        total_ref=$((total_ref + ref))
        total_rvv=$((total_rvv + rvv))
        count=$((count + 1))

        # Calculate speedup for THIS specific run
        curr_speedup=$(awk "BEGIN {printf \"%.4f\", $ref / $rvv}")
        
        # Check Best Run
        is_better=$(awk "BEGIN {print ($curr_speedup > $max_speedup)}")
        if [ "$is_better" -eq 1 ]; then
            max_speedup=$curr_speedup
            best_rvv_cycles=$rvv
        fi

        # Check Worst Run
        is_worse=$(awk "BEGIN {print ($curr_speedup < $min_speedup)}")
        if [ "$is_worse" -eq 1 ]; then
            min_speedup=$curr_speedup
            worst_rvv_cycles=$rvv
        fi

        # Save individual run data to temp file
        # Formatting as a table row
        printf "Run %3d | Ref: %8d | RVV: %8d | Speedup: %6sx | Verify: %s\n" \
               "$i" "$ref" "$rvv" "$curr_speedup" "$verify_status" >> "$TEMP_DATA"
    else
        # Log failed run
        echo "Run $i: Invalid output or error" >> "$TEMP_DATA"
    fi

    # Progress bar
    echo -ne "Progress: $i/$RUNS\r"
done

echo ""
echo "------------------------------"

# 3. Final Calculation & Report Generation
if [ $count -gt 0 ]; then
    # Calculate Averages
    avg_ref=$((total_ref / count))
    avg_rvv=$((total_rvv / count))
    avg_speedup=$(awk "BEGIN {printf \"%.2f\", $avg_ref / $avg_rvv}")
    
    disp_max=$(awk "BEGIN {printf \"%.2f\", $max_speedup}")
    disp_min=$(awk "BEGIN {printf \"%.2f\", $min_speedup}")

    # --- Write to Log File ---
    {
        echo "Total Successful Runs: $count/$RUNS"
        echo ""
        echo "--- Average Performance ---"
        echo "Avg. Cycles Ref:  $avg_ref"
        echo "Avg. Cycles RVV:  $avg_rvv"
        echo "Avg. Speedup:     ${avg_speedup}x"
        echo ""
        echo "--- Extreme Cases ---"
        echo "Best Run:  ${disp_max}x speedup (RVV Cycles: $best_rvv_cycles)"
        echo "Worst Run: ${disp_min}x speedup (RVV Cycles: $worst_rvv_cycles)"
        echo ""
        echo "--------- Individual Run Details ---------"
        echo ""
        # Append the buffered individual results
        cat "$TEMP_DATA"
    } > "$LOGFILE"

    # Print summary to console as well
    echo "Benchmark complete."
    echo "Results saved to: $LOGFILE"
    echo ""
    echo "Summary Preview:"
    echo "Avg Speedup: ${avg_speedup}x"
    echo "Best: ${disp_max}x | Worst: ${disp_min}x"

else
    echo "[!] No successful runs recorded. Check QEMU or code."
fi

# Cleanup
rm -f "$TEMP_DATA"
