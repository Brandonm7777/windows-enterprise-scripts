"select disk 0`r`nrescan`r`nlist partition" | Out-File C:\Windows\Temp\diskpart1.txt -Encoding utf8 -Force

if ((& diskpart /s C:\Windows\Temp\diskpart1.txt | Where-Object { $_ -like "*Recovery*" }) -match 'Partition (\d)') {

    $recovery = $matches[1].ToString()

    "select disk 0`r`nselect partition $recovery`r`ndelete partition override" | Out-File C:\Windows\Temp\diskpart2.txt -Encoding utf8 -Force

    & diskpart /s C:\Windows\Temp\diskpart2.txt
}

"select volume c`r`nextend" | Out-File C:\Windows\Temp\diskpart3.txt -Encoding utf8 -Force

& diskpart /s C:\Windows\Temp\diskpart3.txt