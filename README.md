# MATH5005-5006 Course Project

## 1. Project Introduction & Background
<!-- Briefly describe the purpose, problem statement, and research focus.
     Mention that this repository supports a coursework/thesis-level project at UNSW (MATH5005 & MATH5006). -->
- Objective: <one or two sentences about what this project studies/implements>
- Scope: <algorithms, datasets, platforms>
- Outcomes: <codes, benchmarks, reports, figures>

## 2. Subproject Overview
Summarize each component/module:

| Submodule / Folder | Language / Tools | Description | Status |
|--------------------|------------------|-------------|--------|
| `src/`             | C / Assembly     | Core implementations (e.g., symmetric eigenvalue solvers) | ✅ / 🚧 |
| `scripts/`         | Shell / Make     | Build, run, and benchmarking scripts | ✅ / 🚧 |
| `python/`          | Python           | Analysis and plotting utilities | ✅ / 🚧 |
| `resources/`       | —                | Sample inputs / matrices / configs | — |
| `output/`          | —                | Logs, CSVs, plots, result tables | — |
| `thesis/`          | LaTeX            | Report/thesis drafts and figures | — |

<!-- Add or remove rows to match your actual layout. -->

## 3. Project Structure
Provide a quick tree for orientation.

```text
.
├── src/            # <short description>
├── scripts/        # <short description>
├── python/         # <short description>
├── resources/      # <short description>
├── output/         # <short description>
├── thesis/         # <short description>
└── README.md
```

## 4. Environment & Dependencies
List OS, toolchains, compilers, libraries, and Python packages with versions (if possible).

- **OS**: Ubuntu 20.04 / macOS 12 / AWS EC2 (Graviton) / etc.
- **Compiler / Toolchain**: GCC/Clang, Make, (optional) GFortran
- **Math libs**: BLAS/LAPACK (e.g., OpenBLAS, ArmPL) — if applicable
- **Python**: 3.9
- **Python packages**: `numpy`, `scipy`, `pandas`, `matplotlib` (if used)

```bash
# Example: install Python dependencies
pip install -r requirements.txt
```

## 5. Build & Run Instructions

### 5.1 Compile
```bash
# Example (C/Make)
cd src
make
# or
gcc -O3 main.c -lm -o app
```

### 5.2 Execute
```bash
# Example (binary)
./app --input resources/sample.bin --mode fast

# Example (Python analysis)
python3 python/analysis.py --input output/results.csv --plot
```

<!-- Document CLI flags, env vars (e.g., OPENBLAS_NUM_THREADS), and expected inputs/outputs. -->

## 6. Results / Outputs / Screenshots

### 6.1 Sample Results
| Test Case | Input Size | Runtime (s) | Notes |
|-----------|------------|-------------|-------|
| Example 1 | 1000       | 0.12        | ...   |
| Example 2 | 5000       | 1.05        | ...   |

### 6.2 Figures
![Performance Plot](output/plots/performance.png)
<!-- Place figures under output/plots and update the path. -->

## 7. Acknowledgements / References
- Supervisor/Advisor: **Name**
- Libraries/Frameworks: LAPACK / BLAS / OpenBLAS / NumPy / SciPy
- Selected references:
  - Author, Title, Venue/Year. DOI/URL.
  - ...
