#!/bin/bash

set -e  # Exit after failed command

# This script will attempt to download and install WRF and WRF-Chem

# Set up environment (you probably have to change this on each machine)
module load intel/13.1 intelmpi

# Path variables:
export NETCDF="$HOME/local"
export PATH="$HOME/bin:$HOME/bin/local/bin:$PATH:/usr/lib64/qt-3.3/bin:/usr/bin:/usr/local/bin:/bin:/usr/local/sbin:/usr/sbin:/sbin:/bubo/sw/uppmax/bin:/opt/thinlinc/bin"
#export HDF5_DISABLE_VERSION_CHECK=1
export LD_LIBRARY_PATH="$HOME/local/lib:$LD_LIBRARY_PATH"

# Options:
export WRF_CHEM=1 # Whether or not to install WRF-Chem
export NJOBS=4 # Number of processes to launch when compiling
export TESTCASE=em_real  # Compile option (test case) for WRF

export VERSION="3.8"
export WRF_URL=http://www2.mmm.ucar.edu/wrf/src/WRFV${VERSION}.TAR.gz
export WPS_URL=http://www2.mmm.ucar.edu/wrf/src/WPSV${VERSION}.TAR.gz
export CHEM_URL=http://www2.mmm.ucar.edu/wrf/src/WRFV3-Chem-${VERSION}.TAR.gz

export WRF_TAR=$(basename "$WRF_URL")
export WPS_TAR=$(basename "$WPS_URL")
export CHEM_TAR=$(basename "$CHEM_URL")

# Determine target directory name:
if [[ $WRF_CHEM == 1 ]]; then
  export WRF_DIR="WRF-Chem_$VERSION"
else
  export WRF_DIR="WRF_$VERSION"
fi

# Settings for coloured output:
B="\e[01;34m"   # Changes the color of following characters to blue
W="\e[037;01m"  # Changes the color of following charcters to white (default)
D="\e[033;00m"  # Changes the color of following charcters to light gray (default)
P="\e[01;35m"   # Changes the color of following charcters to purple
R="\e[031;01m"  # Red

SEP1="$B==================================================$W"
SEP2="$B--------------------------------------------------$W"

# Print some information before starting
echo "WRF will be installed under $(pwd)/$WRF_DIR"

init_tests () {
  if [[ -e WRFV3 ]]; then
    echo -e "${R}ERROR: Target directory 'WRFV3' already exists${D}"
    echo -e "${R}       Please rename or delete before running installer${D}"
    exit 1
  fi
  if [[ -e $WRF_DIR ]]; then
    echo -e "${R}ERROR: Target directory '$WRF_DIR' already exists${D}"
    echo -e "${R}       Please rename or delete before running installer${D}"
    exit 1
  fi
}

download_packages () {
  if [[ -f $WRF_TAR ]]; then
    echo -e "$W-Found local file '$WRF_TAR' will skip download-$D"
  else
    echo -e "$W-Downloading WRF-$D"
    wget "$WRF_URL"
  fi
  if [[ -f $WPS_TAR ]]; then
    echo -e "$W-Found local file '$WPS_TAR' will skip download-$D"
  else
    echo -e "$W-Downloading WPS-$D"
    wget "$WPS_URL"
  fi
  if [[ $WRF_CHEM == 1 ]]; then
    if [[ -f $CHEM_TAR ]]; then
      echo -e "$W-Found local file '$CHEM_TAR' will skip download-$D"
    else
      echo -e "$W-Downloading WRF-Chem module-$D"
      wget "$CHEM_URL"
    fi
  fi
}

check_wrf_configuration_for_chem () {
  # If you configured WRF for use with WRF-Chem, run this before compiling
  # to verify that you have no obvious errors in your configuration file
  FILE=configure.wrf
  echo -e "${W}-Verifying that '$FILE' should work with WRF-Chem$D-"
  if ! egrep "ENVCOMPDEFS\s*=\s*-DWRF_CHEM" "$FILE"; then
    echo -e "${R}ERROR: -DWRF_CHEM flag missing$D"
    exit 1
  elif ! egrep "WRF_CHEM\s*=\s*1" "$FILE"; then
    echo -e "${R}ERROR: WRF_CHEM flag missing$D"
    exit 1
  elif egrep "OMP\s*=\s*-" "$FILE"; then
    echo -e "${R}ERROR: WRF smpar will not work with CHEM!"
    exit 1
  fi
}

