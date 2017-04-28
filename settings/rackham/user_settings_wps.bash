# This file will be source by wrf_installer.sh 
# The file should use a format compatible with Bash

# Path variables (will also use common settings)
export JASPERLIB=$HOME/local/lib
export JASPERINC=$HOME/local/include

# Installer options:
export WRF_CHEM=1         # 1 = WRF-Chem, 0 = only WRF
export NJOBS=4            # Number of processes to launch when compiling (1-20)
export TESTCASE=em_real   # Compile option (test case) for WRF

