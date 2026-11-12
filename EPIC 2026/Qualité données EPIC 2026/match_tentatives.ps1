# Recherche d'appariement des Tentatives 1 et 2
Add-Type -AssemblyName System.IO.Compression.FileSystem
$zip = [System.IO.Compression.ZipFile]::OpenRead("EPIC_Basic-rgpd ok.xlsx")
$ssEntry = $zip.GetEntry("xl/sharedStrings.xml")
$s = $ssEntry.Open()
$r = New-Object System.IO.StreamReader($s, [System.Text.Encoding]::UTF8)
$xml = [xml]$r.ReadToEnd()
$r.Close(); $s.Close()
$sharedStrings = $xml.sst.si | ForEach-Object { $_.InnerText }

$sheetEntry = $zip.GetEntry("xl/worksheets/sheet1.xml")
$s = $sheetEntry.Open()
$r = New-Object System.IO.StreamReader($s, [System.Text.Encoding]::UTF8)
$xml = [xml]$r.ReadToEnd()
$r.Close(); $s.Close()
$zip.Dispose()

$rows = $xml.worksheet.sheetData.row
$allData = @()
for ($i = 1; $i -lt $rows.Count; $i++) {
    $row = $rows[$i]
    $rowDict = [ordered]@{}
    foreach ($c in $row.c) {
        $colLetter = $c.r -replace '[0-9]', ''
        $val = if ($c.t -eq "s") { $sharedStrings[[int]$c.v] } else { $c.v }
        $rowDict[$colLetter] = $val
    }
    $allData += [PSCustomObject]@{
        Row = $i
        ID = $rowDict["A"]
        Region = $rowDict["B"]
        Tentative = $rowDict["D"]
        EPIC_courses = $rowDict["E"]
        Statut = $rowDict["F"]
        Commence = $rowDict["G"]
        Termine = $rowDict["H"]
        Duree = $rowDict["I"]
        Note = $rowDict["K"]
    }
}

Write-Host "Total records: $($allData.Count)"
$t2 = $allData | Where-Object { $_.Tentative -eq "2" }
Write-Host "Tentative 2 count: $($t2.Count)"

foreach ($item in $t2) {
    # Chercher les tentatives 1 dans la même région avec des caractéristiques proches
    Write-Host "T2: Row $($item.Row), ID $($item.ID), Reg $($item.Region), Note $($item.Note), Date $($item.Commence), Duree $($item.Duree)"
}

