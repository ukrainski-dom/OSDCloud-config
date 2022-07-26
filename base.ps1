#=======================================================================
#   Install Windows
#=======================================================================

$Params = @{
    OSBuild = "21H2"
    # OSEdition = "Pro"
    OSLanguage = "pl-pl"
    OSLicense = "Retail"
    SkipAutopilot = $true
    SkipODT = $true
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
                   "IsPresent":  false
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
:: Set the PowerShell Execution Policy
PowerShell -NoL -Com Set-ExecutionPolicy RemoteSigned -Force
:: Add PowerShell Scripts to the Path
set path=%path%;C:\Program Files\WindowsPowerShell\Scripts
:: Open and Minimize a PowerShell instance just in case
start PowerShell -NoL -W Mi
:: Install the latest OSD Module
start "Install-Module OSD" /wait PowerShell -NoL -C Install-Module OSD -Force -Verbose
:: Start-OOBEDeploy
:: The next line assumes that you have a configuration saved in C:\ProgramData\OSDeploy\OSDeploy.OOBEDeploy.json
start "Start-OOBEDeploy" PowerShell -NoL -C Start-OOBEDeploy
exit
'@
$SetCommand | Out-File -FilePath "C:\Windows\OOBEDeploy.cmd" -Encoding ascii -Width 2000 -Force


#=================================================
#	new UnattendXml
#=================================================
$UnattendXml = @'
<?xml version="1.0" encoding="utf-8"?>
<unattend xmlns="urn:schemas-microsoft-com:unattend">
    <settings pass="specialize">
        <component name="Microsoft-Windows-Deployment" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS" xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
            <RunSynchronous>
                <RunSynchronousCommand wcm:action="add">
                    <Order>1</Order>
                    <Description>OSDCloud Specialize</Description>
                    <Path>Powershell -ExecutionPolicy Bypass -Command Invoke-OSDSpecialize -Verbose</Path>
                </RunSynchronousCommand>
            </RunSynchronous>
        </component>
    </settings>
    <settings pass="oobeSystem">
        <component name="Microsoft-Windows-Deployment" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS" xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
            <Reseal>
                <Mode>Audit</Mode>
            </Reseal>
        </component>
    </settings>
    <settings pass="auditUser">
        <component name="Microsoft-Windows-Deployment" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS" xmlns:wcm="http://schemas.microsoft.com/WMIConfig/2002/State" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
            <RunSynchronous>
                <RunSynchronousCommand wcm:action="add">
                <Order>1</Order>
                <Description>Set ExecutionPolicy RemoteSigned</Description>
                <Path>PowerShell -WindowStyle Hidden -Command "Set-ExecutionPolicy RemoteSigned -Force"</Path>
                </RunSynchronousCommand>

                <RunSynchronousCommand wcm:action="add">
                <Order>2</Order>
                <Description>WaitWebConnection</Description>
                <Path>PowerShell -Command "Wait-WebConnection powershellgallery.com -Verbose"</Path>
                </RunSynchronousCommand>

                <RunSynchronousCommand wcm:action="add">
                <Order>3</Order>
                <Description>Start OOBEDeploy</Description>
                <Path>C:\Windows\OOBEDeploy.cmd</Path>
                </RunSynchronousCommand>
            </RunSynchronous>
        </component>
    </settings>
</unattend>
'@

#=================================================
#	Overwrite panther Unattend
#=================================================
$Panther = 'C:\Windows\Panther'
$UnattendPath = "$Panther\Invoke-OSDSpecialize.xml"

Write-Verbose -Verbose "Overwriting $UnattendPath"
$UnattendXml | Out-File -FilePath $UnattendPath -Encoding utf8 -Width 2000 -Force

Restart-Computer
