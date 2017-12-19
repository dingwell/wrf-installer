# This file will be source by wrf_installer.sh 
# The file should use a format compatible with Bash

module load intel/17.2 intelmpi/17.2 # Load modules (if needed)

# Notes:
# Rackham should have the netcdf libraries installed under:
#  /usr/lib64
# However, these libraries lack the fortran and c++ support and they
# are compiled using GCC (not Intel). You will be better of compiling 
# your own libraries.
#
# You should be able to compile WRF with the options labelled:
#     "INTEL (ifort/icc): Xeon (SNB with AVX mods)"
#   or
#     "INTEL (ifort/icc)"
#
# The following will probably NOT work:
#     "INTEL (ifort/icc): Xeon Phi (MIC architecture)"
#
# Tne above suggestions are for WRF 3.9 and might be named a bit differently
# in older/newer releases.
#
# These are the libraries you need to install (in order):
# * libjasper (recommended version: <=1.900.x, the newer versions are more difficult)
# * zlib      (I used 1.2.11)
# * HDF5      (I used 1.8.18)
# * netCDF-C Libraries (recommended version: 4.4.1.1)
# * netCDF-Fortran Libraries (recommended version: 4.4.4)
#
# There are also several optional dependencies which we can do without.

# Path to user installed files (usually "~/local")
LOCAL_DIR=$HOME/local.rackham.intel

# Path variables:
export NETCDF="$LOCAL_DIR"
export PATH="$HOME/bin:$LOCAL_DIR/bin:$PATH"
export LD_LIBRARY_PATH="$LOCAL_DIR/lib:$LD_LIBRARY_PATH"

# Compilation variables:
export JASPERINC=$LOCAL_DIR/include  # Path to libjasper headers
export JASPERLIB=$LOCAL_DIR/lib      # Path to libjasper libraries
export NETCDF=$LOCAL_DIR             # Path to root of netcdf installation
export HDF5=$LOCAL_DIR               # Path to root of HDF5 installation
export NCARG_ROOT=$LOCAL_DIR         # Path to root of NCL installation (optional)

# Installer options:
export WRF_CHEM=1         # 1 = WRF-Chem, 0 = only WRF
export NJOBS=2            # Number of processes to launch when compiling (1-20)
export TESTCASE=em_real   # Compile option (test case) for WRF

# WRF download URLs (It's probably enough to set the version)
export VERSION="3.8.1"
export WRF_URL=http://www2.mmm.ucar.edu/wrf/src/WRFV${VERSION}.TAR.gz
export WPS_URL=http://www2.mmm.ucar.edu/wrf/src/WPSV${VERSION}.TAR.gz
export CHEM_URL=http://www2.mmm.ucar.edu/wrf/src/WRFV3-Chem-${VERSION}.TAR.gz
