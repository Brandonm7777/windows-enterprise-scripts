Connect-VIServer -Server <servername>,<servername02> -warningaction silentlycontinue

$Credentials = Get-Credential

 

$VDIname = Read-Host "`nPlease provide a VDI name to expand their drive. i.e... 'testvdi-vdi1'"

 

Get-WmiObject -Class win32_logicaldisk -ComputerName $VDIname | Format-Table DeviceId, MediaType, @{n="Size";e={[math]::Round($_.Size/1GB,2)}},@{n="FreeSpace";e={[math]::Round($_.FreeSpace/1GB,2)}}

 

# Prompt for confirmation

$confirm = Read-Host "Would you like to continue with expanding '$VDIname'? (Y/N)"

if ($confirm -eq "Y" -or $confirm -eq "y") {

 

    $GBsAdded = Read-Host "`nHow many GBs would you like to add to '$VDIname'? "

 

    ForEach ($VDI in $VDIname) {

        $WinSizeBefore = (Get-WmiObject Win32_LogicalDisk -ComputerName $VDI -Filter "DeviceID='C:'").Size / 1024 / 1024 / 1024

        get-vm $VDI | get-snapshot | Remove-Snapshot -Confirm:$false -RunAsync

        Write-Host "`nWaiting 30 seconds, snapshot needs to be removed before continuing... "

        Start-Sleep -Seconds 30 # wait 30 secs for snapshot removal


        try {

            $CurrentGB = Get-HardDisk $VDI | Select-Object -ExpandProperty CapacityGB

            $ExpandedGB = $CurrentGB + $GBsAdded

            Write-Host "`nExpanding $VDI VMDK from $CurrentGB to $ExpandedGB GB, please wait 45 seconds..."

            $VDIhd = Get-HardDisk $VDI

            $ParentDisk = $VDIhd[0]

            Set-HardDisk -HardDisk $ParentDisk -CapacityGB $ExpandedGB -Confirm:$false

            Start-Sleep -Seconds 50 # wait 30 secs for for disk expansion

        }   

        catch {

            Write-Host "`nUnable to process VMDK expansion"

        }

 

        #try {

        Copy-Item -Path C:\Temp\Powershell\Expand-cPartition.ps1 -Destination filesystem::\\$VDI\c$\Windows\Temp

        $result = Invoke-VMScript -VM $VDI -ScriptType bat -ScriptText "powershell.exe -noprofile -executionpolicy bypass -file c:\windows\temp\Expand-cPartition.ps1" -GuestCredential $Credentials

        if ($result.ScriptOutput) {

            Write-Output "`nScript output:"

            Write-Output $result.ScriptOutput

        } else {

            Write-Output "No script output."

        }


        $WinSizeAfter = (Get-WmiObject Win32_LogicalDisk -ComputerName $VDI -Filter "DeviceID='C:'").Size / 1024 / 1024 / 1024

        $PostChangeGB = Get-HardDisk $VDI | Select-Object -ExpandProperty CapacityGB


        Write-Host "`n$VDI disk sizes: Windows Before ($WinSizeBefore), Windows After ($WinSizeAfter), VMDK Before ($CurrentGB), VMDK After ($PostChangeGB)`n" | Out-File -FilePath c:\windows\temp\drive-expansion-log.txt -Append -Encoding utf8

       

    } 

}

 

$clearingsearchindex = {

  try {

      # Stop the windows search service

      Stop-Service WSearch -Force -ErrorAction Stop

      # Delete the contents of the search index folder

      Remove-Item -Path "C:\ProgramData\Microsoft\Search\Data\*" -Recurse -Force -ErrorAction Stop

           

      Write-Output "`nSearch index cleared and rebuilt successfully."}

      catch { Write-Error "Failed to clear and rebuild search index: $_"}

      }

 

Invoke-Command -ComputerName $VDIname -Credential $Credentials -ScriptBlock $clearingsearchindex

 

Get-WmiObject -Class win32_logicaldisk -ComputerName $VDIname | Format-Table DeviceId, MediaType, @{n="Size";e={[math]::Round($_.Size/1GB,2)}},@{n="FreeSpace";e={[math]::Round($_.FreeSpace/1GB,2)}}

 

Write-Output "`nCongratualtions you are done."