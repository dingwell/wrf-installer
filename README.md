# WRF-installer (beta)

This tool will help you install WRF and WPS on a selection of systems
available to researchers at Uppsala University.

## Usage
* Downloand archive (tar or zip) and unpack
* From a clean directory (e.g. ~/WRF), link the installation script and
  settings:
  ```bash
  mkdir ~/WRF
  cd ~/WRF
  ln -s /path/to/wrf-installer/*sh .
  cp /path/to/wrf-installer/YOUR_SYSTEM/*.bash
  ```
* Edit your copies of *user_settings_common.bash* and *user_settings_wps.bash*
  to match your environment
* If you want to install WRF-Chem,
  open *user_common_settings.bash*
  and set **WRF_CHEM=1**, otherwise set **WRF_CHEM=0**
* run the installer: *./wrf_installer.sh*
* You will need to select compiler options as usual
  when the configuration scripts are running (once for WRF and once for WPS).

## Notes
* The installer will download all the necessary tar-balls automatically; but if
you prefer, you can download them yourself and place them in the working
directory. If you download them yourself, ensure that the version string in
*user_settings_common.bash* matches that of your downloaded files.
* This installer assumes that all dependencies are already installed on
  your system (I might add installation instructions for these as well, but
  that's a bit more work...)
