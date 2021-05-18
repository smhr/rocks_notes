My Rocks and slurm notes
========================

## User management


### Add New Users

```sh
su -
useradd username
passwd username
chfn -f "Name" username
rocks sync users
```

### Deleting Users

```sh
userdel username
delete user home directory manually
```
### Some useful commands

`getent group developers # List All Members of a Group`

`groups username         # List all groups a user is a member of (also: id -nG)`

`id username             # Prints information about the specified user and its groups`

### Missing /etc/411-security/shared.key issue

When a node reinstalls, it is supposed to ask the frontend to sync the sharedkey. It usually works,
but apparently not always (e.g. a rocks bug). Without the shared key, the nodes can't decode the 411 files (by design). the 411 files do contain crypted passwords.

to fix it, use

`rocks sync host sharedkey compute`

### Comments on "/etc/default/useradd"

The default home directory for "useradd" command is set to be "/export/home". The "rock sync users" command only recognizes this directory and automatically change "/export/home/username" in /etc/passwd to "/home/username". In addition, it updates auto.home and passwd file to compute nodes, but only if we use the default home directory "/export/home".

## Change timezone on Rocks Cluster

On Rocks Cluster when install new compute node, timezone will same as frontend. If we want to change existing rocks, we use command “timedatectl” to change.

But when new compute installing, it still set default time zone, we must change attribute Kickstart_Timezone in frontend.

Example : change time zone to America/Newyork to Asia/Tehran

### change timezone for frontend and compute

`timedatectl set-timezone Asia/Tehran`

`tentakel timedatectl set-timezone Asia/Tehran`

### change attribute Kickstart_Timezone for new compute installed

`rocks set attr Kickstart_Timezone Asia/Tehran`

### Reinstall a nodes

`rocks set host boot action=install compute-0-0`

`ssh compute-0-0 'shutdown -r now'` or

`rocks run host compute-0-0 'shutdown -r now'`

## SLURM notes

### Add a slurm partition

Edit `/etc/slurm/parts ` for example:

```sh
PartitionName=WHEEL RootOnly=yes Priority=1000 Nodes=ALL
PartitionName=SHORT MaxTime=1-0:0 DefaultTime=00:30:00 DefMemPerCPU=512 TRESBillingWeights="CPU=1.0,Mem=0.25G,GRES/gpu=2.0" MaxNodes=1
PartitionName=LONG MaxTime=7-0:0 DefaultTime=00:30:00 DefMemPerCPU=512 TRESBillingWeights="CPU=1.0,Mem=0.25G,GRES/gpu=2.0" MaxNodes=1
```

Then assign a node to the created partition

```sh
rocks add host attr compute-0-1 slurm_partitions value='|CLUSTER|WHEEL|SHORT|'
```

If the attribute already exists, do

```sh
rocks set host attr compute-0-0 slurm_partitions value='|CLUSTER|WHEEL|SHORT|'
```

And finally don't forget to do
`rocks sync slurm`

### Add GPU

Edit `/etc/slurm/gres.conf.1` as

`Name=gpu Type=nvidia File=/dev/nvidia0`

Then edit /var/411/Files.mk to include your template:

`FILES += /etc/slurm/gres.conf.1`

Then

```sh
cd /var/411
make clean
make
```
You must set two new attributes for the node that has GPU

```sh
rocks set host attr compute-0-0 slurm_gres_template value="gres.conf.1"
rocks set host attr compute-0-0 slurm_gres value="gpu"
```

Then

```sh
rocks sync slurm
scontrol show node compute-0-
```

### QOS

Limit users in **normal** qos to can use just two nodes

```sh
sacctmgr update qos where name=normal set maxnodesperuser=2
```

and see the changes

```sh
sacctmgr show qos format=Name,MaxCpusPerUser,MaxNodesPerUser,MaxJobsPerUser,Flags
```

### Change priorities

Open `/etc/slurm/slurm.conf` and change it as

