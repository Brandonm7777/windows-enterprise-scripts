# Define the name of the group you want to delete


$groupName = Read-Host "Enter the name of the group you want to delete"


if (Get-ADGroup -Filter {Name -eq $groupName}) {

   # Prompt for confirmation

   $confirm = Read-Host "`nAre you sure you want to delete the group '$groupName'? (Y/N)"

   if ($confirm -eq "Y" -or $confirm -eq "y") {

        

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


           $groupInfo | Export-Csv -Path "C:\temp\DecommissionedADGroups\COMPLETED\decommissioned_$groupName.csv" -NoTypeInformation


           Write-Output "`nGroup properties exported to 'C:\temp\DecommissionedADGroups\COMPLETED\decommissioned_$groupName.csv'."

        } else {

           Write-Output "`nGroup '$groupName' not found in Active Directory."

        }

 

        Write-Output "`nDeleting '$groupName' ...."

        Start-Sleep -Seconds 2

           Remove-ADGroup -Identity $groupName -Confirm:$false

   Write-Output "`nGroup '$groupName' has been successfully deleted."

} else {

   Write-Output "`nGroup '$groupName' not found in Active Directory."

}

}