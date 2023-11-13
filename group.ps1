#отобразить группы пользователя user
Get-ADUser -Identity user -Properties memberof | Select-Object -ExpandProperty memberof | ForEach-Object { (Get-ADGroup $_).Name }
