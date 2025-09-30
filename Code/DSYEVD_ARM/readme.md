# AWS Graviton3 SVE Performance Environment

## Environment

- **Instance**: AWS EC2 `c7g.large` (2 vCPU / 4 GiB, Arm Neoverse V1 with **SVE**)
- **OS**: Amazon Linux 2023 (ARM64, Kernel 6.1)

## Goal

Evaluate LAPACK routines (e.g. `dsyevd`) on Arm-based CPUs with SVE support.

## Toolchain Setup (Minimal Build Environment)

```bash
# System update & basic compiler toolchain
sudo dnf update -y
sudo dnf groupinstall -y "Development Tools"
sudo dnf install -y gcc gcc-gfortran cmake git make wget tar
