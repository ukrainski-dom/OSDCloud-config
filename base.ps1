#=======================================================================
#   Install Windows
#=======================================================================

$Params = @{
    OSLanguage = "pl-pl"
    OSLicense = "Retail"
    SkipAutopilot = $true
    SkipODT = $true
    # OSEdition = "Pro"
    # ZTI = $true
}

Start-OSDCloud @Params

#=======================================================================
#   AutopilotOOBE config
#=======================================================================
Write-SectionHeader "Applying OSDeploy.AutopilotOOBE.json"
Write-DarkGrayHost 'C:\ProgramData\OSDeploy\OSDeploy.AutopilotOOBE.json'

If (!(Test-Path "C:\ProgramData\OSDeploy")) {
    New-Item "C:\ProgramData\OSDeploy" -ItemType Directory -Force | Out-Null
}

$AutopilotOOBEJson = @'
{
    "Assign":  {
                   "IsPresent":  true
               },
    "Hidden":  [
                   "AddToGroup",
                   "AssignedComputerName",
                   "AssignedUser",
                   "PostAction"
               ],
    "PostAction":  "Quit",
    "Run":  "NetworkingWireless",
    "Docs":  "https://autopilotoobe.osdeploy.com/",
    "Title":  "OSDeploy Autopilot Registration"
}
'@
$AutopilotOOBEJson | Out-File -FilePath 'C:\ProgramData\OSDeploy\OSDeploy.AutopilotOOBE.json' -Encoding ascii -Width 2000 -Force

#=======================================================================
#   OOBEDeploy config
#=======================================================================

Write-SectionHeader "Applying OSDeploy.OOBEDeploy.json"
Write-DarkGrayHost 'C:\ProgramData\OSDeploy\OSDeploy.OOBEDeploy.json'

$OOBEDeployJson = @'
{
    "Autopilot":  {
                      "IsPresent":  true
                  },
    "RemoveAppx":  [
                       "CommunicationsApps",
                       "OfficeHub",
                       "People",
                       "Skype",
                       "Solitaire",
                       "Xbox",
                       "ZuneMusic",
                       "ZuneVideo"
                   ],
    "UpdateDrivers":  {
                          "IsPresent":  true
                      },
    "UpdateWindows":  {
                          "IsPresent":  true
                      }
}
'@
$OOBEDeployJson | Out-File -FilePath 'C:\ProgramData\OSDeploy\OSDeploy.OOBEDeploy.json' -Encoding ascii -Width 2000 -Force


$OOBEFixScript = @'
##########################
#trying to get the file #
########################

$Account = New-Object -TypeName System.Security.Principal.NTAccount -ArgumentList 'builtin\Administrators';

try
{
	$Itemexists = test-path 'C:\Windows\SystemApps\*\webapps\inclusiveOobe\view\oobelocalaccount-main.html'
	$ItemList = Get-Item -Path C:\Windows\SystemApps\*\webapps\inclusiveOobe\view\oobelocalaccount-main.html
}
catch
{
	write-host "an error occurred"
        exit 1
}



####################################
# change owner of the file         #
#####################################


if($Itemexists)
{ 

	$Acl = $null; 
    	$Acl = Get-Acl -Path $Itemlist.FullName; 
    	$Acl.SetOwner($Account); 
    	Set-Acl -Path $Itemlist.FullName -AclObject $Acl; 
}else{ 
	Write-Host  "File not found!"
        exit 1            
}


###########################################
#Change acl permissions                  #
###########################################


try
{
	$Acl = Get-Acl -Path $Itemlist.FullName; 
        $owner = $acl.owner
}
catch
{
	write-host "owner not found"
        exit 1
}



if ($owner -eq $account)      
{
   	$myPath = $itemlist
	$myAcl = Get-Acl "$myPath"
	$myAclEntry = "nt authority\system","FullControl","Allow"
	$myAccessRule = New-Object System.Security.AccessControl.FileSystemAccessRule($myAclEntry)
	$myAcl.SetAccessRule($myAccessRule)
	$myAcl | Set-Acl "$MyPath"
	

	$myPath = $itemlist
	$myAcl = Get-Acl "$myPath"
	$myAclEntry = $account,"FullControl","Allow"
	$myAccessRule = New-Object System.Security.AccessControl.FileSystemAccessRule($myAclEntry)
	$myAcl.SetAccessRule($myAccessRule)
	$myAcl | Set-Acl "$MyPath"
	
}else{
       Write-Host "Permissions couldnt be changed"
       exit 1
}



###############################################
#remove the option to add a local account in oobe  #
##############################################

$data = foreach($line in Get-Content $itemlist)
{
    if($line -like '*/webapps/inclusiveOobe/js/oobelocalaccount-page.js*')
    {
    }
    else
    {
        $line
    }
}
$data | Set-Content $itemlist -Force
exit 0
'@
$OOBEFixScript | Out-File -FilePath 'C:\ProgramData\OSDeploy\OOBEFixScript.ps1' -Encoding ascii -Width 2000 -Force


#================================================
#   WinPE PostOS
#   Set OOBEDeploy CMD
#================================================
$SetCommand = @'
@echo off
PowerShell -NoL -Com Set-ExecutionPolicy RemoteSigned -Force
set path=%path%;C:\Program Files\WindowsPowerShell\Scripts
start PowerShell -NoL -W Mi
start "OOBEFixScript" PowerShell -NoL -ExecutionPolicy Bypass -File C:\ProgramData\OSDeploy\OOBEFixScript.ps1
start "Start-OOBEDeploy" PowerShell -NoL -C Start-OOBEDeploy
exit
'@
$SetCommand | Out-File -FilePath "C:\Windows\OOBEDeploy.cmd" -Encoding ascii -Width 2000 -Force

Restart-Computer
