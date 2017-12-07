# Set the kernel version string, feel free to change this or not.
export LOCALVERSION="-vs995.10b.reStock-1.2"

# Set the kernel architecture, do not change this.
export ARCH=arm64

# Toolchain (required) - add the path and prefix to your GCC compiler.
export CROSS_COMPILE=$HOME/aarch64-linux-android-4.9/bin/aarch64-linux-android-

# Lazy Kernel Flasher (optional) - set the path to the LKF directory to automate
# generating a flashbale zip file. Comment out or set output directory to disable.
#https://forum.xda-developers.com/android/software-hacking/zip-lazyflasher-tool-flashing-custom-t3549210
LKF="$HOME/lazyflasher/"

# Remove Root Check (optional) - Remove RCTD and CCMD from the existing kernel boot image via
# Lazy Kernel Flasher. Also removes Triton, a poor powersaving option that apparently doesn't
# work well. Comment out to disable.
RRC=true

# Output directory (optional) - override the directory the kernel Image.lz4-dtb and modules
# are copied to. This will override Lazy Kernel Flasher. Comment out to disable.
#OUT=

# Set the base directory. 
DIR=$(pwd)

# Set the build directory.
BUILD="$DIR/build"

# Set the output directory.
if [ ! -z "$OUT" ]; then
   echo "Output directory is declared and will be used. $OUT"
elif [ ! -z "$LKF" ] && [ -d "$LKF" ]; then
   echo "Lazy Kernel Flasher is set and present. Flashable zip file will be created in $LKF"
   OUT="$LKF"
else 
   echo "Lazy Kernel Flasher is not set/present and output directory is not declared. Using $DIR/OUT"
   OUT="$DIR/out"
fi

# Set the numper of CPUs (+1). 
NPR=`expr $(nproc) + 1`

# Clean old builds before starting a new one.
echo "cleaning build..."
if [ -d "$BUILD" ]; then
   rm -rf "$BUILD"
fi
if [ "$LKF" == "$OUT" ]; then
   if [ -e "$OUT/Image.lz4-dtb" ]; then 
      rm -f "$OUT/Image.lz4-dtb"
   fi
   if [ -e "$OUT/modules" ]; then
      rm -rf "$OUT/modules/"*.*
   fi
   if [ -e "$OUT/patch.d/025-rctd" ]; then
      rm -f "$OUT/patch.d/025-rctd"
   fi
elif [ -d "$OUT" ]; then
   rm -rf "$OUT"
fi


# Make the defconfig.
echo "setting up build..."
mkdir "$BUILD"
make O="$BUILD" VS995_reStock_defconfig

# Make the kernel dtb.
echo "building kernel..."
make O="$BUILD" -j$NPR

# Make the external modules.
echo "building moduels"
make O="$BUILD" INSTALL_MOD_PATH="." INSTALL_MOD_STRIP=1 modules_install
rm $BUILD/lib/modules/*/build
rm $BUILD/lib/modules/*/source

# Move the kernel and modules to the proper location.
if [ ! -d "$OUT/modules" ]; then
   mkdir -p "$OUT/modules"
fi
mv "$BUILD/arch/arm64/boot/Image.lz4-dtb" "$OUT/Image.lz4-dtb"
find "$BUILD/lib/modules/" -name *.ko | xargs -n 1 -I '{}' mv {} "$OUT/modules"
echo "Image.lz4-dtb and modules can be found in $OUT"

# Make a flashable zip if Lazy Kernel Flasher is set and present.
if [ "$LKF" == "$OUT" ]; then
   echo "Building flashable zip in $OUT"
   if "$RRC"; then
      cp "$DIR/025-rctd" "$LKF/patch.d"
   fi
   cd "$LKF" && make
fi

# Done.
echo "Done."

