#!/bin/bash
# -----------------------------------------------------------------------------
# install_grads.sh
# 
# Explicit configuration script for GrADS using the provided Spack environment paths
# -----------------------------------------------------------------------------

set -e

echo "================================================================="
echo "   Configuring GrADS with Spack Environment Paths                "
echo "================================================================="

# Extract exact root paths from the provided cluster environment string
NETCDF_ROOT="/opt/sw/spack/apps-2024/linux-rhel8-x86_64_v3/gcc-12.3.0-openmpi-4.1.6/netcdf-c-4.9.2-x7"
HDF5_ROOT="/opt/sw/spack/apps-2024/linux-rhel8-x86_64_v3/gcc-12.3.0-openmpi-4.1.6/hdf5-1.14.3-46"
LIBTIFF_ROOT="/opt/sw/spack/apps-2024/linux-rhel8-x86_64_v3/gcc-12.3.0/libtiff-4.5.1-ua"
WGRIB2_ROOT="/opt/sw/spack/apps-2024/linux-rhel8-x86_64_v3/gcc-12.3.0/wgrib2-3.1.1-lt"
CURL_ROOT="/opt/sw/spack/apps-2024/linux-rhel8-x86_64_v3/gcc-12.3.0/curl-8.7.1-k4"
LIBPNG_ROOT="/opt/sw/spack/apps-2024/linux-rhel8-x86_64_v3/gcc-12.3.0/libpng-1.6.39-bp"

# Append all critical Spack paths to CPPFLAGS (for Headers) and LDFLAGS (for Linking)
export CPPFLAGS="-I$NETCDF_ROOT/include -I$HDF5_ROOT/include -I$LIBTIFF_ROOT/include -I$LIBPNG_ROOT/include -I$CURL_ROOT/include -I$WGRIB2_ROOT/include $CPPFLAGS"
export LDFLAGS="-L$NETCDF_ROOT/lib -L$HDF5_ROOT/lib -L$LIBTIFF_ROOT/lib -L$LIBPNG_ROOT/lib -L$CURL_ROOT/lib -L$WGRIB2_ROOT/lib $LDFLAGS"

# Append Pkg-Config to detect any remaining dynamically loadable `.pc` configurations
export PKG_CONFIG_PATH="$NETCDF_ROOT/lib/pkgconfig:$HDF5_ROOT/lib/pkgconfig:$LIBTIFF_ROOT/lib/pkgconfig:$LIBPNG_ROOT/lib/pkgconfig:$CURL_ROOT/lib/pkgconfig:$PKG_CONFIG_PATH"

echo "Using CPPFLAGS: $CPPFLAGS"
echo "Using LDFLAGS: $LDFLAGS"
echo "================================================================="

# Create dummy directories to prevent libtool bug `-L..//lib` on empty supplibs
mkdir -p lib include

chmod +x configure

# Run configure with explicit overrides mapped to your NetCDF and HDF5 spack deployments
./configure \
    --prefix=$(pwd)/run_install \
    --with-netcdf="$NETCDF_ROOT" \
    --with-hdf5="$HDF5_ROOT" \
    --enable-dyn-supplibs \
    --with-gadap

echo ""
echo "Configuration complete. Proceeding to build..."
make -j $(nproc 2>/dev/null || echo 4)
echo ""
echo "Build complete! You can run 'make install' to finalize."
