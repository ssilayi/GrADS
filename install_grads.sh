#!/bin/bash
# -----------------------------------------------------------------------------
# install_grads.sh
# 
# Installation wrapper for GrADS on cluster environments.
# This script automatically detects the paths for all GrADS dependencies 
# (NetCDF, HDF5, Cairo, GeoTIFF, GD, ShapeLib, Grib2, etc.) using `pkg-config`,
# `nc-config`, and cluster environment variables, enabling them for the build.
# -----------------------------------------------------------------------------

set -e

echo "================================================================="
echo "   Auto-Detecting Dependency Paths for GrADS Configuration       "
echo "================================================================="

EXTRA_INCLUDES=""
EXTRA_LIBS=""

# Helper function to extract paths from pkg-config
add_pkg_config_paths() {
    local pkg=$1
    if pkg-config --exists "$pkg" 2>/dev/null; then
        echo "Found $pkg via pkg-config"
        EXTRA_INCLUDES="$EXTRA_INCLUDES $(pkg-config --cflags-only-I "$pkg")"
        EXTRA_LIBS="$EXTRA_LIBS $(pkg-config --libs-only-L "$pkg")"
    fi
}

# Helper function to append cluster $DIR or $ROOT environment variables
add_env_path() {
    local path=$1
    if [ -n "$path" ] && [ -d "$path" ]; then
        echo "Found environment path: $path"
        if [ -d "${path}/include" ]; then
            EXTRA_INCLUDES="$EXTRA_INCLUDES -I${path}/include"
        fi
        if [ -d "${path}/lib" ]; then
            EXTRA_LIBS="$EXTRA_LIBS -L${path}/lib"
        elif [ -d "${path}/lib64" ]; then
            EXTRA_LIBS="$EXTRA_LIBS -L${path}/lib64"
        fi
    fi
}

# 1. Identify paths automatically using pkg-config
add_pkg_config_paths "cairo"
add_pkg_config_paths "libgeotiff"
add_pkg_config_paths "geotiff"
add_pkg_config_paths "gdlib"
add_pkg_config_paths "hdf5"
add_pkg_config_paths "netcdf"
add_pkg_config_paths "readline"

# 2. Identify paths automatically using nc-config (NetCDF fallback)
if command -v nc-config >/dev/null 2>&1; then
    echo "Found nc-config"
    EXTRA_INCLUDES="$EXTRA_INCLUDES -I$(nc-config --includedir)"
    EXTRA_LIBS="$EXTRA_LIBS -L$(nc-config --libdir)"
fi

# 3. Identify cluster-specific loaded variables (Lmod/Environment Modules style)
add_env_path "$CAIRO_DIR"
add_env_path "$GEOTIFF_DIR"
add_env_path "$SHP_DIR"
add_env_path "$SHAPELIB_DIR"
add_env_path "$GD_DIR"
add_env_path "$GDLIB_DIR"
add_env_path "$GRIB2_DIR"
add_env_path "$HDF4_DIR"
add_env_path "$HDF5_DIR"
add_env_path "$NETCDF_DIR"
add_env_path "$GADAP_DIR"

# Clean up whitespace and deduplicate
export CPPFLAGS="$CPPFLAGS $(echo $EXTRA_INCLUDES | tr ' ' '\n' | sort -u | tr '\n' ' ')"
export LDFLAGS="$LDFLAGS $(echo $EXTRA_LIBS | tr ' ' '\n' | sort -u | tr '\n' ' ')"

echo ""
echo "Exported CPPFLAGS: $CPPFLAGS"
echo "Exported LDFLAGS:  $LDFLAGS"
echo "================================================================="

# Generate configure if missing
if [ ! -f "configure" ]; then
    echo "configure script not found. Running autoreconf..."
    autoreconf -vfi
fi

# Make the configure script executable in case DOS format or permissions break
chmod +x configure

echo ""
echo "Running ./configure..."

# Run configure with standard optional dependency arguments explicitly provided if path variables exist.
# The `m4` fallback macros and environment LDFLAGS we set up will satisfy the rest dynamically!
./configure \
    ${NETCDF_DIR:+--with-netcdf="$NETCDF_DIR"} \
    ${HDF5_DIR:+--with-hdf5="$HDF5_DIR"} \
    ${HDF4_DIR:+--with-hdf4="$HDF4_DIR"} \
    ${GEOTIFF_DIR:+--with-geotiff="$GEOTIFF_DIR"} \
    ${SHP_DIR:+--with-shp="$SHP_DIR"} \
    --enable-dyn-supplibs \
    --with-gadap

echo ""
echo "Configuration complete. Proceeding to build..."
make -j $(nproc 2>/dev/null || echo 4)
echo ""
echo "Build complete! You can run 'make install' to finalize."
