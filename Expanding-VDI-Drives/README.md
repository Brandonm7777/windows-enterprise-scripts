# Expanding-hard-drives

This source code allows the user to expand any disk drive on any virtual machine in vSphere.

**What it does:** The script will connect to your on-premise vSphere server(s) >> delete the virtual machines most current snapshot >> add space to the disk drive >> copy a diskpart bash script locally on the machine to help remove recovery partition and extend the allocated extra disk space >> rebuild the targeted machines windows search index in other words locat and delete the windows search.edb file. We have seen in the past where the windows .edb files grows abnormally large. This script can be run at any time without interrupting the user. 

**Purpose:** The purpose of this PowerShell script was to minimize the downtime a user was disconnected from their VDI and consolidate all the steps it takes for expanding a disk drive into one script which takes less than 3 minutes to complete.
