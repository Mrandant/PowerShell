                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        ﻿<#
.SYNOPSIS
Pull the OU locations for all AD Objects (Users or Computers)
.DESCRIPTION
Pull the OU locations for all AD Objects (Users or Computers)
.EXAMPLE
Get-OULocation -Domain contoso.com -Computer
OU=Staging,DC=contoso,DC=com
OU=Domain Controllers,DC=contoso,DC=com
OU=Computers,OU=Administrative,DC=contoso,DC=com
OU=Computers,OU=End User,DC=contoso,DC=com
.EXAMPLE
Get-OULocation -Domain contoso.com -User
CN=Users,DC=contoso,DC=com
OU=Restricted,OU=Accounts,OU=Administrative,DC=contoso,DC=com
OU=Server,OU=Accounts,OU=Administrative,DC=contoso,DC=com
OU=Accounts,OU=End User,DC=surface,DC=contoso,DC=com
OU=Non-Interactive,OU=Accounts,OU=Administrative,DC=contoso,DC=com
OU=Shared,OU=Accounts,OU=Administrative,DC=contoso,DC=com
#>
[CmdletBinding()]
[Alias()]
[OutputType([int])]
Param
(
    # Domain to Query
    [String]
    $Domain = $env:USERDOMAIN,

    # Query for all User OUs
    [Switch]
    [Parameter(ParameterSetName='User')]
    $User,

    # Query for all Computer OUs
    [Switch]
    [Parameter(ParameterSetName='Computer')]
    $Computer,

    # Query for only Server OS
    [Switch]
    [Parameter(ParameterSetName='Computer')]
    $ServerOS,

    # Query for only Client OS
    [Switch]
    [Parameter(ParameterSetName='Computer')]
    $ClientOS,

    # Query for any Windows OS
    [Switch]
    [Parameter(ParameterSetName='Computer')]
    $AllOS,

    # Query for only Server OS, excluding Domain Controllers
    [Switch]
    [Parameter(ParameterSetName='Computer')]
    $ExcludeDCs
)

Begin {
    If ((Get-Module -Name ActiveDirectory -Verbose:$False) -eq $false){
 	    Throw 'ActiveDirectory module is not available.'
    } # End If

    If (-NOT(($User) -or ($Computer))) {
        Write-Error 'Select Either User or Computer' -ErrorAction Stop
    }
}
Process {
    # Pull All Users from AD (this is going to be slow, but works)
    If ($User) {
        $ADObject = Get-ADUser -Server $Domain -Filter {(Enabled -eq $True)} -Properties DistinguishedName
    } Elseif ($Computer) {
        If ($ServerOS) {
            $ADObject = Get-ADComputer -Server $Domain -Filter {(Enabled -eq $True) -and (OperatingSystem -like '*Server*')} -Properties DistinguishedName
        } ElseIf ($ClientOS) {
            $ADObject = Get-ADComputer -Server $Domain -Filter {(Enabled -eq $True) -and (OperatingSystem -notlike '*Server*')} -Properties DistinguishedName
        } ElseIf ($ExcludeDCs) {
            $ADObject = Get-ADComputer -Server $Domain -Filter {(Enabled -eq $True) -and (OperatingSystem -like '*Server*')} -Properties DistinguishedName | Where {$_.DistinguishedName -notlike '*Domain Controllers*'}
        } Else {
            $ADObject = Get-ADComputer -Server $Domain -Filter {(Enabled -eq $True)} -Properties DistinguishedName
        }
    }

    # Create Empty Array
    $OUName = @()

    # Loop through each user and get just the DN
    foreach ($Object in $ADObject) {
        $DN = $Object.distinguishedname
        $TempOU = $DN -creplace "^[^,]*,",""
        If (($TempOU.StartsWith('OU=')) -or ($TempOU.StartsWith('CN='))) {
            $OUName += $TempOU
        } Else {
            $i = 0
            do {
                $TempOU = $TempOU -creplace "^[^,]*,",""
                $i++
            }
            until (($TempOU.StartsWith('OU=')) -or ($TempOU.StartsWith('CN=')) -or ($i -gt 10))
            $OUName += $TempOU -creplace "^[^,]*,",""
        }
    } # End Foreach

    # Create Variable with just the unique values
    $DistinguishedName = $OUName | Select -Unique
} # End Process
End {
    $DistinguishedName
} # End End
