# Remove all existing Powershell sessions 
Get-PSSession | Remove-PSSession 

# Authenticate to Office 365
$Credentials = Get-AutomationPSCredential -Name "Office 365"
Connect-MsolService -Credential $Credentials

# Set Authentication Requirement parameter
$MFA = New-Object -TypeName Microsoft.Online.Administration.StrongAuthenticationRequirement
$MFA.RelyingParty = "*"

# Choose the MFA State
$MFA.State = "Enforced"

# Get todays date and set it as a parameter for not issue before date 
$MFA.RememberDevicesNotIssuedBefore = (Get-Date)

#Set MFA for all Global Admins
$Global_Admins = Get-MsolRole -RoleName "Company Administrator"
Get-MsolRoleMember -RoleObjectId $Global_Admins.ObjectId | ForEach-Object {
    Set-MsolUser -UserPrincipalName $_.EmailAddress -StrongAuthenticationRequirements $MFA
    }