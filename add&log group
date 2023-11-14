# Получить список пользователей и групп
$users = Get-Content -Path "C:\Users\_______\Desktop\users.txt"
$groups = Get-Content -Path "C:\Users\______\Desktop\groupname.txt"

# Присвоить группы пользователям
foreach ($user in $users) {
    foreach ($group in $groups) {
        Add-ADGroupMember -Identity $group -Members $user
    }
}

# Прологировать группы пользователей
foreach ($user in $users) {
    $groups = Get-ADPrincipalGroupMembership $user | Select-Object Name 
    Write-Host Groups for user $user
    $groups | Format-Table
}
