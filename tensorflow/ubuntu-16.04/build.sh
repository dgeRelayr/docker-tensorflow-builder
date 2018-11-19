#!/usr/bin/env bash
set -e

export PATH="/conda/bin:/usr/bin:$PATH"


gcc --version

# Install an appropriate Python environment
conda create --yes -n tensorflow python==3.6
source activate tensorflow
conda install --yes numpy wheel bazel
conda install -c conda-forge keras-applications

# Checkout tensorflow
cd /
rm -fr tensorflow/
git clone --branch r1.10 "https://github.com/tensorflow/tensorflow.git"
TF_ROOT=/tensorflow
cd $TF_ROOT

# Python path options
export PYTHON_BIN_PATH=$(which python)
export PYTHON_LIB_PATH="$($PYTHON_BIN_PATH -c 'import site; print(site.getsitepackages()[0])')"
export PYTHONPATH=${TF_ROOT}/lib
export PYTHON_ARG=${TF_ROOT}/lib

# Compilation parameters, used in configure
export TF_NEED_CUDA=0
export TF_NEED_GCP=0
export TF_CUDA_COMPUTE_CAPABILITIES=5.2,3.5
export TF_NEED_HDFS=0
export TF_NEED_OPENCL=0
export TF_NEED_JEMALLOC=0  # Need to be disabled on CentOS 6.6
export TF_ENABLE_XLA=0
export TF_NEED_VERBS=0
export TF_CUDA_CLANG=0
export TF_DOWNLOAD_CLANG=0
export TF_NEED_MKL=0
export TF_DOWNLOAD_MKL=0
export TF_NEED_MPI=0
export TF_NEED_S3=0
export TF_NEED_KAFKA=0
export TF_NEED_GDR=0
export TF_NEED_OPENCL_SYCL=0
export TF_SET_ANDROID_WORKSPACE=0
export TF_NEED_AWS=0

# Compiler options
export GCC_HOST_COMPILER_PATH=$(which gcc)
export CC_OPT_FLAGS="-march=native"

# Compilation
./configure

bazel build --config=opt \
		    --action_env="LD_LIBRARY_PATH=${LD_LIBRARY_PATH}" \
		    //tensorflow/tools/pip_package:build_pip_package

bazel build --config=opt //tensorflow:libtensorflow_cc.so
bazel build --config=opt //tensorflow:libtensorflow.so
bazel build --config=opt //tensorflow:libtensorflow_framework.so
bazel-bin/tensorflow/tools/pip_package/build_pip_package /wheels

# Fix wheel folder permissions
chmod -R 777 /wheels/

# export artifacts
mkdir artifacts
cp -r /tensorflow /artifacts/tensorflow
cp -r /wheels /artifacts/wheels
