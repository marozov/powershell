#список УЗ которым продлеваем срок действия
$users = Get-Content -Path "C:\Users\______\Desktop\users.txt"
#30 дней
$expirationDate = (Get-Date).AddDays(30)

foreach ($user in $users) {
    Set-ADUser -Identity $user -AccountExpirationDate $expirationDate }
