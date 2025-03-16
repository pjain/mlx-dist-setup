# MLX Distributed Setup and Usage

This project contains a set of scripts to help you set up a distributed environment using **Open MPI** and **mlx-lm** on macOS machines (e.g., Apple Silicon) and run a distributed LLM inference job across multiple hosts.

## Overview of Scripts (for running sequence, see next section)

1. **`setup_mlxdist.sh`**  
   - **Purpose**: Creates (or re-creates) a clean conda environment named `mlxdist` with Python 3.12, installs Open MPI and `mlx-lm`, downloads `pipeline_generate.py`, and generates a `hosts.json` file.  
   - **Important**:  
     - Any existing conda environment named **`mlxdist`** will be **removed** and replaced.  
     - The project folder `/Users/alex/Code/ml/mlxdist` is also cleared out before setup.  
   - **Where to run**: Typically on **each** machine (e.g., `host1` and `host2`) if you want the same environment on each.

2. **`copy_setup_script.sh`**  
   - **Purpose**: Copies the setup scripts (and optionally other scripts) from one machine to the same path on remote machines.  
   - **Where to run**: On the **main** machine (e.g., `host1`) that has the scripts in `/Users/alex/Code/ml/`. It will SSH and `scp` them to other hosts.  
   - **Key actions**:
     - Copies `setup_mlxdist.sh`, `set_mem_limit.sh`, and `run_mlx.sh` to `/Users/alex/Code/ml/` on each remote machine in the `HOSTS` array.

3. **`set_mem_limit.sh`**  
   - **Purpose**: Raises the wired memory limit for Apple Silicon devices (e.g., M2 Ultra) by calling `sudo sysctl iogpu.wired_limit_mb=XXXXXX`.  
   - **Where to run**: On **each** machine that needs the memory limit raised.  
   - **Key actions**:
     - Sets `iogpu.wired_limit_mb` to the specified number of MB.  
     - **Note**: This setting **only** works for the **current terminal session**. Once you close the shell or reboot, you’ll lose the setting unless you run this script again or add it to a startup process.  
     - Requires `sudo` and will reset on reboot or new shell.

4. **`run_mlx.sh`**  
   - **Purpose**: Activates the `mlxdist` environment, then launches a distributed MLX job using `mlx.launch` with MPI.  
   - **Where to run**: On the machine from which you want to **launch** the distributed job (the “controller” node).  
   - **Key actions**:
     - Sources your conda setup script so `conda activate` works properly.  
     - Activates `mlxdist`.  
     - **By default**, exports `OMPI_MCA_btl_tcp_if_include=en0` to ensure MPI uses the correct network interface (avoid link‐local addresses).  
     - Runs `mlx.launch` with your chosen prompt, tokens, and model.

## Network Interface Considerations

- Most macOS systems with a single wired or Wi-Fi interface call it **`en0`**.  
- If your internet connection is on **another interface** (e.g., `en1`, `en2`, `eth0`, etc.), you need to update the `run_mlx.sh` script or your environment variable to match.  
- **How to check**: run `ifconfig` (or `ip addr` if you have the command) in the terminal and look for the interface that has your active IP address. For example, if you see:
  ```
  en1: flags=8863<UP,BROADCAST,RUNNING,SIMPLEX,MULTICAST> mtu 1500
          inet 192.168.1.10 netmask 0xffffff00 broadcast 192.168.1.255
          ...
  ```
  then you should set:
  ```bash
  export OMPI_MCA_btl_tcp_if_include=en1
  ```
- After identifying your primary interface, **edit** `run_mlx.sh` (or set the environment variable) so that it reads:
  ```bash
  export OMPI_MCA_btl_tcp_if_include=en1
  ```
  instead of `en0`, if that’s the interface carrying your traffic.

## Prerequisites

1. **SSH must be set up for passwordless login** among all machines.  
   - Ensure `ssh <hostname>` works **without** prompting for a password or passphrase (using SSH keys).  
   - Each node must be able to SSH to every other node.  
2. **Conda installed and initialized** on each machine (so `conda activate` commands work).  
3. **Matching environment paths** (the scripts assume `/Users/alex/miniconda3/envs/mlxdist/bin/python` on each machine).  
4. **macOS firewall** or other firewalls must allow MPI traffic across the network interface.  
5. **Confirm the correct interface** (by default, we assume `en0`). If needed, adjust to `en1` or another interface in `run_mlx.sh`.

