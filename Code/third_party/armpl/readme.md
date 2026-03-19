## Arm Performance Libraries (ArmPL) Dependency

This project relies on **Arm Performance Libraries (ArmPL)** for optimized BLAS/LAPACK routines on **AArch64 platforms**.

⚠️ **Note:** ArmPL is *not available via GitHub or public package managers (apt/dnf/pip)*.  
You must **manually download it from Arm’s official website**.

---

### 📥 How to Download ArmPL

1. Open the official ArmPL download page:

   👉 https://developer.arm.com/Tools%20and%20Software/Arm%20Performance%20Libraries#Downloads

   *(You can also search “**ArmPL download**” on Google or Bing.)*

2. Choose the correct package based on your **compiler and OS**:

   | Your Compiler | Recommended ArmPL Package |
   |---------------|--------------------------|
   | `gcc / gfortran` | `*_gcc.tar` or `*_rpm_gcc.tar` |
   | `nvhpc` | `*_nvhpc.tar` |
   | `flang / llvm` | `*_flang.tar` |
   | **Ubuntu / Debian** | `.deb_xxx.tar` |
   | **Amazon Linux / RHEL / Fedora** | `.rpm_xxx.tar` |

3. **Download and extract** the package into **this project directory** (or any preferred path).

---

### 📦 Example (Amazon Linux / GCC)

```bash
# Suppose you downloaded:
arm-performance-libraries_25.07_rpm_gcc.tar

# Extract it into the current directory
tar -xf arm-performance-libraries_25.07_rpm_gcc.tar

cd arm-performance-libraries_25.07_rpm

nohup bash arm-performance-libraries_25.07_rpm.sh --accept --install-to ./armpl_local > armpl_install.log 2>&1 &

