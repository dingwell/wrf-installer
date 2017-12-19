# This file will be source by wrf_installer.sh 
# The file should use a format compatible with Bash

module load intel/13.1 intelmpi # Load modules (if needed)

# Path variables:
export NETCDF="$HOME/local"
export PATH="$HOME/bin:$HOME/bin/local/bin:$PATH:/usr/lib64/qt-3.3/bin:/usr/bin:/usr/local/bin:/bin:/usr/local/sbin:/usr/sbin:/sbin:/bubo/sw/uppmax/bin:/opt/thinlinc/bin"
export LD_LIBRARY_PATH="$HOME/local/lib:$LD_LIBRARY_PATH"

# Installer options:
export WRF_CHEM=1         # 1 = WRF-Chem, 0 = only WRF
export NJOBS=2            # Number of processes to launch when compiling (1-20)
export TESTCASE=em_real   # Compile option (test case) for WRF

# WRF download URLs (It's probably enough to set the version)
export VERSION="3.9.1"
export WRF_URL=http://www2.mmm.ucar.edu/wrf/src/WRFV${VERSION}.TAR.gz
export WPS_URL=http://www2.mmm.ucar.edu/wrf/src/WPSV${VERSION}.TAR.gz
export CHEM_URL=http://www2.mmm.ucar.edu/wrf/src/WRFV3-Chem-${VERSION}.TAR.gz