## Enabling SSH and Changing Hostname

### Enabling SSH

1. **Open System Preferences**:
   - Go to `System Preferences` > `Sharing`.
2. **Enable Remote Login**:
   - Check the box next to `Remote Login`.
   - This will allow SSH access to your machine.
3. **Allow Access for All Users or Specific Users**:
   - You can choose to allow access for all users or specify which users can log in.

### Changing Hostname

1. **Open Terminal**:
   - You can find Terminal in `Applications` > `Utilities` or by searching for it in Spotlight.
2. **Change the Hostname**:
   - Run the following command to change the hostname:
     ```bash
     sudo scutil --set HostName <new-hostname>
     ```
     Replace `<new-hostname>` with your desired hostname.
3. **Verify the Change**:
   - Run the following command to verify the change:
     ```bash
     hostname
     ```
     This should display the new hostname you set.

## Order of Operations

Below is a suggested workflow for **two machines** (`host1` and `host2`). Adjust as needed for more machines.

1. **On the primary machine (e.g., `host1`)**:
   1. **Ensure conda is installed** and initialized (`conda init`). Make sure `conda activate` works in your shell.  
   2. **Run `copy_setup_script.sh`** to copy these scripts (including `setup_mlxdist.sh`, `run_mlx.sh`, `set_mem_limit.sh`) to the **other** machine(s):
      ```bash
      ./copy_setup_script.sh
      ```
   3. **Run `setup_mlxdist.sh`** (if you want to set up the environment on this machine). For example:
      ```bash
      cd /Users/alex/Code/ml
      ./setup_mlxdist.sh
      ```
      > **Note**: This will remove any existing `mlxdist` conda environment and recreate it.  
   4. **Run `set_mem_limit.sh`** (if you need more memory for iogpu on an M-series Mac):
      ```bash
      ./set_mem_limit.sh
      ```
      Remember, the setting will revert on reboot or new session.  
   5. **SSH** into the other machine(s) to continue setup.

2. **On the secondary machine(s) (e.g., `host2`)**:
   1. **SSH** from `host1` or open a terminal on `host2`.  
   2. **Run `setup_mlxdist.sh`** to create the same `mlxdist` environment:
      ```bash
      cd /Users/alex/Code/ml
      ./setup_mlxdist.sh
      ```
   3. **Run `set_mem_limit.sh`** (if needed for memory on Apple Silicon):
      ```bash
      ./set_mem_limit.sh
      ```
      Again, this setting won’t persist across reboots or new shells.  
   4. Ensure you have the **same** environment path `/Users/alex/miniconda3/envs/mlxdist` on each machine.

3. **Check SSH connectivity**:
   - Ensure you can SSH passwordlessly between `host1` and `host2`. This is essential for MPI.  
   
4. **Launch the distributed job**:
   - On the machine you wish to run the job from (e.g., `host1`), use:
     ```bash
     cd /Users/alex/Code/ml/mlxdist
     ./run_mlx.sh
     ```
   - This script will:
     - Activate `mlxdist`.  
     - Force MPI to use the specified interface (default `en0`; change it if your active connection is on `en1` or something else).  
     - Run `mlx.launch --backend mpi ...` with your `pipeline_generate.py` across both machines listed in `hosts.json`.  

If everything is configured correctly, MPI will start processes on both `host1` and `host2`, and you’ll see the generated output.

## Troubleshooting

- **Firewall**: macOS’s firewall can block inbound connections for MPI. If you see errors about “failed to TCP connect,” disable or configure the firewall to allow inbound ephemeral ports.  
- **Link-Local Addresses**: If MPI tries to use `169.254.x.x` addresses, confirm your **interface** setting. By default, `run_mlx.sh` sets `OMPI_MCA_btl_tcp_if_include=en0`. If your actual active IP is on `en1`, update that line to `en1`.  
- **Missing Conda Environment**: Make sure `/Users/alex/miniconda3/envs/mlxdist/bin/python` exists on **every** machine. The path must match exactly.  
- **Permissions**: If you see “Unable to execute Python” errors, ensure it’s installed and executable (`chmod +x`).  
- **Memory**: The `set_mem_limit.sh` script only applies to your current shell session, so you need to re-run it after a reboot or if you open a new shell.

---

**Enjoy using MLX!** For more detailed MPI or MLX usage, consult the official documentation.