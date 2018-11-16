#!/usr/bin/env bash
set -e

export PATH="/conda/bin:/usr/bin:$PATH"


gcc --version

# Install an appropriate Python environment
conda create --yes -n tensorflow python==$PYTHON_VERSION
source activate tensorflow
conda install --yes numpy wheel bazel
conda install -c conda-forge keras-applications

# Compile TensorFlow

# Here you can change the TensorFlow version you want to build.
# You can also tweak the optimizations and various parameters for the build compilation.
# See https://www.tensorflow.org/install/install_sources for more details.

cd /
rm -fr tensorflow/
git clone --depth 1 --branch $TF_VERSION_GIT_TAG "https://github.com/tensorflow/tensorflow.git"

TF_ROOT=/tensorflow
cd $TF_ROOT

# Python path options
export PYTHON_BIN_PATH=$(which python)
export PYTHON_LIB_PATH="$($PYTHON_BIN_PATH -c 'import site; print(site.getsitepackages()[0])')"
export PYTHONPATH=${TF_ROOT}/lib
export PYTHON_ARG=${TF_ROOT}/lib

# Compilation parameters
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


# Project name can only be set for TF > 1.8
#PROJECT_NAME="tensorflow_gpu_cuda_${TF_CUDA_VERSION}_cudnn_${TF_CUDNN_VERSION}"
#bazel-bin/tensorflow/tools/pip_package/build_pip_package /wheels --project_name $PROJECT_NAME

bazel-bin/tensorflow/tools/pip_package/build_pip_package /wheels

# Fix wheel folder permissions
chmod -R 777 /wheels/
