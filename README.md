# WRF-installer

This tool will help you install WRF and WPS on your system.

## Usage
* Downloand the scripts to a clean working directory.
* Edit *user_settings_common.bash* and *user_settings_wps.bash* to match your environment
* For WRF-Chem: set **WRF_CHEM=1**; otherwise: set **WRF_CHEM=0**
* run the installer: *./wrf_installer.sh*
* You will need to select compiler options as usual when the configuration
  scripts are running (once for WRF and once for WPS).

## Notes
The installer will download all the necessary tar-balls automatically; but if
you prefer, you can download them yourself and place them in the working
directory. If you download them yourself, ensure that the version string in
*user_settings_common.bash* matches that of your files.
