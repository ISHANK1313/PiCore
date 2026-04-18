#!/bin/bash
# PiCore Disk Benchmarking Script
# Runs full fio matrix: sequential + random + endurance

set -e
RESULTS_DIR="/home/ishank/bench_results"
FILE="/mnt/data/fiotest"
mkdir -p "$RESULTS_DIR"

echo "=========================================="
echo "  PiCore Disk Benchmark"
echo "  Target: /mnt/data (128GB data drive)"
echo "=========================================="

# Sequential Read/Write — 1MB blocks
echo ""
echo "[1/3] Sequential Read/Write (1MB blocks, 256MB)..."
sudo fio --name=seq_test \
    --ioengine=posixaio \
    --rw=readwrite \
    --bs=1M \
    --size=256M \
    --numjobs=1 \
    --iodepth=1 \
    --directory=/mnt/data \
    --output-format=terse \
    | tee -a "$RESULTS_DIR/disk-seq.txt"

# Random Read/Write — 4K blocks
echo ""
echo "[2/3] Random Read/Write (4K blocks, 128MB, iodepth=4)..."
sudo fio --name=rand_test \
    --ioengine=posixaio \
    --rw=randrw \
    --bs=4k \
    --size=128M \
    --numjobs=1 \
    --iodepth=4 \
    --directory=/mnt/data \
    --output-format=terse \
    | tee -a "$RESULTS_DIR/disk-rand.txt"

# Endurance — sustained write to expose SLC cache exhaustion
echo ""
echo "[3/3] Endurance test (sustained write, 2GB, 120s)..."
sudo fio --name=endurance \
    --ioengine=posixaio \
    --rw=write \
    --bs=1M \
    --size=2G \
    --numjobs=1 \
    --iodepth=1 \
    --directory=/mnt/data \
    --runtime=120 \
    --time_based \
    --status-interval=10 \
    | tee -a "$RESULTS_DIR/disk-endurance.txt"

# Cleanup
rm -f "$FILE"
rm -f /mnt/data/seq_test.* /mnt/data/rand_test.* /mnt/data/endurance.*

echo ""
echo "Results saved to $RESULTS_DIR/"
echo "Key metrics to record:"
echo "  Sequential read BW, Sequential write BW"
echo "  Random read IOPS, Random write IOPS"
echo "  Endurance: note where write speed drops (SLC cache exhaustion)"
