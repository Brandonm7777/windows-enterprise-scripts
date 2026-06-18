
# Import Modules and Set Variables

cd c:

Import-Module activedirectory

$techemail = Get-ADUser (whoami).replace("COMPANY\","").replace("da-","").replace("adm-","") -Properties mail | Select-Object -ExpandProperty mail

$CitrixSession = New-PSSession -ComputerName COMPANYPRDNYCTXDC03

Invoke-Command -Command {Add-PSSnapin Citrix.*} -Session $CitrixSession

$null = Import-PSSession -Session $CitrixSession -Module Citrix.*

 

# Clear the screens and re-size the window

clear-host

 

# Begin collecting user account variables

write-host ""

write-host "Welcome to the COMPANY user account creation script"

write-host ""

 

while ($fname.length -lt 2) {

    [string]$fname = read-host "Enter the user's first name (req'd)   "

}

while ($lname.length -lt 1) {

    [string]$lname = read-host "Enter the user's last name (req'd)    "

}

 

$uname = $fname.ToLower().Substring(0,1) + `

    ([System.Text.RegularExpressions.Regex]::Replace($lname,"[^1-9a-zA-Z_]","")).ToLower()

if ($uname.length -gt 10) {$uname = $uname.Substring(0,10)}

 

$unchk = get-aduser -filter {samaccountname -eq $uname}

 

while ([bool]$unchk -eq $True) {

    write-host "The username $uname already exists."

    $uname = Read-Host "Please enter a unique username        "

    $unchk = get-aduser -filter {samaccountname -eq $uname}

}

 

$dname = $fname + " " + $lname

$upn = $fname.ToLower() + '.' + $lname.ToLower() + '@company.com'

$upn = $upn.Replace(" ","")

 

[string]$phonw = read-host "Enter the user's phone number         "

[string]$phonm = read-host "Enter the user's mobile number        "

do {[string]$edept = read-host "Enter the user's department           "}

while ($edept.Length -lt 3)

 

$mgrun = read-host "Enter the username of their manager   "

if ($mgrun -eq "") {$mgrun = "zzzzzzzzz"}

$mgrck = get-aduser -filter {samaccountname -eq $mgrun} -Properties mail -ErrorAction SilentlyContinue

 

while ([bool]$mgrck -ne $True) {

    $mgrun = read-host "Enter the username of their manager   "

    if ($mgrun -eq "") {$mgrun = "zzzzzzzzz"}

    $mgrck = get-aduser -filter {samaccountname -eq $mgrun} -Properties mail -ErrorAction SilentlyContinue

}

 

$mgrname = $mgrck | Select-Object -ExpandProperty Name

$mgremail = $mgrck | Select-Object -ExpandProperty mail

 

$title = read-host "Enter the user's title                "

$offic = read-host "Enter the users office                "

 

# Check if the user is a consultant or not

do {$is_cn = read-host "Is the user a consultant? (y/n)       "}

while ($is_cn.ToLower() -ne "y" -and $is_cn.ToLower() -ne "n")

 

if ($is_cn.ToLower() -eq "y") {

    do {$ccpny = read-host "Enter consulting company (required!)  "} while ($ccpny -eq "")

    $ecpny = $ccpny + " (Consultant)"

    $upath = "OU=Vendors,OU=People,DC=COMPANY,DC=corp,DC=COMPANY,DC=com"

    $ounit = "COMPANY.corp.COMPANY.com/People/Vendors"

}

 

else {

    $ecpny = "COMPANY Investment Partners"

    $upath = "OU=Standard,OU=People,DC=HPS,DC=corp,DC=hpspartners,DC=com"

    $ounit = "COMPANY.corp.company.com/People/Standard"

}

 

#Check what type of mail accounts are needed

do {$ms365 = read-host "Create an Office 365 account? (y/n)   "}

while ($ms365.ToLower() -ne "y" -and $ms365.ToLower() -ne "n")

 

if ($ms365.ToLower() -eq "y") {

    $exonl = "n"

    $email = $fname + '.' + $lname + '@company.com'

    $email = $email.Replace(" ","")

#    do {$mobil = read-host "Create Mobility account? (y/n)        "}

#    while ($mobil.ToLower() -ne "y" -and $mobil.ToLower() -ne "n")

}

 

if ($ms365.ToLower() -eq "n" -and $is_cn.ToLower() -eq "y") {

    do {$email = read-host "Enter consultant's external email     "}

    while ($email -notmatch "@")

}

 

<#

if ($ms365.ToLower() -eq "n") {

    do {$exonl = read-host "Create Exchange Online account? (y/n) "}   

    while ($exonl.ToLower() -ne "y" -and $exonl.ToLower() -ne "n")

}

#>

 

# Confirm account details

Write-Host ""

Write-Host ""

Write-Host "****************************************************************************"

Write-Host "****************************************************************************"

Write-Host "***"

Write-Host "***  A new user will be created with the following details."

Write-Host "***"

Write-Host "***  First Name:        $fname"

Write-Host "***  Last Name:         $lname"

Write-Host "***  Display Name:      $dname"

Write-Host "***  Username:          $uname"

Write-Host "***  OU:                $ounit"

Write-Host "***  UPN:               $upn"

Write-Host "***  Email:             $email"

Write-Host "***  H Drive:           \\company\users\home\$uname"

Write-Host "***  Telephone Number:  $phonw"

Write-Host "***  Mobile Number:     $phonm"

Write-Host "***  Office:            $offic"

Write-Host "***  Company:           $ecpny"

Write-Host "***  Department:        $edept"

Write-Host "***  Title:             $title"

Write-Host "***"

Write-Host "****************************************************************************"

Write-Host "****************************************************************************"

Write-Host ""

Write-Host ""

 

do {$conf1 = read-host "Type 'confirm' to proceed or ctl+c to exit"}

    while ($conf1.ToLower() -ne "confirm")

 

# Create AD User Account

$txtpasswd = -join (33..126 | ForEach-Object {[char]$_} | Get-Random -Count 20)

$secpasswd = ConvertTo-SecureString $txtpasswd -AsPlainText -Force

 

New-ADUser `

    -SamAccountName $uname `

    -UserPrincipalName $upn `

    -GivenName $fname `

    -Surname $lname `

    -DisplayName $dname `

    -Name $dname `

    -AccountPassword $secpasswd `

    -PasswordNeverExpires $False `

    -Enabled $True `

    -AllowReversiblePasswordEncryption $False `

    -OfficePhone $phonw `

    -MobilePhone $phonm `

    -Path $upath `

    -Department $edept `

    -Company $ecpny `

    -Title $title `

    -Manager $mgrun `

    -Office $offic `

    -OtherAttributes @{'ipPhone' = "1234"}

 

Write-Host ""

Write-Host ""

Write-Host ">>>  AD account has been created."

 

if ($ms365.ToLower() -eq "y") {

    Set-ADUser -Identity $uname -EmailAddress $email

    Send-MailMessage -SmtpServer mailrelay -From "$techemail" -To workdayemaildomaincom -Cc "$techemail" -Subject "New Hire Information for $fname $lname" -Body "<p>Workday Team:  A new user account has been created for $fname $lname with the following information.  Please review to see if Workday needs to be updated with any of the information below.  Thank you.</p><ul><li>First Name: $fname</li><li>Last Name: $lname</li><li>Display Name: $dname</li><li>Username: $uname</li><li>Email Address: $email</li><li>Company: $ecpny</li><li>Department: $edept</li><li>Title: $title</li><li>Telephone Number: $phonw</li><li>Mobile Number: $phonm</li></ul>" -BodyAsHtml

}

 

if ($ms365.ToLower() -eq "n" -and $is_cn.ToLower() -eq "y") {

    Set-ADUser -Identity $uname -EmailAddress $email

}

 

Add-ADGroupMember -Identity gr_azure_authentication_sspr -Members $uname

Add-ADGroupMember -Identity gr_azure_intune_ios_native_calendar_contacts_only -Members $uname

if ($is_cn.ToLower() -eq "n") {Add-ADGroupMember -Identity gr_company_all -Members $uname; Add-ADGroupMember -Identity gr_citrix_login -Members $uname; Add-ADGroupMember -Identity gr_azure_sso_officespace -Members $uname; Add-ADGroupMember -Identity gr_intune_company_covid_us -Members $uname}

if ($ms365.ToLower() -eq "y") {Add-ADGroupMember -Identity gr_azure_license_m365 -Members $uname;Add-ADGroupMember -Identity gr_azure_sso_intune_corp_mdm -Members $uname}

#if ($ms365.ToLower() -eq "y" -and $mobil.ToLower() -eq "y") {Add-ADGroupMember -Identity gr_azure_license_m365 -Members $uname;Add-ADGroupMember -Identity gr_azure_sso_intune_corp_mdm -Members $uname}

#if ($ms365.ToLower() -eq "y" -and $mobil.ToLower() -eq "n") {Add-ADGroupMember -Identity gr_azure_license_o365 -Members $uname;Add-ADGroupMember -Identity gr_azure_license_aadp1 -Members $uname}

if ($ms365.ToLower() -eq "y") {Add-ADGroupMember -Identity gr_azure_sso_mimecast -Members $uname}

if ($ms365.ToLower() -eq "n") {Add-ADGroupMember -Identity gr_azure_license_aadp1 -Members $uname}

 

Write-Host ">>>  Mailbox created (if applicable)."

 

# Create and permission required network folders

$null = New-Item -path \\domain\users\home -name $uname -ItemType directory                      #edit correct domain Name

Start-Sleep -s 15

$null = icacls \\domain\users\home\$uname /grant $uname`:`(OI`)`(CI`)M                #edit correct domain Name

 

Write-Host ">>>  Home directory created and ACEs applied."

Write-Host ""

Write-Host ""

 

# Send approvals to copy group memberships of an existing user

 

$a = "<style>"

$a = $a + "TABLE{border-width: 1px;border-style: solid;border-color: black;border-collapse: collapse;}"

$a = $a + "TH{border-width: 1px;padding: 3px;border-style: solid;border-color: black;}"

$a = $a + "TD{border-width: 1px;padding: 3px;border-style: solid;border-color: black;}"

$a = $a + "</style>"

 

do {write-host "Request approval to copy group memberships"; $repyn = read-host "from an existing user? (y/n)          "}

while ($repyn.ToLower() -ne "y" -and $repyn.ToLower() -ne "n")

 

if ($repyn.ToLower() -eq "y") {

    while ([bool]$ruchk -eq $False) {

 

        $replu = Read-Host "Enter an existing username to copy    "

        $ruchk = get-aduser -filter {samaccountname -eq $replu}

    }

 

    $rpgps = Get-ADUser $replu -Properties MemberOf | Select-Object -ExpandProperty MemberOf | Get-ADGroup -Properties Description,ManagedBy | Sort-Object SamAccountName

 

    $rpgps | Select-Object @{e={$_.Name};l="$replu's Groups"},@{e={(get-aduser $_.ManagedBy | Select-Object -ExpandProperty Name)};l="Group Owner"},Description | Sort-Object "$replu's groups" | Out-String | Write-Host

 

    write-host "$replu's group membershpis are listed above"

 

    do {$copyallyn = read-host "Copy all groups or some (all/some)    "}

    while ($copyallyn.ToLower() -ne "all" -and $copyallyn.ToLower() -ne "some")

 

    $finalgroups = @()

 

    if ($copyallyn.ToLower() -eq "some") {

        ForEach ($rpgp in $rpgps) {

            $rpgpname = $rpgp | Select-Object -ExpandProperty SamAccountName

            do {$repgroupyn = read-host "Add $uname to $rpgpname (y/n)         "}

            while ($repgroupyn.ToLower() -ne "y" -and $repgroupyn.ToLower() -ne "n")

            if ($repgroupyn.ToLower() -eq "y") {

                $finalgroups += $rpgp

            }

            $repgroupyn = "z"

        }

    }

    else {

        $finalgroups = $rpgps

    }

 

    $finalnoapprovalgroups = $finalgroups | Where-Object {$_.Description -like "no approval needed*"}

 

    foreach ($finalnoapprovalgroup in $finalnoapprovalgroups) {

        Add-ADGroupMember -Identity ($finalnoapprovalgroup | Select-Object -ExpandProperty Samaccountname) -Members $uname

    }

 

    $finalgroups = $finalgroups | Where-Object {$_.samaccountname -notin ($finalnoapprovalgroups | Select-Object -ExpandProperty samaccountname)}

 

    $owners = $finalgroups | Select-Object -ExpandProperty ManagedBy -Unique

    #[string[]]$Cc = "$techemail", "$mgremail"

    [string[]]$Cc = "$techemail"

 

    ForEach ($owner in $owners) {

 

        $ownername = Get-ADUser $owner | Select-Object -ExpandProperty Name

        $owneremail = Get-ADUser $owner -Properties mail| Select-Object -ExpandProperty mail

 

        #if statement added 5/23/2023 checks if owner is Joseph and instead directs to compliance team for approval THIS IS NOT NEEDED CAN BE DELETED

        if($owneremail -eq notneededemailaddress){

            $owneremail = notneededemailaddress

            $ownername = "Compliance"

            }

        #if statement added 7/13/2023 checks if owner is Kevin and instead directs to compliance team for approval

         elseif($owneremail -eq notneededemailaddress){

            $owneremail = notneededemailaddress

            $ownername = "Compliance"

            }

              # EDIT THE SUPPORT EMAIL ADDRESS BELOW

        $ownerGroups_html = $finalgroups | Where-Object {$_.ManagedBy -eq $owner} | Select-Object @{e={$_.SamAccountName};l="Group Name"},Description | ConvertTo-Html -Fragment | Out-String

        $body = ConvertTo-Html -Head $a -PreContent "<p><b>$ownername`</b>: $fname $lname is a new $title hire joining the $edept team reporting to $mgrname, who has requested that they be added to the user groups listed below, which you own.  <b>Please reply all and let us know if you approve adding $fname $lname to these groups</b>.  Thank you.</p>" -PostContent $ownerGroups_html | Out-String

        Send-MailMessage -From supportemailaddresscom -To $owneremail -Cc $cc -Subject "Group Membership Approval for $fname $lname ($edept New $title Hire) Required From $ownername" -BodyAsHtml -Body $body -SmtpServer mailrelay

    }

}

 

# Temporary during VDA 2023 migration - 4/28/23 - do not remove until VDA on VDI templates are updated.

# Removal of this should coincide with the VDA lines lower in this script

# Add-ADGroupMember gr_citrix_vda_1912 $uname

 

# START VDI CREATION PROCESS

 

do {$vdiyn = read-host "Create a persistent VDI? (y/n)        "}

while ($vdiyn.ToLower() -ne "y" -and $vdiyn.ToLower() -ne "n")

 

if ($vdiyn.ToLower() -eq "y"){

    $GuestUsername = whoami

    $GuestPassword = Read-Host -Prompt "Enter the password for your $GuestUsername account" -AsSecureString

    Add-ADGroupMember -Identity gr_vdi_my_virtual_desktop -Members $uname

 

    do {$gpuyn = read-host "Add Nvidia vGPU to this VDI? (y/n)    "}

    while ($gpuyn.ToLower() -ne "y" -and $gpuyn.ToLower() -ne "n")

 

    do {$vdidc = read-host "Create VDI in NY5 or LD6?             "}

    while ($vdidc.ToLower() -ne "ny5" -and $vdidc.ToLower() -ne "ld6")

 

    Write-Host ""

    Write-Host ">>>  A VDI will be created for $fname $lname."

    Write-Host ">>>  Use RDP to connect to vGPU VDI."

    Write-Host ">>>  This will take 5 - 10 minutes."

    Write-Host ">>>  This script will email you when complete."   

    Write-Host ">>>  No further input is required."

    Write-Host ""

 

    if ($vdidc.ToLower() -eq "ny5" -and $gpuyn.ToLower() -eq "n") {$vCenter = "COMPANYPRDNYVC02"; $CtxHypConn = "NY vCenter 02"; $VdiCatalog = "NY"; $VdiTemplate = "W10_22H2_N_Ent_Template"; $cluster = "NY5-VDI"}   

    elseif ($vdidc.ToLower() -eq "ld6" -and $gpuyn.ToLower() -eq "n") {$vcenter = "COMPANYPRDLDVC02"; $CtxHypConn = "LD vCenter 02"; $VdiCatalog = "LD"; $VdiTemplate = "W10_22H2_N_Ent_Template"; $cluster = "LD6-VDI"}

    elseif ($vdidc.ToLower() -eq "ny5" -and $gpuyn.ToLower() -eq "y") {$vcenter = "COMPANYPRDNYVC02"; $CtxHypConn = "NY vCenter 02"; $VdiCatalog = "NY"; $VdiTemplate = "W10_22H2_N_Ent_vGPU_Template"; $cluster = "NY5-VDI-GPU"}

    elseif ($vdidc.ToLower() -eq "ld6" -and $gpuyn.ToLower() -eq "y") {$vcenter = "COMPANYPRDLDVC02"; $CtxHypConn = "LD vCenter 02"; $VdiCatalog = "LD"; $VdiTemplate = "W10_22H2_N_Ent_vGPU_Template"; $cluster = "LD6-VDI-GPU"}

    $null = Connect-VIServer -Server $vCenter -warningaction silentlycontinue

 

    # Find lazy host and empty datastore for the new VDI

    $lazyhost = Get-Cluster $cluster -Server $vCenter | Get-VMHost | Where-Object {$_.ConnectionState -eq "Connected"} | Sort-Object CpuUsageMhz | Select-Object -First 1 -ExpandProperty Name

    $emptystore = Get-VMHost $lazyhost | Get-Datastore *VDI-PERSIST* | Where-Object {$_.State -eq "Available" -and $_.FileSystemVersion -gt 6} | Sort-Object FreeSpaceGB -Descending | Select-Object -First 1 -ExpandProperty Name

 

    # Clone the VDI from template, apply OS customization spec and power on

    $null = New-VM -Name "$uname-vdi1" -VMHost $lazyhost -Template $VdiTemplate -Datastore $emptystore -Location "VDI - Persistent"

    Write-Host ">>>  VDI cloned from template."

    $null = Set-VM "$uname-vdi1" -OSCustomizationSpec "COMPANY NY Windows 10" -Confirm:$false

    Write-Host ">>>  OS Customization Spec applied to VDI."

    $null = start-vm "$uname-vdi1"

    Write-Host ">>>  VDI Starting up now."

 

    # Allow time for the OS customization script to complete and then move the computer account to the right OU

    Write-Host ">>>  Joining VDI to the domain."

    Start-Sleep -Seconds 420

    Write-Host ">>>  Moving AD computer account"

    if ($gpuyn.ToLower() -eq "y") {Get-ADComputer "$uname-vdi1" | Move-ADObject -TargetPath "OU=Acceleration Enable,OU=$vdidc,OU=Persistent VDI,OU=Workstations,DC=COMPANY,DC=corp,DC=COMPANY,DC=com"}

    else {Get-ADComputer "$uname-vdi1" | Move-ADObject -TargetPath "OU=$vdidc,OU=Persistent VDI,OU=Workstations,DC=COMPANY,DC=corp,DC=COMPANY,DC=com"}   

    if ($vdidc.ToLower() -eq "ny5") {Set-ADComputer -Identity "$uname-vdi1" -Location "nyc"} else {Set-ADComputer -Identity "$uname-vdi1" -Location "1mp"}

 

    # Restart the VDI twice to allow time for GPOs to take effect

    Write-Host ">>>  Rebooting VDI."

    Start-Sleep -Seconds 180

    $null = Restart-VMGuest "$uname-vdi1" -Confirm:$false

    Write-Host ">>>  Second reboot for group policies to apply."

    Start-Sleep -Seconds 180

    $null = Restart-VMGuest "$uname-vdi1" -Confirm:$false

 

    # Add the new VDI to the "My Virtual Desktop" machine catalog and delivery group in Citrix

    $VdiName = "COMPANY\" + $uname + "-vdi1"

    $HostedMachineId = Get-VM "$uname-vdi1" | ForEach-Object{(Get-View $_.Id).config.uuid}

    #$CatalogID = Get-BrokerCatalog "My Virtual Desktop - $VdiCatalog" | Select-Object -ExpandProperty Uid

    #Above line is used before the vdi image update 5/31/23

    #Switch to following after the VDA is updated on VDI Images

    $CatalogID = Get-BrokerCatalog "COMPANY Virtual Desktop" | Select-Object -ExpandProperty Uid

    $HyperID = Get-BrokerHypervisorConnection $CtxHypConn | Select-Object -ExpandProperty Uid

    Write-Host ">>>  Adding VDI to Citrix desktop group and machine catalog."

    $null = New-BrokerMachine -MachineName $VdiName -catalogUid $CatalogID -HypervisorConnectionUid $HyperID -HostedMachineId $HostedMachineId

    $null = Add-BrokerMachine -MachineName $VdiName -DesktopGroup "COMPANY Virtual Desktop" #New VDA 5/31/23

    Set-BrokerPrivateDesktop -MachineName $VdiName -PublishedName $uname-vdi1 #New VDA 5/31/23

    $null = Add-BrokerUser -Name "COMPANY\$uname" -Machine $VdiName

 

   

    # Add the computer account to the gr_app_sccm_zoom_machines group to have Zoom installed via SCCM

    Add-ADGroupMember -Identity gr_app_sccm_zoom_machines -Members "$uname-vdi1$"

 

    # Add the user to the local Direct Access Users group on the new VDI

    Write-Host ">>>  Adding user to local Direct Access Users group."

    Start-Sleep -Seconds 60

    Get-Service winrm -ComputerName "$uname-vdi1" | Start-Service

    Start-Sleep -Seconds 7

    Invoke-Command -ComputerName "$uname-vdi1" -ArgumentList $uname {Add-LocalGroupMember -Group "Direct Access Users" -Member $args[0]}

    Invoke-VMScript -VM "$uname-vdi1" {Add-LocalGroupMember -Group "Direct Access Users" -Member gr_vsphere_admin} -GuestUser $GuestUsername -GuestPassword $GuestPassword

 

    # Email the person running the script to let them know the desktop is ready    EDIT THE SCRIPT EMAIL ADDRESS

    Send-MailMessage -SmtpServer mailrelay -From scrpitemailaddresscom -To "$techemail" -Subject "VDI Creation Process Complete for $uname-vdi1" -Body "You should be able to connect into the new virtual desktop now.  Note that if this is a vGPU enabled desktop you'll need to use RDP to connect, and private VLANs may prevent you from connecting from the same subnet."   

}

Write-Host ">>>  Script complete - exiting in 10 seconds."

Start-Sleep 10