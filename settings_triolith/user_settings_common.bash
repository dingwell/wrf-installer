# This file will be source by wrf_installer.sh 
# The file should use a format compatible with Bash

module load intel/12.1.4 impi/4.0.3.008 netcdf/4.2-i1214-hdf5-1.8.11-parallel # Load modules (if needed)

# Compiler variables
export CC=icc
export FC=ifort

# Path variables:
export NETCDF="$HOME/local"
PERSONAL_PATH="$HOME/bin:$HOME/local/bin"
export PATH="$PERSONAL_PATH:$PATH"
export NETCDF=$NETCDF_DIR
export NETCDF4=1

export LD_LIBRARY_PATH="$HOME/local/lib:$NETCDF/lib:$LD_LIBRARY_PATH"

# Installer options:
export WRF_CHEM=1         # 1 = WRF-Chem, 0 = only WRF
export NJOBS=8            # Number of processes to launch when compiling (1-20)
export TESTCASE=em_real   # Compile option (test case) for WRF

# WRF download URLs (It's probably enough to set the version)
export VERSION="3.8"
export WRF_URL=http://www2.mmm.ucar.edu/wrf/src/WRFV${VERSION}.TAR.gz
export WPS_URL=http://www2.mmm.ucar.edu/wrf/src/WPSV${VERSION}.TAR.gz
export CHEM_URL=http://www2.mmm.ucar.edu/wrf/src/WRFV3-Chem-${VERSION}.TAR.gz
