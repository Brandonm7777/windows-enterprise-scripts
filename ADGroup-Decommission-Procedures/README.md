# ActiveDirectory-Securitygroup-Decommision

This source code allows the user to "clean up" stale active directory groups and provide a regulated process in removing security groups as well

**What it does:** There are two parts, one script copys all of the groups metadata and information into an excel spreadsheet saves it, then deletes the group with no delay. The second script does the same but adds a timer using Task scheduler

*Purpose:** The purpose of this powershell scriptwas to minimize manual efforts as well as streamline and standardize the decomissiong of AD groups

