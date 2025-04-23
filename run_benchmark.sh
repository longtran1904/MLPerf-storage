# Set up logging
LOGFILE="benchmark_run_$(date +%Y%m%d_%H%M%S).log"
exec > >(tee -a "$LOGFILE") 2>&1

echo "Script started at $(date)"

declare -a batch_sizes=(1)
declare -a num_threads=(4)

FlushDisk() {
    echo "Flushing disk caches..."
    sudo sh -c "echo 3 > /proc/sys/vm/drop_caches && sync && echo 3 > /proc/sys/vm/drop_caches && sync"
    sleep 5
}

for batch_size in "${batch_sizes[@]}"; do
        for num_thread in "${num_threads[@]}"; do
                FlushDisk
                sed -i "s/^batch_size: .*/batch_size: ${batch_size}/" /storage-conf/workload/cloudlab_unet3d_h100.yaml
                sed -i "s/^num_threads: .*/num_threads: ${num_thread}/" /storage-conf/workload/cloudlab_unet3d_h100.yaml
                echo "Running benchmark with batch size: ${batch_size} and num threads: ${num_thread}"
                RESULTDIR="resultsdir/batch_size_${batch_size}_num_threads_${num_thread}"

                ./benchmark.sh run \
                        --hosts localhost \
                        --workload cloudlab_unet3d \
                        --accelerator-type h100 \
                        --num-accelerators 1 \
                        --results-dir $RESULTDIR \
                        --param dataset.num_files_train=2000 \
                        --param dataset.data_folder=unet3d_data
        done
done