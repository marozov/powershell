# Запрос названия группы от пользователя
$groupName = Read-Host "Введите название группы"
 
# Запрос описания группы от пользователя
$groupDescription = Read-Host "Введите описание группы"
 
# Преобразование названия группы в верхний регистр
$groupName = $groupName.ToUpper()
 
# Задайте OU здесь
$ou = "OU=Groups,DC=domain,DC=ru"
 
# Создание групп
Write-Host;
New-ADGroup -Name "NUR_RSP_FS_$($groupName)_RO" -DisplayName "NUR_RSP_FS_$($groupName)_RO" -Description "$groupDescription" -GroupScope Global -Path $ou
New-ADGroup -Name "NUR_RSP_FS_$($groupName)_RW" -DisplayName "NUR_RSP_FS_$($groupName)_RW" -Description "$groupDescription" -GroupScope Global -Path $ou
Write-Host;
Write-Host "Ресурс создан: \\shares\$groupName$"
Write-Host;
Write-Host "Группы доступа:"
"NUR_RSP_FS_$($groupName)_RO"
"NUR_RSP_FS_$($groupName)_RW"

# Define servers list
$servers = @("ip_address")
 
# Create PSCredential
$credential = New-Object System.Management.Automation.PSCredential("admin", (ConvertTo-SecureString "password" -AsPlainText -Force))
 
foreach ($server in $servers) {
   # Connect to NetApp
   $controller = Connect-NcController -Name $server -Credential $credential
   $cluster = Get-NcCluster
   $clusterName = $cluster.ClusterName
}
 
# Get the server for the current server
$vserverName = "host name"

# Получите список всех volume
$volumes = Get-NcVol
 
# Найдите volume с наибольшим объемом свободного места среди тех у кого включена дедупликация
$volumeWithMostFreeSpace = $volumes | Where-Object { $_.Dedupe -eq "True" } | Sort-Object Available | Select-Object -Last 1
 
$volumeneed = $volumeWithMostFreeSpace.Name
# Получить путь к сетевому пути
$sharePath = "/$volumeneed/$groupName"
$QutaPath = "/vol/$volumeneed/$groupName"
# Создайте новый qtree WORK
New-NcQtree -Vserver $vserverName -Volume $volumeneed -Qtree $groupName
Set-NcQuota -Vserver $vserverName -Path $QutaPath -DiskLimit 20900mb 
# Создайте новый сетевой ресурс 
Add-NcCifsShare -Vserver $vserverName -Name $groupName -Path $sharePath -Comment "$groupDescription"

# Assign the groups to the share
#
Add-NcCifsShareAcl -Vserver $vserverName -Share $groupName -UserOrGroup DOMAIN\NUR_RSP_FS_$($groupName)_RO -Permission read
Add-NcCifsShareAcl -Vserver $vserverName -Share $groupName -UserOrGroup DOMAIN\NUR_RSP_FS_$($groupName)_RW -Permission change
Add-NcCifsShareAcl -Vserver $vserverName -Share $groupName -UserOrGroup DOMAIN\NUR-FS-Admins -Permission full_control
Add-NcCifsShareAcl -Vserver $vserverName -Share $groupName -UserOrGroup DOMAIN\NUR_RSP_FS_UEB_RO -Permission read
Add-NcCifsShareAcl -Vserver $vserverName -Share $groupName -UserOrGroup DOMAIN\Nur_rsp_IB_Monitoring -Permission read
Add-NcCifsShareAcl -Vserver $vserverName -Share $groupName -UserOrGroup "DOMAIN\Domain DFS Admins" -Permission read
Remove-NcCifsShareAcl -Vserver $vserverName -Share $groupName -UserOrGroup Everyone
#Create dfs link
New-DfsnFolder -Path "\\domain\shares\$groupName" -TargetPath "\\ip_address\$groupName`$"

# Создаем объект Outlook
$Outlook = New-Object -ComObject Outlook.Application

# Создаем новое сообщение
$Mail = $Outlook.CreateItem(0)

# Задаем получателя, тему и текст сообщения 
$Mail.To = "user@test.ru"
$Mail.Subject = "Ресурс $groupName создан."

$Mail.BodyFormat = 2 
# Set body format to HTML

# Variable to track the current server

   $mail.HTMLBody += "<p>Добрый день!</p>"
   $mail.HTMLBody += "<p><b>Ресурс $groupName создан:</b> \\shares\$groupName`$</p>"
   $mail.HTMLBody += "<p><b>Группы доступа:</b></p>"
   $mail.HTMLBody += "<p>NUR_RSP_FS_$groupName_RO</p>"
   $mail.HTMLBody += "<p>NUR_RSP_FS_$groupName_RW</p>"

# Set email recipient and send
$mail.Send()
