#!/bin/sh

echo "This is src dir SRC_DIR"
echo "This is CXXFLAGS: $CXXFLAGS"

mkdir build && cd build

# Enable SDL
sed 's/\/\/#define _IRR_COMPILE_WITH_SDL_DEVICE_/#define _IRR_COMPILE_WITH_SDL_DEVICE_/g' $SRC_DIR/include/IrrCompileConfig.h > ./PatchedIrrCompileConfig.h
cp ./PatchedIrrCompileConfig.h $SRC_DIR/include/IrrCompileConfig.h

# Avoid macOS arm64 compilation failures
# See https://github.com/conda-forge/irrlicht-feedstock/pull/9#issuecomment-1049181315
sed 's/(NSOpenGLPixelFormatAttribute)nil/0/g' $SRC_DIR/source/Irrlicht/MacOSX/CIrrDeviceMacOSX.mm > ./PatchedCIrrDeviceMacOSX.mm
cp ./PatchedCIrrDeviceMacOSX.mm $SRC_DIR/source/Irrlicht/MacOSX/CIrrDeviceMacOSX.mm

# GNU extensions are required by Irrlicht
CXXFLAGS=$(echo "${CXXFLAGS}" | sed "s/-std=c++/-std=gnu++/g")

# -fpermessive is necessary to compile irrlicht with jpeg v9
CXXFLAGS="${CXXFLAGS} -fpermissive"



cmake ${CMAKE_ARGS} -DCMAKE_INSTALL_PREFIX=$PREFIX \
      -DCMAKE_PREFIX_PATH=$PREFIX \
      -DCMAKE_BUILD_TYPE=Release \
      -DCMAKE_INSTALL_LIBDIR=lib \
      -DBUILD_SHARED_LIBS=ON \
      $SRC_DIR

VERBOSE=1 make -j${CPU_COUNT}
make install
