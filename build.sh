
#!/bin/bash

#
# AOSiP Build script by teh kooba
#
# change the cd directory to your rom dir
#
# Usage: ./build.sh <DEVICE> <BUILDTYPE> <REPOSYNC> <CHERRYPICK> <CLEANORDIRTY> <UPLOAD>
#

DEVICE="$1"
BUILDTYPE="$2"
REPOSYNC="$3"
CHERRYPICK="$4"
CLEANORDIRTY="$5"

alias reposyncf="repo sync -c -f -j64 --no-clone-bundle --no-tags --force-sync"
alias reposync="repo sync -c -f -j64 --no-clone-bundle --no-tags"

  if [ $# -lt 5 ];
  then
  echo "You forgot some variable(s), please specify all of them in this order
        (there is always and example in brackets)
        <DEVICE(bullhead)>
        <BUILDTYPE(your custom build type, should be one word for example akhilsucks)>
        <REPOSYNC(reposync, write no for no sync)>
        <CHERRYPICK(this executes custom cherrypick from a .sh file(read this script for more info))>
        <CLEANORDIRTY(you either write clean or dirty of clean or dirty build! yay!)>
        source build.sh bullhead OMS yes no clean"
  return
  fi

# CD To AOSiP

   if [ $PWD != "~/AOSiP/" ] # Put your source dir here
   then
   cd ~/AOSiP/
   fi

# Source envsetup.sh

   source build/envsetup.sh

# Rekt jack

   rm -rf ~/.jack*
   ./prebuilts/sdk/tools/jack-admin install-server prebuilts/sdk/tools/jack-launcher.jar prebuilts/sdk/tools/jack-server-4.8.ALPHA.jar
   export JACK_SERVER_VM_ARGUMENTS="-Dfile.encoding=UTF-8 -XX:+TieredCompilation -Xmx4096M"
   export SERVER_NB_COMPILE=2
   export ANDROID_JACK_VM_ARGS=$JACK_SERVER_VM_ARGUMENT
   ./prebuilts/sdk/tools/jack-admin start-server

# Sync the repositores

   if [ $REPOSYNC == "yes" ];
   then
   reposync
   fi

   if [ $REPOSYNC == "force" ];
   then
   reposyncf
   fi

# Choose your cherrypick.sh script

   if [ $CHERRYPICK == "yes" ];
   then
   source cherrypick.sh
   fi

# Use ccache

   export USE_CCACHE=true
   export CCACHE_DIR=~/.ccache/$DEVICE/
   ./prebuilts/misc/linux-x86/ccache/ccache -M 20G
   ccache -M 20G

# Choose clean or dirty build

   if [ "$CLEANORDIRTY" == "clean" ];
   then
   make clean
   fi

   if [ "$CLEANORDIRTY" == "dirty" ];
   then
   make installclean
   make dirty
   OUTDIR="./out/target/product/$DEVICE";
      rm -rfv "$OUTDIR/combinedroot";
      rm -rfv "$OUTDIR/data";
      rm -rfv "$OUTDIR/recovery";
      rm -rfv "$OUTDIR/root";
      rm -rfv "$OUTDIR/system";
      rm -rfv "$OUTDIR/utilities";
      rm -rfv "$OUTDIR/boot"*;
      rm -rfv "$OUTDIR/combined"*;
      rm -rfv "$OUTDIR/kernel";
      rm -rfv "$OUTDIR/ramdisk"*;
      rm -rfv "$OUTDIR/recovery"*;
      rm -rfv "$OUTDIR/system"*;
      rm -rfv "$OUTDIR/obj/ETC/system_build_prop_intermediates";
      rm -rfv "$OUTDIR/ota_temp/RECOVERY/RAMDISK";
   fi

# Logfile stuff

  [[ -d logs ]] || mkdir -v logs
  export LOGFILE="logs/${DEVICE}-$(date +%Y%m%d-%H%M).log"

# Compile the build

   export AOSIP_BUILDTYPE=$BUILDTYPE
   lunch aosip_$DEVICE-userdebug
   make kronic -j16 2>&1 | tee ${LOGFILE}

# Transfer to device if any connected or upload to afh
   if [ "$(ls ${OUT}/AOSiP*.zip 2> /dev/null | wc -l)" != "0" ];
   then
   echo "Build successful"
   source upload.sh afh
   else
   echo "Build failed"
   echo "Check for errors in ${LOGFILE}"
   fi

# Stop the jack server

   echo -e "Stopping jack server"
   ./prebuilts/sdk/tools/jack-admin kill-server
   pkill -9 java