check_wrf_compile_log_for_chem () {
  # If compiling WRF for use with WRF-Chem run this to check for 
  # some common errors:
  LOGFILE=$1
  echo -e "${W}-Verifying that build should work with WRF-Chem$D"
  if egrep "WARNING:.*emis_ant"; then
    echo -e "${R}ERROR: Emission arrays missing from some modules$D"
    echo -e "${W}Try re-compiling with a clean build directory (./clean -a)$D"
    exit 1
  elif egrep "libnetcdf\.a.*nc_del_att"; then
    echo -e "${R}ERROR: NetCDF error detected, verify environment and try again"
    exit 1
  elif egrep "dec_jpeg2000.*catastrophic error";then
    echo -e "${R}ERROR: Please disable WPS environment variables, and try again"
    exit 1
  fi
}
  

build_wrf () {
  echo -e "$W=Installing WRF=$D"
  echo -e "$W-Unpacking WRF-$D"
  tar -xf "$WRF_TAR"
  echo -e "$W-Renaming & entering working directory-$D"
  mv -v $(tar -tf "$WRF_TAR"|head -n1) "$WRF_DIR"
  cd "$WRF_DIR"
  if [[ $WRF_CHEM == 1 ]]; then
    echo -e "$W-Unpacking WRF-Chem-$D"
    tar -xf "../$CHEM_TAR"
  fi
  echo -e "$W-Configuring WRF-$D"
  if [[ $WRF_CHEM == 1 ]]; then
    echo -e "${W}Please note that WRF-Chem only works with serial or dmpar options!$D"
  fi
  ./configure
  if [[ $WRF_CHEM == 1 ]]; then
    check_wrf_configuration_for_chem
  fi
  echo -e "$W-Compiling WRF-$D"
  WRF_LOG=compile_wrf.log
  echo -e "${W}Will output errors to screen, for full details see $WRF_LOG$D"
  # Note: compile does not take unix-style arguments; it's written to look like
  # it does, but it does not! E.g. '-j8' should be equivalent to '-j 8' but only
  # the latter will work as expected.
  ./compile -j $NJOBS $TESTCASE 2>&1 |tee $WRF_LOG |grep --color -C 1 -i error
  if [[ $WRF_CHEM == 1 ]]; then
    check_wrf_compile_log_for_chem $WRF_LOG
    echo -e "$W-Compiling external emissions conversion code-$D"
    EMI_LOG=compile_emi-conv.log
    ./compile -J$NJOBS emi_conv 2>&1 |tee $EMI_LOG |grep --color -C 1 -i error
  fi
  cd ..
}

# Build WRF:
build_wps () {
  echo -e "$W=Installing WPS=$D"
  echo -e "$W-Unpacking WPS-$D"
  tar -xf "$WPS_TAR"
  echo -e "$W-Renaming & entering working directory-$D"
  mv -v $(tar -tf "$WRF_TAR"|head -n1) "$WRF_DIR"
  cd "$WRF_DIR"
  echo -e "$W-Configuring WPS-$D"
  if [[ $WRF_CHEM == 1 ]]; then
    echo -e "${W}Please note that WRF-Chem only works with serial or dmpar options!$D"
  fi
  ./configure
  echo -e "$W-Compiling WRF-$D"
  WRF_LOG=compile_wrf.log
  echo "Will output errors to screen, for full details see $WRF_LOG"
  ./compile -j$NJOBS $TESTCASE 2>&1 |tee $WRF_LOG |grep --color -C 1 -i error
}

# MAIN #
init_tests
download_packages
build_wrf
#build_wps
#build_chem
