#  run as: /bin/su -c "/share/apps/install_nvhpc.sh" - modules
ml purge
mkdir -p /home/modules/software/nvhpc/20.7/
export NVHPC_SILENT=true
export NVHPC_INSTALL_DIR=/home/modules/software/nvhpc/20.7/
export NVHPC_INSTALL_TYPE=single
export NVHPC_DEFAULT_CUDA=11
/share/apps/nvhpc_2020_207_Linux_x86_64_cuda_11.0/install
cp -r /home/modules/software/nvhpc/20.7/modulefiles/* /home/modules/modules/all/
exit
