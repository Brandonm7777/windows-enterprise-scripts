#START

 

#PROMPT USER FOR FOLDER PATH

 

$folderpath = Read-Host "`nPlease provide a folderpath to lock down. e.g...'\\<company>\apps\Test\Testing\foldertest\folderpathtest' "

$folderproperties = Get-Item -Path $folderpath | Select-Object *

$folderproperties

$acl = Get-Acl -Path $folderpath

 

#CONFIRM PATH IS CORRECT

 

$confirm = Read-Host "`nDoes the folder FullName look correct? Would you like to continue? (Y/N)"

if ($confirm -eq "Y" -or $confirm -eq "y"){

   

 

    Write-Host "`nLets Start with creating two new AD groups that will be used for your folder lockdown..." -ForegroundColor Green

    # Define the OU where you want to create the groups

    $ouPath = "OU=FileServer,OU=Groups,DC=COMPANY,DC=corp,DC=COMPANY,DC=com"

    # Function to ensure group name length

    function Ensure-GroupNameLength {

       param (

           [string]$baseName,

           [string]$suffix

       )

       $maxLength = 63

       $groupName = "$baseName$suffix"

       if ($groupName.Length -gt $maxLength) {

           $availableLength = $maxLength - $suffix.Length

           $baseName = $baseName.Substring(0, $availableLength)

           $groupName = "$baseName$suffix"

       }

       return $groupName

    }

    # Prompt the user for base group name and append _rw and _ro

    $baseGroupName = Read-Host "`nEnter the base name for the groups you want created (under 60 characters).i.e. 'fs_shared_princ-strat_test' I will append the _rw and _ro suffix"

 

    # Prompt the user for additional group attributes

   

    Write-Host "`nAdding description... 'Read\Write access to: $folderpath'"

    $descriptionrw = "Read\Write access to: $folderpath" #Read-Host "`nEnter the description wanted for the _rw group i.e. 'read\write access to: folderpath'"

   

    Write-Host "`nAdding description... 'Read Only access to: $folderpath'"

    $descriptionro = "Read Only access to: $folderpath" #Read-Host "`nEnter the description wanted for the _ro group i.e. 'read only access to: folderpath'"

   

    $managedByUsername = Read-Host "`nEnter the USERNAME of the OWNER\MANAGER for the groups"

    Start-Sleep -Seconds 2

    Write-Host "`nAdding to notes for both groups.... 'Approver: $managedByUsername '"

    $notes = "Approver: $managedByUsername" #Read-Host "`nEnter the notes for both groups i.e. 'Approver: username'"

   

    Write-Host "`nFeel free to edit description and notes once groups are created in AD..." -ForegroundColor Green

 

    try {

        $managedBy = Get-ADUser -Identity $managedByUsername -Properties DistinguishedName | Select-Object -ExpandProperty DistinguishedName

    } catch {

        Write-Host "User '$managedByUsername' not found."

        exit

    }

 

    # Prompt the user for members of the _rw group

    $rwMembers = Read-Host "`nEnter the usernames for the _RW group members, seperated by commas i.e. 'username1,username2,username3'"

    $rwMembersArray = $rwMembers -split "," | ForEach-Object { $_.Trim() }

 

    # Prompt the user for members of the _ro group

    $roMembers = Read-Host "`nEnter the usernames for the _RO group members, seperated by commas i.e. 'username1,username2,username3'"

    $roMembersArray = $roMembers -split "," | ForEach-Object { $_.Trim() }

 

    # Ensure the group names are under 63 characters

    $groupName_rw = Ensure-GroupNameLength -baseName $baseGroupName -suffix "_rw"

    $groupName_ro = Ensure-GroupNameLength -baseName $baseGroupName -suffix "_ro"

 

    Write-Host "`nCreating first group with _rw suffix....."

    Start-Sleep -Seconds 3

 

    # Create the first group with _rw suffix

    if (-not (Get-AdGroup -Filter {Name -eq $groupName_rw})) {

        New-ADGroup -Name $groupName_rw -Path $ouPath -GroupScope Global -GroupCategory Security -Description $descriptionrw -OtherAttributes @{info=$notes; managedBy=$managedBy}

        Write-Host "`nGroup '$groupName_rw' created successfully"

    } else {

        Write-Host "`nGroup '$groupName_rw' already exists."

    }

 

    Write-Host "`n adding members to '$groupName_rw'....."

    Start-Sleep -Seconds 3

 

    # Add members to the _rw group

    foreach ($member in $rwMembersArray) {

        try {

            $userDN = Get-ADUser -Identity $member -Properties DistinguishedName | Select-Object -ExpandProperty DistinguishedName

            Add-ADGroupMember -Identity $groupName_rw -Members $userDN

            Write-Host "`nUser '$member' added to group '$groupName_rw'."

        } catch {

            Write-Host "`nUser '$member' not found or could not be added to group '$groupName_rw'."

        }

    }

 

 

    Write-Host "`nCreating second group with _ro suffix....."

    Start-Sleep -Seconds 3

 

    # Create the second group with _ro suffix

    if (-not (Get-AdGroup -Filter {Name -eq $groupName_ro})) {

        New-ADGroup -Name $groupName_ro -Path $ouPath -GroupScope Global -GroupCategory Security -Description $descriptionro -OtherAttributes @{info=$notes; managedBy=$managedBy}

        Write-Host "`nGroup '$groupName_ro' created successfully"

    } else {

        Write-Host "`nGroup '$groupName_ro' already exists."

    }

 

    Write-Host "`n adding members to '$groupName_ro'....."

    Start-Sleep -Seconds 10

 

    # Add members to the _ro group

    foreach ($member in $roMembersArray) {

        try {

            $userDN = Get-ADUser -Identity $member -Properties DistinguishedName | Select-Object -ExpandProperty DistinguishedName

            Add-ADGroupMember -Identity $groupName_ro -Members $userDN

            Write-Host "`nUser '$member' added to group '$groupName_ro'."

        } catch {

            Write-Host "`nUser '$member' not found or could not be added to group '$groupName_ro'."

        }

    }

 

   

    

    #REMOVE THE GROUPS SPECIFIED

 

    # check if the inheritance is disabled

    Write-Host "`nLets continue with disabling Inheritance to the folder path. Checking..."

    Start-Sleep -Seconds 2

    $confirmInheritance = Read-Host "`nWould you like to continue with disabling Inheritance? (Y/N)"

    if ($confirmInheritance -eq "Y" -or $confirmInheritance -eq "y"){

        try {

            if ($acl.AreAccessRulesProtected) { Write-Host "`nInheritance is already disabled. Lets continue.`n "} else {

            Write-Host "`nInheritance is enabled. Disabling inheritance..."

            $acl.SetAccessRuleProtection($true,$true) # this will disable inheritance and preserve exisiting inherited permissions

            Start-Sleep -Seconds 2

            Set-Acl -Path $folderPath -AclObject $acl

            Write-Host "`nInheritance has been disabled, lets continue."

            }

    } catch {Write-Host "Inheritance will not be disabled...."}

    }

 

    $acl = Get-Acl -Path $folderpath

    $acl.Access

 

    $confirmRemovals = Read-Host "Would you like to remove any groups? (Y/N)"

    if ($confirmRemovals -eq "Y" -or $confirmRemovals -eq "y"){

 

       

        $groupInput = Read-Host "`nReferring to each object's 'IdentityReference', enter the groups you want to remove seperated by commas (NO SPACES) i.e. 'fs_shared_test_rw,fs_shared_folder_ro' !!!TYPE 'n/N' IF NO GROUP ARE NEEDED FOR REMOVAL!!!"

        # split the input into an array of group names

        $groupNamesToRemove = $groupInput -split ',' | ForEach-Object { "HPS\$_".Trim() }

        # prompt the user to confirm the groups to be removed

        Write-host "`nGroups to be removed: $($groupNamesToRemove -join ', ')"

        $confirmation = Read-Host "`nConfirm removal of the listed groups (Y/N)"

        # If confirmed, proceed with the removal

        if ($confirmation -eq "Y" -or $confirmation -eq "y") {

            # select the access rules for the specified group names

            $accessRulesToRemove = $acl.Access | Where-Object { $groupNamesToRemove -contains $_.IdentityReference.Value }

            Write-Host "`nPlease wait 3 seconds for groups to be removed..."

            # remove the selected access rules

            foreach ($rule in $accessRulesToRemove)

        {

                $acl.RemoveAccessRule($rule)

            }

            # set the modified ACL back to thefolder

            Set-Acl -Path $folderPath -AclObject $acl

            Start-Sleep -Seconds 5 # wait 5 seconds for removal of groups to comlete

            Write-Host "`nAccess rules for the specified groups have been successfully removed."

            $acl.Access

        } else {

            Write-Host "`nRemoval of access rules canceled."

        }

    }

} #else{Write-Host "`nNo groups will be removed...."}

 

