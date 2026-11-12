Add-Type -AssemblyName System.IO.Compression.FileSystem

function Convert-ColLetterToIdx([string]$colStr) {
    $col = 0
    foreach ($char in $colStr.ToCharArray()) {
        $col = ($col * 26) + ([int][char]$char - [int][char]'A' + 1)
    }
    return $col
}

function Export-XlsxToCsv {
    param(
        [string]$XlsxPath,
        [string]$CsvPath
    )

    $zip = [System.IO.Compression.ZipFile]::OpenRead($XlsxPath)
    
    # 1. Shared Strings
    $ssEntry = $zip.GetEntry("xl/sharedStrings.xml")
    $sharedStrings = New-Object System.Collections.Generic.List[string]
    if ($ssEntry) {
        $stream = $ssEntry.Open()
        [xml]$ssXml = (New-Object System.IO.StreamReader($stream, [System.Text.Encoding]::UTF8)).ReadToEnd()
        $stream.Dispose()
        foreach ($si in $ssXml.sst.si) {
            if ($si.t -ne $null) {
                $val = if ($si.t.'#text') { $si.t.'#text' } else { $si.t }
                $sharedStrings.Add([string]$val)
            } elseif ($si.r -ne $null) {
                $txt = ($si.r | ForEach-Object { if ($_.t.'#text') { $_.t.'#text' } else { $_.t } }) -join ""
                $sharedStrings.Add([string]$txt)
            } else {
                $sharedStrings.Add("")
            }
        }
    }

    # 2. Worksheet
    $sEntry = $zip.GetEntry("xl/worksheets/sheet1.xml")
    $stream = $sEntry.Open()
    [xml]$sXml = (New-Object System.IO.StreamReader($stream, [System.Text.Encoding]::UTF8)).ReadToEnd()
    $stream.Dispose()
    $zip.Dispose()

    # Determine max column
    $allRows = @()
    $maxCol = 0

    foreach ($row in $sXml.worksheet.sheetData.row) {
        $rowCells = @{}
        foreach ($c in $row.c) {
            $ref = $c.r
            $colLetters = $ref -replace '[0-9]', ''
            $colIdx = Convert-ColLetterToIdx $colLetters
            if ($colIdx -gt $maxCol) { $maxCol = $colIdx }
            
            $val = ""
            if ($c.t -eq "s") {
                $idx = [int]$c.v
                if ($idx -lt $sharedStrings.Count) {
                    $val = $sharedStrings[$idx]
                }
            } elseif ($c.v) {
                $val = [string]$c.v
            }
            $rowCells[$colIdx] = $val
        }
        $allRows += ,$rowCells
    }

    # Write to CSV with BOM and ;
    $lines = New-Object System.Collections.Generic.List[string]
    foreach ($rDict in $allRows) {
        $rowVals = for ($i = 1; $i -le $maxCol; $i++) {
            $cell = if ($rDict.ContainsKey($i)) { $rDict[$i] } else { "" }
            # Escape quotes
            $cell = $cell -replace '"', '""'
            if ($cell -match '[;,"\r\n]') {
                "`"$cell`""
            } else {
                $cell
            }
        }
        $lines.Add(($rowVals -join ";"))
    }

    $utf8WithBom = New-Object System.Text.UTF8Encoding($true)
    [System.IO.File]::WriteAllLines($CsvPath, $lines, $utf8WithBom)
    Write-Output "Exporté $XlsxPath -> $CsvPath ($($lines.Count) lignes, $maxCol colonnes)"
}

Export-XlsxToCsv -XlsxPath "BAC 3/UMONS_Pretest_2025.xlsx" -CsvPath "BAC 3/UMONS_Pretest_2025.csv"
Export-XlsxToCsv -XlsxPath "BAC 3/UMONS_posttest_2025.xlsx" -CsvPath "BAC 3/UMONS_posttest_2025.csv"
