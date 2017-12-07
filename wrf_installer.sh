#!/bin/bash

#set -e  # Exit after failed command

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

check_for_dependencies () {
  # Check for dependencies and query the user to install missing libraries
  echo "$W-Checking dependencies-$D"
  echo "$W-TODO-$D"
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

check_wrf_configuration () {
  FILE=configure.wrf
  echo -e "${W}-Checking validity of '$FILE'-$D"
  # Check for some common errors in configure.wrf:

  # Check if pre-processor is set up properly for all files:
  if [[ $FC == "ifort" ]] || [[ $FC == "gfortran" ]]; then
    if egrep "FORMAT_FIXED\s*=\s*-FI\s*$" "$FILE"; then
      echo -e "${W}Adjusting FORMAT_FIXED from '-FI' to '-FI -cpp'$D"
      sed -i.bak -r 's/(FORMAT_FIXED\s*=\s*).*/\1-FI -cpp/' "$FILE"
    fi
    if egrep "FORMAT_FREE\s*=\s*-FR\s*$" "$FILE"; then
      echo -e "${W}Adjusting FORMAT_FREE from '-FR' to '-FR -cpp'$D"
      sed -i.bak -r 's/(FORMAT_FREE\s*=\s*).*/\1-FR -cpp/' "$FILE"
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

  if egrep "you have not loaded a compiler module yet!" "$LOGFILE"; then
    echo -e "${R}ERROR: It seems there is no compiler module loaded$D"
    echo -e "${W}Adjust your build environment and re-run wrf-installer.sh$D"
    exit 1
  elif egrep -i "real_em.f90(12): error #7002" "$LOGFILE"; then
    echo -e "${R}ERROR: The executable failed to build$D"
    echo -e "${W}This can happen if you are compiling with too many threads$D"
    echo -e "${W}Re-run with J=1 or J=2, or run ./compile manually$D"
    return 1
  elif egrep -i "compilation aborted for .*" "$LOGFILE"; then
    echo -e "${R}ERROR: Compiling WRF failed, see '$LOGFILE' for details$D"
    return 1
  fi
  return 0
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
 
run_wrf_compile(){
  # This function will run the ./compile command (in the WRF directory)
  # A full log will be written to $WRF_LOG (env. variable)
  # errors will also be forwarded to stdout
  echo -e "$W-Compiling WRF-$D"

  WRF_LOG=$1
  if [[ -z $WRF_LOG ]]; then
    WRF_LOG=compile_wrf.log
  fi
  echo -e "${W}Will output errors to screen, for full details see $WRF_LOG$D"
  # Note: compile does not take unix-style arguments; it's written to look like
  # it does, but it does not! E.g. '-j8' should be equivalent to '-j 8' but only
  # the latter will work as expected.
  ./compile -j $NJOBS $TESTCASE 2>&1 |tee "$WRF_LOG" |egrep --color -C 1 -i "error.[^a-z]"

  echo -e "${G}WRF compilation complete$D"
  return 0
}

unpack_wrf () {
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
}


build_wrf () {
  echo -e "$W=Installing WRF=$D"
  unpack_wrf
  cd "$WRF_DIR"
  ./configure
  check_wrf_configuration # Check for some common mistakes
  if [[ $WRF_CHEM == 1 ]]; then
    check_wrf_configuration_for_chem
  fi

  WRF_LOG="compile_wrf.log"
  run_wrf_compile "$WRF_LOG"

  # Check if there were any errors and suggest solutions:
  while ! check_wrf_compile_log $WRF_LOG; do
    echo "Compilation error detected!"
    echo "Some errors might be solved by running ./compile again,"
    echo "especially if you are trying to run with a high job count."
    echo -ne "$W"
    read -p "Should I try to continue by re-running ./compile? [y/N]" -n 1 -r
    echo -ne "$D"
    if [[ $REPLY =~ ^[Yy]$ ]]; then
      echo -e "${W}Trying to continue compilation$D"
      run_wrf_compile
    else
      echo -e "${W}Exited with errors$D"
      exit 1
    fi
  done

  if [[ $WRF_CHEM == 1 ]]; then
    check_wrf_compile_log_for_chem $WRF_LOG
    echo -e "$W-Compiling external emissions conversion code-$D"
    EMI_LOG=compile_emi-conv.log
    echo -e "${W}Will output errors to screen, for full details see $EMI_LOG$D"
    ./compile -j $NJOBS emi_conv 2>&1 |tee $EMI_LOG |egrep --color -C 1 -i "error.[^a-z]"
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
  ./clean -a &> clean.log
  echo -e "$W-Configuring WPS-$D"
  ./configure

  # Replace the default WRF path:
  sed -i.bak -r 's/(WRF_DIR\s*=).*/\1 ../' configure.wps
  WPS_LOG=compile_wps.log

  # If MPI_ROOT is missing, try with I_MPI_ROOT:
  if [[ -z $MPI_ROOT ]]; then
    export MPI_ROOT=$I_MPI_ROOT
  fi

  # If enc_jpeg2000.c contains a reference to the private variable "inmem",
  # comment it out since this has been removed from newer releases of libjasper:
  sed -i.bak -r 's;^(\s*image.inmem_.*);//\1 //Removed by wrf-installer;' \
    ./ungrib/src/ngl/g2/enc_jpeg2000.c

  echo -e "$W-Compiling WPS-$D"
  echo -e "${W}Will output errors to screen, for full details see $WPS_LOG$D"
  ./compile 2>&1 |tee $WPS_LOG |egrep --color -C 1 -i "error.[^a-z]"
}

# MAIN #
source user_settings_common.bash # User defined variables
echo "NETCDF: $NETCDF"
source internal_settings.bash    # Relies on some variables from set_user()
echo "WRF will be installed under $(pwd)/$WRF_DIR"
#init_tests
#download_packages
build_wrf
source user_settings_wps.bash
build_wps
