# This file is not intended for the average user
# Change these settings on your own risk!

# Get the filename of tar-files from URLs (set in user_settings_common)
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
export B="\e[01;34m"   # Changes the color of following characters to blue
export W="\e[037;01m"  # Changes the color of following charcters to white (default)
export D="\e[033;00m"  # Changes the color of following charcters to light gray (default)
export P="\e[01;35m"   # Changes the color of following charcters to purple
export R="\e[031;01m"  # Red

#SEP1="$W==================================================$W"
#SEP2="$W--------------------------------------------------$W"
