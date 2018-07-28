Get-PSSession | Remove-PSSession
# Connect to Office 365
$Credentials = Get-AutomationPSCredential -Name "Office 365"
Connect-MsolService -Credential $Credentials

$AppPremission = (Get-MsolCompanyInformation).UsersPermissionToUserConsentToAppEnabled
Write-Output $AppPremission

# Changing premission if the current value is set to True
if($AppPremission -Contains "True")
    {
    Write-output "Setting User Premission to user consent to app enabled"
    Set-MsolCompanySettings –UsersPermissionToUserConsentToAppEnabled:$false
    }

# Outputing current premissions
$AppPremission = Get-MsolCompanyInformation | fl UsersPermissionToUserConsentToAppEnabled
Write-Output $AppPremission

# Disconnecting from Office 365
Get-PSSession | Remove-PSSession