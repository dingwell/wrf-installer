#!/bin/bash

set -e  # Exit after failed command

# This script will attempt to download and install WRF and WRF-Chem
#
# Configuration of this script is made by editing these to files:
#   + user_settings_common 
#   + user_settings_wps
#
# The rest of the configuration/compilation should be handled by this script
# please let me know if you have any issues.
#
# Adam Dingwell
# publicadam2011@gmail.com


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
  echo -e "${W}-Verifying that '$FILE' should work with WRF-Chem -$D"
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

check_wrf_compile_log () {
  # Check for some common errors
  LOGFILE=$1
  echo -e "${W}-Scanning '$LOGFILE' for errors-$D"

  if egrep "you have not loaded a compiler module yet!" $LOGFILE; then
    echo -e "${R}ERROR: It seems there is no compiler module loaded$D"
    echo -e "${W}Adjust your build environment and re-run wrf-installer.sh$D"
    exit 1
  fi
}

check_wrf_compile_log_for_chem () {
  # If compiling WRF for use with WRF-Chem run this to check for 
  # some common errors:
  LOGFILE=$1
  echo -e "${W}-Verifying that build should work with WRF-Chem -$D"
  if egrep "WARNING:.*no.*array named emis_ant" $LOGFILE; then
    echo -e "${R}ERROR: Emission arrays missing from some modules$D"
    echo -e "${W}Try re-compiling with a clean build directory (./clean -a)$D"
    exit 1
  elif egrep "libnetcdf\.a.*nc_del_att" $LOGFILE; then
    echo -e "${R}ERROR: NetCDF error detected, verify environment and try again"
    exit 1
  elif egrep "dec_jpeg2000.*catastrophic error" $LOGFILE;then
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
  ./compile -j $NJOBS $TESTCASE 2>&1 |tee $WRF_LOG |egrep --color -C 1 -i "error.[^o]"
  echo -e "${G}WRF compilation complete$D"

  check_wrf_compile_log $WRF_LOG
  if [[ $WRF_CHEM == 1 ]]; then
    check_wrf_compile_log_for_chem $WRF_LOG
    echo -e "$W-Compiling external emissions conversion code-$D"
    EMI_LOG=compile_emi-conv.log
    ./compile -j $NJOBS emi_conv 2>&1 |tee $EMI_LOG |grep --color -C 1 -i error
  fi
  echo -e "${G}WRF-CHEM compilation complete$D"
  cd ..
}

check_wps_configuration_for_chem () {
  # Scan configure.wps for obvious errors
  echo -e "${W}-Scanning configure.wps for obvious errors-$D"
  #TODO
  return 0
}

# Build WPS:
build_wps () {
  echo -e "$W=Installing WPS=$D"
  cd $WRF_DIR
  echo -e "$W-Unpacking WPS-$D"
  tar -xf "../$WPS_TAR"
  cd WPS
  echo -e "$W-Making sure directory is clean-$D"
  ./clean -a
  echo -e "$W-Configuring WPS-$D"
  ./configure
  # Replace the default WRF path:
  sed -i.bak -r 's/(WRF_DIR\s*=).*/\1 ../' configure.wps
  WPS_LOG=compile_wps.log
  # If MPI_ROOT is missing, try with I_MPI_ROOT:
  if [[ -z $MPI_ROOT ]]; then
    export MPI_ROOT=$I_MPI_ROOT
  fi
  echo -e "$W-Compiling WPS-$D"
  ./compile 2>&1 |tee $WPS_LOG |grep --color -C 1 -i error
}

# MAIN #
source user_settings_common.bash # User defined variables
source internal_settings.bash    # Relies on some variables from set_user()
echo "WRF will be installed under $(pwd)/$WRF_DIR"
init_tests
download_packages
build_wrf
source user_settings_wps.bash
build_wps
