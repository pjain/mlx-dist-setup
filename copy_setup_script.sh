#!/usr/bin/env bash
set -e

# Source script to copy (the environment setup script)
SRC_SETUP_SCRIPT="/Users/alex/Code/ml/setup_mlxdist.sh"

# Source script to copy (the memory limit script)
SRC_MEMORY_SCRIPT="/Users/alex/Code/ml/set_mem_limit.sh"

# Source script to copy (the MLX run script)
SRC_MLX_SCRIPT="/Users/alex/Code/ml/run_mlx.sh"

# Destination directory on remote machines:
DEST_DIR="/Users/alex/Code/ml"

# List of remote hosts (besides az-ms-1 itself).
# Add more hostnames here if needed (e.g. "az-ms-3", "az-ms-4", etc.)
HOSTS=(
  "az-ms-2"
)

echo "Copying scripts to remote machines..."

for host in "${HOSTS[@]}"; do
  echo "--------------------------------------"
  echo "Copying scripts to $host ..."
  
  # Ensure the destination directory exists on the remote machine:
  ssh "$host" "mkdir -p \"$DEST_DIR\""
  
  # Use scp to copy each file to the remote machine:
  scp "$SRC_SETUP_SCRIPT" "$host:$DEST_DIR/"
  scp "$SRC_MEMORY_SCRIPT" "$host:$DEST_DIR/"
  scp "$SRC_MLX_SCRIPT"  "$host:$DEST_DIR/"
  
  echo "Done copying scripts to $host:$DEST_DIR"
done

echo
echo "All copies complete!"