```sh
PriorityWeightAge=1000
PriorityMaxAge=14-0
```
see [multifactor priority plugin](https://slurm.schedmd.com/priority_multifactor.html) for more details.

## Anaconda installation and configuration

### Anaconda system wide installation

groupadd anaconda_users -g 10000
usermod -a -G anaconda_users username
rocks sync users

logout from username and then login

chgrp -R anaconda_users /share/apps/anaconda3
chmod 770 -R /share/apps/anaconda3

If choose to not have conda modify your shell scripts at all. To activate conda's base environment in your current shell session:

`eval "$(/share/apps/anaconda3/bin/conda shell.bash hook)"`

To install conda's shell functions for easier access, first activate, then:

`conda init`

If you'd prefer to conda's base environment not be activated on startup, set the auto_activate_base parameter to false:

`conda config --set auto_activate_base false`

### Configure conda for all users

To properly configure conda for using `conda activate` for all users, please run:

```sh
ln -s /share/apps/anaconda3/etc/profile.d/conda.sh /etc/profile.d/conda.sh
```

The options above will permanently enable the 'conda' command, but they do NOT put conda's base (root) environment on PATH. To do so, run

`conda activate base`

in your terminal, or to put the base environment on PATH permanently, run

`echo "conda activate" >> ~/.bashrc`

### Install packages using pip:

Install [fyrd](https://fyrd.science/releases/) as an example:

`pip install fyrd`


### An example batch script for running jupyter in the "LONG" partition on a node

```sh
#!/bin/bash
#SBATCH -J jupyter
#SBATCH --partition LONG
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --nodelist=compute-0-1
#SBATCH --output="stdout_jup.txt"
#SBATCH --error="stderr_jup.txt"
#SBATCH --mail-user=your_email@um.ac.ir
#SBATCH --mail-type=BEGIN,END
#SBATCH --mem-per-cpu=1000
#SBATCH --time=7-0:0:0
ulimit -s unlimited
cd $SLURM_SUBMIT_DIR
source /share/apps/anaconda3/etc/profile.d/conda.sh
conda activate base
jupyter notebook --no-browser >& out.txt
```

### Using a remote jupyter kernel in your local computer

At the first you should forward ssh from the computing node (e.g. compute-0-0) to the cluster front-end. So, in the cluster front-end do:

`ssh -NL 8888:localhost:8888 compute-0-0`

If 8888 port is already in used in front-end, test other ports e.g. 8800:

`ssh -NL 8800:localhost:8888 compute-0-0`

Then, in your local computer do (according to whatever you entered as the front-end port above, e.g. 8800):

`ssh -NL 8888:localhost:8800 your_username@scihpc.local`

Then open your browser and got the address:

`http://localhost:8800`

If it asks for a token, copy and paste the token in `out.txt` which has been stored in the directory in which you ran your above jupyter job.

### Add anaconda and opt-python modulefiles

Here, we add a module file for loading anaconda environment. Since we have made a few changes in the Rocks's opt-python module, we replace it with the new version. We should add because the Anaconda3 installation path is `/share/apps/anaconda3`, we initially name the module file "anaconda-3", but rename it to "anaconda3" which seems better. :-)

```sh
cd ~/my_rocks/modulesfiles
cp ./anaconda-3 ./opt-python /usr/share/Modules/modulefiles/anaconda3 # copy in frontend
cp ./anaconda-3 ./opt-python /share/apps/ # copy to a shared place
rocks run host compute "cp /share/apps/anaconda-3 /usr/share/Modules/modulefiles/" # copy to all nodes
rocks run host compute "mv /usr/share/Modules/modulefiles/anaconda-3 /usr/share/Modules/modulefiles/anaconda3" # change the name
rocks run host compute "cp /share/apps/opt-python /usr/share/Modules/modulefiles/" # copy to all nodes
```

### Change a compute node name

```sh
rocks set host name compute-0-23 compute-0-0
rocks sync config
```

### lua

Currently is not required, because in Lmod section we will install lua with rpms.

```sh
yum install ncurses*
wget -c https://netix.dl.sourceforge.net/project/lmod/lua-5.1.4.9.tar.bz2
tar -jxvf lua-5.1.4.9.tar.bz2
cd lua-5.1.4.9
./configure --with-static=no --prefix=/share/apps/lua
make && make install
```

### Lmod

- Install Lmod and lua on front-end:

```sh
cd Lmod_rpms
yum install ./*.rpms ##
```

Edit "/etc/profile.d/00-modulepath.sh" as:

```sh
[ -z "$MODULEPATH" ] &&
  [ "$(readlink /etc/alternatives/modules.sh)" = "/usr/share/lmod/lmod/init/profile" -o -f /etc/profile.d/z00_lmod.sh ] &&
  export MODULEPATH=/etc/modulefiles:/usr/share/Modules/modulefiles || :
```
- Install on nodes:

```sh
cp -r Lmod_rpms /share/apps/
cp install_Lmod.sh /share/apps
rocks run host compute "/share/apps/install_Lmod.sh"
```
- TODO: Must add post installation script for above commands or add rpms to rocks and build distro.

### Easybuild

```sh
useradd modules
passwd modules
rocks sync users
chmod a+rx /home/modules/

su -l modules

echo "
export EASYBUILD_MODULES_TOOL=Lmod
export EASYBUILD_PREFIX=/home/modules
" >> .bashrc

source .bashrc

curl -O https://raw.githubusercontent.com/easybuilders/easybuild-framework/develop/easybuild/scripts/bootstrap_eb.py

ml anaconda3 ## I will use the previous installed anaconda3 module

python bootstrap_eb.py $EASYBUILD_PREFIX

echo "
module use $EASYBUILD_PREFIX/modules/all
module load EasyBuild
module list
eb --version
" >> .bashrc
```
### Install libraries

I will use *my_easyconfig_files* directory to consider modified easyconfig files located in `my_easyconfig_files` directory. Please see https://easybuild.readthedocs.io/en/latest/Using_the_EasyBuild_command_line.html#use-robot.

- Install foss-2018b toolchain (GCC, OpenMPI, OpenBLAS/LAPACK, ScaLAPACK(/BLACS), FFTW)
```sh
eb --parallel=6 foss-2018b.eb --robot=$HOME/my_easyconfig_files
```
- Install LAPACK
```sh
eb --parallel=6 OpenBLAS-0.2.19-gompi-2018b-LAPACK-3.6.1.eb --robot=$HOME/my_easyconfig_files
```
- Add MCA parameter to OpenMPI module files. Open the file `modules/all/OpenMPI/3.1.1-GCC-7.3.0-2.30.lua` and add this environment variable in it.
```sh
setenv("OMPI_MCA_btl", "self,vader,tcp")
```

- Install CMake
```sh
eb CMake-3.12.1-GCCcore-7.3.0.eb -r
```

- Install Boost
```sh
eb -r Boost-1.67.0-foss-2018b.eb
```

#### Global setup of modules for all users

On CentOS systems the shell initialization scripts are in `/etc/profile.d/`. The Lmod RPM has installed several scripts here.

To set up the EasyBuild environment, create in `/etc/profile.d/` the file `z01_EasyBuild.sh`:

```sh
if [ -z "$__Init_Default_Modules" ]; then
 export __Init_Default_Modules=1
 export EASYBUILD_MODULES_TOOL=Lmod
 export EASYBUILD_PREFIX=/home/modules
 module use $EASYBUILD_PREFIX/modules/all
else
 module refresh
fi
```

Then

```sh
cp /etc/profile.d/z01_EasyBuild.sh /share/apps/
rocks run host compute "cp /share/apps/z01_EasyBuild.sh /etc/profile.d/z01_EasyBuild.sh"
```

### X11 forwarding

In forntend add:

```sh
ForwardX11Trusted       yes
```

Add `-Y` flag to the ssh command as:

```sh
ssh -Y username@172.21.99.202
```

Then use `interactive` command as explained before to get an interactive job. In another terminal login to the frontend as above and then to the node you are asigned, e.g.

```sh
ssh -Y compute-0-1
```

### Install Mathematica

```sh
su -l modules
mkdir sources/m/Mathematica
cp Mathematica_8.0.4_LINUX.sh sources/m/Mathematica/
eb Mathematica-8.0.4.eb --robot=$HOME/my_easyconfig_files
```

Copy the Mathematica

### Install NVIDIA HPC SDK

```sh
/bin/su -c "/share/apps/install_nvhpc.sh" - modules
```

Then add these lines to CUDA mudule file at /home/modules/modules/CUDA/CUDA...

```sh
conflict("nvhpc")
conflict("nvhpc-nompi")
conflict("nvhpc-byo-compiler")
```

and add this line to all nvhpc modules at /home/modules/modules/nvhpc...

```sh
conflict CUDA
```

### Install vim and nano on compute nodes

```
rocks run host compute "yum -y install nano vim"
```

## Storage

### Add the second HDD (/work1) on frontend

```sh
parted /dev/sdc mklabel gpt
parted /dev/sdc mkpart primary 0% 100%
mkfs.ext4 /dev/sdc1
cp /etc/fstab /etc/fstab.back
mkdir /work1
echo "/dev/sdc1                                /work1        ext4    defaults         1 2" >> /etc/fstab
mount -a
chmod 777 /work1
chmod o+t /work1
```

Then export it as

```sh
echo "/work1 10.1.1.1(rw,async,no_root_squash) 10.1.1.0/255.255.255.0(rw,async)" >> /etc/exports
exportfs -rv
rocks run host compute "echo 10.1.1.1:/work1 /work1 nfs rw,hard,intr,rsize=8192,wsize=8192  0 0 >> /etc/fstab"
rocks run host compute "mkdir /work1"
rocks run host compute "mount -a"
```

### Add the 3rd HDD (/work8) on frontend

parted /dev/sdd mklabel gpt
parted /dev/sdd mkpart primary 0% 100%
mkfs.ext4 /dev/sdd1
cp /etc/fstab /etc/fstab.back
mkdir /work8
echo "/dev/sdd1                                /work8        ext4    defaults         1 2" >> /etc/fstab
mount -a
chmod 777 /work8
chmod o+t /work8

Then export it as
```sh
echo "/work8 10.1.1.1(rw,async,no_root_squash) 10.1.1.0/255.255.255.0(rw,async)" >> /etc/exports
exportfs -rv
rocks run host compute "echo 10.1.1.1:/work8 /work8 nfs rw,hard,intr,rsize=8192,wsize=8192  0 0 >> /etc/fstab"
rocks run host compute "mkdir /work8"
rocks run host compute "mount -a"
```

### Link scratches

```sh
rocks run host compute "ln -s /state/partition1 /scratch1"
```

### Create the second partition on compute-0-2

```sh
parted /dev/sdb mklabel gpt
parted /dev/sdb mkpart primary 0% 100%
mkfs.ext4 /dev/sdb1
```
Then add the following line to the fstab file in compute-0-2

```sh
/dev/sdb1                                /state/partition2        ext4    defaults         1 2
```

and then

```sh
mount -a
```

```sh
chmod o+t /state/partition2
```
---
### Quota for extra HDD on frontend

```
### Change fstab as
/dev/sdc1                                /work1        ext4    defaults,usrquota,grpquota         1 2

umount /dev/sdc1
mount -a
quotacheck -cug /work1

### Generate the table of current disk usage per file system
quotacheck -vug /dev/sdc1
quotaon -v /dev/sdc1

### Assign quota per user
edquota user1
edquota -t  # grace period (all users)

### Verify that the quota for the user1, has been set
quota -vs username

### Prototype quota from user1 to user2
edquota -p user1 user2

################
/dev/sdd1                                /work8        ext4    defaults,usrquota,grpquota         1 2

umount /dev/sdd1

# using the above command the disk could not be unmounted. A process jbd2 was preventing it to unmount. We wait about one day for it, but it continued to run. Finally we find that turning of advanced power management on the drive solves the problem: hdparm -B 255 /dev/sdd

systemctl restart nfs <--- This solves the problem

mount -a
quotaoff -vug /dev/sdc1 <-- turn off quota on /dev/sdc1 (/work1)
quotacheck -cug /work8

### Generate the table of current disk usage per file system
quotacheck -vug /dev/sdd1
quotaon -v /dev/sdd1

### Assign quota per user
edquota user1
edquota -t  # grace period (all users)

### Verify that the quota for the user1, has been set
quota -vs username

### Prototype quota from user1 to user2
edquota -p user1 user2

### You can check all the assigned quota
repquota -as
```
---
## Network


Ref:
[https://github.com/shawfdong/hyades/wiki/Rocks](https://github.com/shawfdong/hyades/wiki/Rocks)

List networks:

```sh
rocks list network

NETWORK  SUBNET          NETMASK         MTU   DNSZONE  SERVEDNS
private: 10.6.0.0        255.255.0.0     1500  local    True    
public:  128.114.126.224 255.255.255.224 1500  ucsc.edu False
```

Add networks:

```sh
rocks add network ib subnet=10.8.0.0 netmask=255.255.0.0 mtu=4092
rocks add network 10g subnet=10.7.0.0 netmask=255.255.0.0 mtu=9000 #please note to mtu
rocks add network ipmi subnet=10.9.0.0 netmask=255.255.0.0
```

rocks list network

```sh
NETWORK  SUBNET          NETMASK         MTU   DNSZONE  SERVEDNS
10g:     10.7.0.0        255.255.0.0     9000  10g      False
ib:      10.8.0.0        255.255.0.0     4092  ib       False
ipmi:    10.9.0.0        255.255.0.0     1500  ipmi     False
private: 10.6.0.0        255.255.0.0     1500  local    True
public:  128.114.126.224 255.255.255.224 1500  ucsc.edu False
```

Set network interfaces on Hyades:

```sh
rocks set host interface subnet hyades iface=ib0 subnet=ib
rocks set host interface ip hyades iface=ib0 ip=10.8.8.1
rocks set host interface subnet hyades iface=em2 subnet=10g # 10G
rocks set host interface ip hyades iface=em2 ip=10.7.8.1    # 10G
rocks set host interface subnet hyades iface=em4 subnet=ipmi
rocks set host interface ip hyades iface=em4 ip=10.9.8.111

rocks list host interface hyades

SUBNET  IFACE MAC                                                         IP              NETMASK         MODULE NAME   VLAN OPTIONS CHANNEL
private em3   90:B1:1C:1C:56:41                                           10.6.8.1        255.255.0.0     ------ hyades ---- ------- -------
10g     em2   90:B1:1C:1C:56:3F                                           10.7.8.1        255.255.0.0     ------ hyades ---- ------- -------
public  em1   90:B1:1C:1C:56:3D                                           128.114.126.225 255.255.255.224 ------ hyades ---- ------- -------
ipmi    em4   90:B1:1C:1C:56:43                                           10.9.8.111      255.255.0.0     ------ hyades ---- ------- -------
ib      ib0   80:00:00:48:FE:80:00:00:00:00:00:00:00:02:C9:03:00:2A:4A:E7 10.8.8.1        255.255.0.0     ------ hyades ---- ------- -------

rocks sync config
rocks sync host network hyades
```
Ref for adding fast network:

[http://central-7-0-x86-64.rocksclusters.org/roll-documentation/base/7.0/x1403.html#AEN1410](http://central-7-0-x86-64.rocksclusters.org/roll-documentation/base/7.0/x1403.html#AEN1410)

See also [this thread](https://marc.info/?l=npaci-rocks-discussion&m=149321672225893&w=2).

---
### Add 10g to Scicluster network

List nework interfaces on head node

```sh
rocks list host interface sci

private eno2       00:25:90:94:5D:8D 10.1.1.1      255.255.255.0 ------ sci  ---- ------- -------
10g     enp129s0f1 ----------------- 10.7.7.1      255.255.255.0 ------ sci  ---- ------- -------
------- enp4s0f0   00:1B:CD:03:23:F4 ------------- ------------- ------ ---- ---- ------- -------
------- eno1       00:25:90:94:5D:8C 172.21.127.53 ------------- ------ sci  ---- ------- -------
------- enp4s0f1   00:1B:CD:03:23:F5 ------------- ------------- ------ ---- ---- ------- -------
------- enp4s0f2   00:1B:CD:03:23:F6 ------------- ------------- ------ ---- ---- ------- -------
------- enp4s0f3   00:1B:CD:03:23:F7 ------------- ------------- ------ ---- ---- ------- -------
```

Remove a previously added 10g interface on head node

```sh
rocks remove host interface sci enp129s0f1

SUBNET  IFACE    MAC               IP            NETMASK       MODULE NAME VLAN OPTIONS CHANNEL
private eno2     00:25:90:94:5D:8D 10.1.1.1      255.255.255.0 ------ sci  ---- ------- -------
------- enp4s0f0 00:1B:CD:03:23:F4 ------------- ------------- ------ ---- ---- ------- -------
------- eno1     00:25:90:94:5D:8C 172.21.127.53 ------------- ------ sci  ---- ------- -------
------- enp4s0f1 00:1B:CD:03:23:F5 ------------- ------------- ------ ---- ---- ------- -------
------- enp4s0f2 00:1B:CD:03:23:F6 ------------- ------------- ------ ---- ---- ------- -------
------- enp4s0f3 00:1B:CD:03:23:F7 ------------- ------------- ------ ---- ---- ------- -------
```

Remove testing IPs on compute-0-0 and 0-3

```sh
0-0
ip addr del 10.7.7.100/255.255.255.0 dev ens4f0 ---> (Mac address: 8c:dc:d4:b6:03:38)
ip addr del 10.7.7.254/255.255.255.0 dev ens4f1 ---> (Mac address: 8c:dc:d4:b6:03:39)
0-3
ip addr del 10.7.7.201/255.255.255.0 dev ens3f1 ---> (Mac address: 38:ea:a7:31:30:3d)
```

Add 10g on compute-0-0

```sh
rocks list host interface compute-0-0

ip link set dev ens4f1 up ---> (Mac address: 8c:dc:d4:b6:03:39)

rocks add host interface compute-0-0 iface=ens4f1 subnet=10g ip=10.7.7.254

rocks set host interface ip compute-0-0 iface=ens4f1 ip=10.7.7.254
rocks set host interface subnet compute-0-0 iface=ens4f1 subnet=10g
rocks set host interface name compute-0-0 iface=ens4f1 name=compute-10g-0-0
rocks set host interface mac compute-0-0 iface=ens4f1 mac=8c:dc:d4:b6:03:39
rocks sync config
rocks sync host network compute-0-0
```

Add 10g on compute-0-2

```sh
ip link set dev ens1f1 up ---> (Mac address: 14:02:ec:92:7f:c9)

rocks add host interface compute-0-2 iface=ens1f1 subnet=10g ip=10.7.7.252
rocks set host interface mac compute-0-2 iface=ens1f1 mac=14:02:ec:92:7f:c9
rocks set host interface ip compute-0-2 iface=ens1f1 ip=10.7.7.252
rocks set host interface subnet compute-0-2 iface=ens1f1 subnet=10g
rocks set host interface name compute-0-2 iface=ens1f1 name=compute-10g-0-2
rocks sync config
rocks sync host network compute-0-2
```

Add 10g on compute-0-3

```sh
rocks list host interface compute-0-3
SUBNET  IFACE MAC               IP         NETMASK       MODULE NAME        VLAN OPTIONS CHANNEL
private eno1  ec:eb:b8:86:1a:d0 10.1.1.251 255.255.255.0 ------ compute-0-3 ---- ------- -------
------- eno2  ec:eb:b8:86:1a:d1 ---------- ------------- ------ ----------- ---- ------- -------
------- eno4  ec:eb:b8:86:1a:d3 ---------- ------------- ------ ----------- ---- ------- -------
------- eno3  ec:eb:b8:86:1a:d2 ---------- ------------- ------ ----------- ---- ------- -------

ip link set dev ens3f1 up ---> (Mac address: 38:ea:a7:31:30:3d)

rocks add host interface compute-0-3 iface=ens3f1 subnet=10g ip=10.7.7.251
rocks set host interface mac compute-0-3 iface=ens3f1 mac=38:ea:a7:31:30:3d
rocks set host interface ip compute-0-3 iface=ens3f1 ip=10.7.7.251
rocks set host interface subnet compute-0-3 iface=ens3f1 subnet=10g
rocks set host interface name compute-0-3 iface=ens3f1 name=compute-10g-0-3
rocks sync config
rocks sync host network compute-0-3
```

```sh
rocks list host interface compute
```
