Instructions for Visual Cloud Computing in GENI platform.

=========================================================
Authors: Dmitrii Chemodanov, Dr. Prasad Calyam
Affilation: University of Missouri-Columbia, USA
=========================================================

=========================================================
I. VCC Experiment Setup
Workflow: allocate VCC controller -> add ctrl IP  address to rspec and allocate testbed -> run POX ctrl and authorize hosts -> update execution scripts and transfer corresponding data to the Fog -> Test LOFT application work 

1) Allocate VCC controller:
    a) download vcc_ctrl.rspec
    b) using any instageni Aggregation Manager (AM) and any tool (e.g., omni, Jack) of your choice allocate VCC controller in GENI
    c) save login information
    d) obtain and save IP address of the controller (e.g., using ping)

2) Specify controller IP address in vcc_cloud_fog.rspec and allocate Cloud/Fog testbed in GENI (NOTE!!!: currently, node h1 in the vcc_cloud_fog.rspec has to be allocated at the Wisconsin-IG site as some of the LOFT application libraries were installed in its shared HDD space)
    a) download vcc_cloud_fog.rspec
    b) open it in any text editor of your choice, and substitute IP address of controller for ALL 3 switches (i.e., s1, s2 and s3);
       - to do that find the following command:
         "<execute command="sudo ovs-vsctl set-controller br0 tcp:<ctrl IP addr>:6653" shell="/bin/sh"/>"
       - substitute your ctrl IP address with "<ctrl IP addr>", e.g.,:
         "<execute command="sudo ovs-vsctl set-controller br0 tcp:8.8.8.8:6653" shell="/bin/sh"/>"
    c) [optional] for correctness of the experiment we need realistic transmission delays; to emulate them, we are using NETEM linux emulator. Alternatively, it's possible to use "GENI stitching" feature to assign Cloud and Fog resources to different geographical locations (complicates a resource allocation process). If you wish to use "GENI stitching", please, comment the following lines in the respec for ALL 3 switches:
        "<execute command="sudo tc qdisc del dev eth1 root" shell="/bin/sh"/>
         <execute command="sudo tc qdisc add dev eth1 root netem delay 5ms" shell="/bin/sh"/>
         <execute command="sudo tc qdisc del dev eth2 root" shell="/bin/sh"/>
         <execute command="sudo tc qdisc add dev eth2 root netem delay 5ms" shell="/bin/sh"/>"
    d) save changes    
    e) using Wisconsin-IG (unless geni stitching applied) AM and any tool (e.g., omni, Jack) of your choice allocate VCC Cloud/Fog testbed in GENI
       - NOTE: if you wish to use GENI stitching, you may use Jack tool to assign different geographical sites (AMs) for the Cloud (i.e., h1,h3,s1), the Fog (i.e., h2,s2) and the transmission node (i.e., s3) resources. However, the Cloud resources currently can be allocated only in Wisconsin-IG
    f) save login information
    
3) Run POX controller and authorize hosts for ssh/scp access without password
    a) login to VCC controller and type the following commands to run POX controller: 
        $ cd  ../../pox/
        $ ./pox.py --verbose openflow.of_01 --port=6653 forwarding.l2_learning openflow.discovery openflow.spanning_tree
    b) to authorize h1 for h2 remote access, login to host h1 and type:
        $ ssh-keygen -t rsa 
        (do not enter a passphrase)
        $ ssh <user_name>@h2 mkdir -p .ssh
        (NOTE: command will ask your h2 password; to provide it, you always may login to h2 and use "sudo passwd <user_name>" command to assign new password)
        $ cat .ssh/id_rsa.pub | ssh <user_name>@h2 'cat >> .ssh/authorized_keys'
        (NOTE: command will ask your h2 password)
    c) similarly, use commands in b) to authorize h2 for h1 and h3 remote accesses 
       (for details refer to http://www.linuxproblem.org/art_9.html)
    d) keep running POX controller
       
4) Update execution scripts and transfer corresponding data to the Fog
    a) login to h1 and type:
        $ cd ../../tracking/LOFT_Lite/data/scripts
    b) open cloud_processing.sh (using any text editor of your choice) and update "fog_host_name_with_path" variable by substituting "dycbt4" for your user name:
        "fog_host_name_with_path=10.0.0.2:/users/<user_name>/raw"
    c) similarly, open cloud_fog_processing.sh and update "cloud_user_host" variable:
        "<user_name>@10.0.0.1"
    d) open storage_transfer.sh and update "storage_host_name_with_path" variable:
        "10.0.0.3:/users/<user_name>/"
    c) transfer corresponding data to the fog by typing the following commands from scritps/ directory:
        $ ssh <user_name>@h2 mkdir -p scripts raw
        $ scp cloud_fog_processing.sh storage_transfer.sh h2:/users/<user_name>/scripts
        $ scp ../raw/*.tif h2:/users/<user_name>/raw
        (NOTE: after step 3), ssh/scp commands should not ask you to specify password)
        
5) Test LOFT application work
    a) relogin to h1 with X desktop property (e.g., ssh -X ...) if needed
    b) type the following commands to run LOFT application in test mode:
        $ cd /tracking/LOFT_Lite/data/config_files
        $ ../../bin/linux/MUtracking ped_test.cfg
        (NOTE: if LOFT cannot find all required libraries, try the following command and try to start it again: 
        $ export LD_LIBRARY_PATH=/tracking/MATLAB/v711/runtime/glnxa64/:/tracking/LOFT_Lite/extern/CentOS_x86_64/:$LD_LIBRARY_PATH
        ")
    c) you should be able to see dummy pedastrian data in the X desktop window and the following output below:
        "h1:/tracking/LOFT_Lite/data/config_files$ ../../bin/linux/MUtracking ped_test.cfg
         MUTracking interface for LOFT-Lite and CSURF Version VHEAD-HASH-NOTFOUND.HEAD-HASH-NOTFOUND.HEAD-HASH-NOTFOUND
         File appears to have a config file extension..trying the MUConfig file reader
         done with a config file (# of lines : 22 )
         Time for parsing the config file : 0 ms
         Initializing MCR..........Success
         Tiled tiff reader initialized
         Initializing LOFT library.......Success
         563 230
         Number of tiles required in the x dim : 0
         Number of tiles required in the y dim : 0
         x1: 563 y1: 230
         tile_top_x: 384 tile_top_y: 0
         ULx1: 134 ULy1: 170
         0.814977
         Time taken to track (this frame): 2620 ms
         Total tracking time : 2620ms
         Current waiting time (this frame): 0 ms
         Total waiting time: 0 ms
         ...
        "

NOTE: all RSpec, scripts and VCC controller config files can be downloaded from repository in case there were accidently removed!
=========================================================

=========================================================
II. VCC Cloud Computing over Best-effor IP network Experiment
Workflow: prepare for experiment (ssh to hosts, run POX) -> perform experiment -> collect and analyze data -> repeat 