# Импортируем модуль NetApp PowerShell SDK
Import-Module DataONTAP
# Установите имя вашей шары
$shareName = "share_name" 
# Устанавливаем учетные данные для доступа к контроллерам
$Username = "user_admin"
$Password = "pas_xxxxx"
$Credential = New-Object System.Management.Automation.PSCredential($Username, (ConvertTo-SecureString $Password -AsPlainText -Force))

# IP-адреса контроллеров
$Controller1 = "10.x.x.x"
$Controller2 = "10.x.x.x"

# Функция для поиска шары на контроллере
function Find-VolumeOnController {
    param (
        [string]$Controller,
        [PSCredential]$Credential
    )

    try {
        # Подключаемся к контроллеру
        Connect-NcController -Name $Controller -Credential $Credential -ErrorAction Stop

        # Получаем список 
        $qtreeList = Get-NcQtree
        $qtree = $qtreeList | Where-Object { $_.Qtree -eq $shareName } -ErrorAction Stop
         #$qtree.NcController
        $qtreeUsed = Get-NcQuotaReport -QuotaType tree -Qtree $qtree.Qtree | Select-Object DiskUsed
        $qtreeSize = Get-NcQuotaReport -QuotaType tree -Qtree $qtree.Qtree | Select-Object DiskLimit
        $volumeqtree = $qtree.Volume
        $volumeName = Get-NcVol | Where-Object { $_.Name -eq $volumeqtree }

        # Проверяем, есть ли шары и форматируем вывод
        if ($qtree) {
            Write-Output "Шары найдены на контроллере $Controller :"
            $volumeSpace = ($volumeName.TotalSize / 1024MB).ToString("F0")
            $volumeAvailable = ($volumeName.Available / 1024MB).ToString("F0")
            $qtreeUsedInGb = ($qtreeUsed.DiskUsed / 1MB).ToString("F0")
            #
            if ($qtreeSize.DiskLimit -eq "-") {
            $qtreeSizeInGb = "NoHardLimit"
            $diskAvailablePercent = "-"
            } else {
            #
            $qtreeSizeInGb = ($qtreeSize.DiskLimit / 1MB)
            $diskAvailablePercent = if ($qtreeSizeInGb -eq 0) { 0 } else { (($qtreeUsedInGb / $qtreeSizeInGb) * 100).ToString("F0")
            }
            }
            Write-Output "_______________________"
            Write-Output "Ресурс: $shareName "
            #
            if ($qtreeSize.DiskLimit -eq "-") {
    Write-Output "Размер ресурса: $qtreeSizeInGb "
} else {
    Write-Output "Размер ресурса: $qtreeSizeInGb GiB"
}
            #
            Write-Output "Использовано на ресурсе: $qtreeUsedInGb GiB"
            Write-Output "Использовано на ресурсе: $diskAvailablePercent %"
            #Write-Output "Volume Name: $($volumeName)"
            Write-Output "Размер тома: $($volumeSpace) GiB"
            #Write-Output "Volume Used: $($volumeName.Used) %"
            Write-Output "Доступно на томе: $($volumeAvailable) GiB"
            Write-Output "_______________________"
        } else {
            Write-Output "Шары не найдены на контроллере $Controller ."
        }
    } catch {
        Write-Output "Ошибка при подключении к контроллеру $Controller ."
    } finally {
        # Отключаемся от контроллера
        #Disconnect-NcController -Name $Controller -ErrorAction SilentlyContinue
    }
}

# Поиск шары на первом контроллере
Find-VolumeOnController -Controller $Controller1 -Credential $Credential

# Если шары не найдены на первом контроллере, поиск на втором
if (!$volumes) {
    Find-VolumeOnController -Controller $Controller2 -Credential $Credential
}
