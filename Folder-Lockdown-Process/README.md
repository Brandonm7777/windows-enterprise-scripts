# Folder-Lockdown_Provisioning

This source code allows the user to "lockdown" a specific folder path located on their systems shared file server

**What it does:** The script below helps with folder lockdown request sent from end user. The manual process for locking down a folder path is a bit tedious such as manually creating two new AD groups, adding members, description and notes, disabling inheritance in the folder path, removing all other inherited groups as well as adding two newly created groups with the correct permissions (r\w, r\o). Sometimes the end user will send one off request to add two new groups for access to a folder path but does not need to be locked down. Luckily for you this script does it all of that.

**Purpose:** The purpose of this PowerShell script was to minimize manual efforts and streamline the process by adding naming standardization and username validation logic