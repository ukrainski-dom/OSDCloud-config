#=======================================================================
#   Install Windows
#=======================================================================

$Params = @{
    OSBuild = "21H2"
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


#================================================
#   WinPE PostOS
#   Set OOBEDeploy CMD
#================================================
$SetCommand = @'
@echo off
PowerShell -NoL -Com Set-ExecutionPolicy RemoteSigned -Force
set path=%path%;C:\Program Files\WindowsPowerShell\Scripts
start PowerShell -NoL -W Mi
start "Start-OOBEDeploy" PowerShell -NoL -C Start-OOBEDeploy
exit
'@
$SetCommand | Out-File -FilePath "C:\Windows\OOBEDeploy.cmd" -Encoding ascii -Width 2000 -Force

Restart-Computer
