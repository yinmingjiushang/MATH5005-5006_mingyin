import numpy as np, scipy
import numpy.__config__ as c

print("NumPy version:", np.__version__)
print("SciPy version:", scipy.__version__)

# 显示 NumPy BLAS/LAPACK 配置
c.show()
