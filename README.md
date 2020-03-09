My Rocks and slurm notes
========================

## User management


### Add New Users

```
su -
useradd username
passwd username
rocks sync users
```

### Deleting Users

```
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

### SLURM notes

### Add a slurm partition 

Edit `/etc/slurm/parts ` for example:

```
PartitionName=WHEEL RootOnly=yes Priority=1000 Nodes=ALL
PartitionName=SHORT MaxTime=1-0:0 DefaultTime=00:30:00 DefMemPerCPU=512 TRESBillingWeights="CPU=1.0,Mem=0.25G,GRES/gpu=2.0" MaxNodes=1
PartitionName=LONG MaxTime=7-0:0 DefaultTime=00:30:00 DefMemPerCPU=512 TRESBillingWeights="CPU=1.0,Mem=0.25G,GRES/gpu=2.0" MaxNodes=1
```

Then assign a node to the created partition

```
rocks add host attr compute-0-1 slurm_partitions value='|CLUSTER|WHEEL|SHORT|'
```

If the attribute already exists, do

```
rocks set host attr compute-0-0 slurm_partitions value='|CLUSTER|WHEEL|SHORT|'
```

And finally don't forget to do
`rocks sync slurm`

## Anaconda installation and configuration

### Anaconda system wide installation

At the final step of installation, please choose to not have conda modify your shell scripts at all. 

To activate conda's base environment in your current shell session:

`eval "$(/share/apps/anaconda3/bin/conda shell.bash hook)"`

To install conda's shell functions for easier access, first activate, then:

`conda init`

If you'd prefer to conda's base environment not be activated on startup, set the auto_activate_base parameter to false: 

`conda config --set auto_activate_base false`

### Configure conda for all users 

To properly configure conda for using `conda activate` for all users, please run:

```
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

```
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
