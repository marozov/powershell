# Импортируем модуль NetApp PowerShell SDK
Import-Module DataONTAP
# Установите имя вашей шары
$shareName = "Baza" 
# Устанавливаем учетные данные для доступа к контроллерам
$Username = "XXXXXXX"
$Password = "XXXXXXX"
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

        # Получаем список шар из qtreeList
        $qtreeList = Get-NcQtree
        #
        $qtree = $qtreeList | Where-Object { $_.Qtree -eq $shareName } -ErrorAction Stop
        #
        $qtreeUsed = Get-NcQuotaReport -QuotaType tree -Qtree $qtree.Qtree | Select-Object DiskUsed
        #
        $qtreeSize = Get-NcQuotaReport -QuotaType tree -Qtree $qtree.Qtree | Select-Object DiskLimit
        #
        $volumeqtree = $qtree.Volume
        #
        $volumeName = Get-NcVol | Where-Object { $_.Name -eq $volumeqtree }
        $qtreeName = $qtree.Qtree
        #

        # Проверяем, есть ли шары
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
            Write-Output "________________________________"
            Write-Output "Ресурс: $qtreeName "
            #
            if ($qtreeSize.DiskLimit -eq "-") {
    Write-Output "Размер ресурса: $qtreeSizeInGb "
} else {
    Write-Output "Размер ресурса: $qtreeSizeInGb GiB"
}
            #Write-Output "Размер ресурса: $qtreeSizeInGb "
            Write-Output "Использовано на ресурсе: $qtreeUsedInGb GiB $diskAvailablePercent %"
            #Write-Output "Использовано на ресурсе: $diskAvailablePercent %"
            #Write-Output "Volume Name: $($volumeName)"
            Write-Output "Размер тома: $($volumeSpace) GiB"
            #Write-Output "Volume Used: $($volumeName.Used) %"
            Write-Output "Доступно на томе: $($volumeAvailable) GiB"
            Write-Output "________________________________"
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
