# Define the name of the group you want to delete

 

$groupName = Read-Host "Enter the name of the group you want to delete"

 

if (Get-ADGroup -Filter {Name -eq $groupName}) {

   # Prompt for confirmation

   $confirm = Read-Host "Are you sure you want to delete the group '$groupName'? (Y/N)"

   if ($confirm -eq "Y" -or $confirm -eq "y") {

      

       # Define the delay before deletion (in days)

 

        $delayDays = Read-Host "Enter the number of days in which you wish for the group to be deleted I.e. ( 1-6 )"

 

        # Calculate the date and time when the task should run

 

        $taskStartTime = (Get-Date).AddDays($delayDays)

 

        # Create a trigger for the scheduled task

 

        $trigger = New-ScheduledTaskTrigger -Once -At $taskStartTime

 

        # Create an action to run the PowerShell script

 

        $action = New-ScheduledTaskAction -Execute "PowerShell.exe" -Argument "-File C:\temp\PSScripts\ADGroupDecommissionScript\post-full-adgroup-decommission.ps1"

        

        # unregister the scheduled task if it already exists

 

        Unregister-ScheduledTask -TaskName "DeleteGroupTask" -Confirm:$false

 

        # Register the scheduled task with Task Scheduler

 

        Register-ScheduledTask -TaskName "DeleteGroupTask" -Trigger $trigger -Action $action -RunLevel Highest -Force -Description "Deletes group '$groupName' after $delayDays days"

              

        # Get the group object from Active Directory

 

        $group = Get-ADGroup -Identity $groupName -Properties DistinguishedName, Members, MemberOf, ManagedBy, Description

 

        # Check if the group object exists

 

        if ($group) {

           # Create a custom object with the desired properties

 

           $groupInfo = [PSCustomObject]@{

               DistinguishedName = $group.DistinguishedName

               Members = ($group.Members | Get-ADUser | Select-Object -ExpandProperty Name) -join ","

               MemberOf = ($group.MemberOf | Get-ADGroup | Select-Object -ExpandProperty Name) -join ","

               ManagedBy = $group.ManagedBy

               Description = $group.Description

           }

           # Export the custom object to a CSV file

 

           $groupInfo | Export-Csv -Path "C:\temp\DecommissionedADGroups\decommissioned_$groupName.csv" -NoTypeInformation

 

           Write-Output "`nGroup properties exported to 'C:\temp\DecommissionedADGroups\decommissioned_$groupName.csv'."

        } else {

           Write-Output "`nGroup '$groupName' not found in Active Directory."

        }

 

        # Check if the group object exsists

 

        if ($group) {

            # Remove all users from the Members property

            $group.Members | ForEach-Object {

                Remove-ADGroupMember -Identity $group.DistinguishedName -Members $_ -Confirm:$false

                }

 

            $group.MemberOf | ForEach-Object {

                Remove-ADGroupMember -Identity $_ -Members $group.DistinguishedName -Confirm:$false

                }

        }

        if ($group.ManagedBy) {

            Set-ADGroup -Identity $group.DistinguishedName -ManagedBy $null

            }

 

 

       Write-Output "`nYOUR GROUP '$groupName' WILL BE DELETED IN: '$delayDays' Day(s)"

   } else {

       Write-Output "`nDeletion of group '$groupName' cancelled."

   }

} else {

   Write-Output "`nGroup '$groupName' not found in Active Directory."

}