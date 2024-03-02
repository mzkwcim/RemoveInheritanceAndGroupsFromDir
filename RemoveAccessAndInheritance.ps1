$dirToRemoveAccess = Read-Host "Wprowadź ścieżkę"
$subDirectories = (Get-ChildItem -Path $dirToRemoveAccess).FullName
$groupList = @()
foreach ($subDirectory in $subDirectories)
{
    $acl = Get-acl -Path $subDirectory
    $groups = $acl.Access | Where-Object { $_.IdentityReference -is [System.Security.Principal.NTAccount] } | Select-Object -ExpandProperty IdentityReference
    $groupList += $groups
}
$groupList += (Get-Acl $dirToRemoveAccess).access | Select-Object -ExpandProperty IdentityReference | Where-Object { $_.Value -like "*S-*"} | Select-Object -ExpandProperty Value
$uniqueGroups = $groupList | ForEach-Object { $_.ToString().ToLower() } | Select-Object -Unique
foreach($group in $uniqueGroups )
{
    Write-Host $group
}
$groupsToRemoveAccess = Read-Host "Wprowadź nazwę grupy lub SID (jeżeli wprowadzasz wiele grup oddziel je pojedynczymi spacjami)"
$validInput = $false
while (-not $validInput) {
    $inheritance = Read-Host "Czy chcesz wyłączyć dziedziczenie dziedziczenie (tak/nie)"
    if ($inheritance -eq "tak" -or $inheritance -eq "nie") {
        $validInput = $true
    } else {
        Write-Host "Wprowadź poprawną wartość (tak/nie)."
    }
}
if ($groupsToRemoveAccess.Contains(' '))
{
    $groupsToRemoveAccessTable = $groupsToRemoveAccess -split ' '
}
else
{
    $groupsToRemoveAccessTable = $groupsToRemoveAccess
}
foreach($name in (Get-ChildItem $dirToRemoveAccess).FullName) 
{
    if (Test-Path -Path $name -PathType Container)
    {
        foreach ($group in $groupsToRemoveAccessTable)
        {
            if ($inheritance -eq "tak")
            {
                icacls $name /inheritance:d
            }
            $acl = Get-Acl $name
            $acl.Access | Where-Object { $_.IdentityReference.Value -eq $group -or $_.IdentityReference.Value -eq $group.ToString().ToLower()} | ForEach-Object {$acl.RemoveAccessRule($_)}
            Set-Acl -Path $name -AclObject $acl
        }
    }
}
Start-Sleep -Seconds 15