Start-Sleep -Seconds 2

$addgroups = Read-Host "`nShall we proceed with adding AD groups to folder path: '$folderpath'? (Y/N)"

if ($addgroups -eq "Y" -or $addgroups -eq "y"){

   

    #ADD GROUPS SPECIFIED

 

    Write-Host "`n Adding '$groupName_rw' for READ\WRITE access..."

    Start-Sleep -Seconds 3

    $trimrw = $groupName_rw -split ',' | ForEach-Object { "HPS\$_".Trim() }

    $accessRule = New-Object System.Security.AccessControl.FileSystemAccessRule($trimrw, "Modify", "ContainerInherit,ObjectInherit", "None", "Allow")

    $acl.AddAccessRule($accessRule)

 

   

    Write-Host "`n Adding '$groupName_ro' for READ ONLY access..."

    Start-Sleep -Seconds 3

    $trimro = $groupName_ro -split ',' | ForEach-Object { "HPS\$_".Trim() }

    $accessRule = New-Object System.Security.AccessControl.FileSystemAccessRule($trimro, "ReadAndExecute", "ContainerInherit,ObjectInherit", "None", "Allow")

    $acl.AddAccessRule($accessRule)

 

    Start-Sleep -Seconds 3

    # set the modified ACL back to the folder

    Set-Acl -Path $folderpath -AclObject $acl

    Start-Sleep -Seconds 2

    $acl.Access

    Write-Host "`nAccess rules for the specified groups have been successfully added." -ForegroundColor Green

    } else { Write-Host "`nAddition of access rules canceled."

}  

 

Write-Host "`n `nFeel free to use the prompt below to send off to the requester. `n `n `nFolderpath: $folderpath has been locked down. `n `nTwo new groups have been created for access: $groupName_rw , $groupName_ro `n `n$managedByUsername is the Approver and owner of both groups. `n `nAll users have been added and granted their respective access to $folderpath `n `nThank you,"