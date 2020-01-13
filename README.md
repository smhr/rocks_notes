My Rocks and slurm notes
========================

## Add/delete Users


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

Missing /etc/411-security/shared.key issue
When a node reinstalls, it is supposed to ask the frontend to sync the sharedkey. It usually works,
but apparently not always (e.g. a rocks bug). Without the shared key, the nodes can't decode the 411 files (by design). the 411 files do contain crypted passwords.

to fix it, use

`rocks sync host sharedkey compute`

Comments on "/etc/default/useradd"
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
PartitionName=TEST AllowAccounts=root AllowGroups=wheel,root
PartitionName=SHORT
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

