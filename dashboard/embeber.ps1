# embeber.ps1 - Copia dashboard\dashboard.html dentro de DASHWEB.PRG (funcion
# HtmlEmbebido, entre las marcas //<<HTML y //HTML>>), asi el HTML viaja dentro
# de BCN.exe y se escribe solo en cada PC.
#
# Uso (desde FUENTES2):  powershell -ExecutionPolicy Bypass -File dashboard\embeber.ps1
# Despues: recompilar DASHWEB.PRG y linkear.
#
# Antes de embeber, si cambiaste el HTML, subi el numero de "dashweb-version"
# (AAAAMMDDnn) para que las PCs que ya tienen la pagina la reemplacen.

$ErrorActionPreference = 'Stop'
$dir  = Split-Path -Parent $MyInvocation.MyCommand.Path
$html = Join-Path $dir 'dashboard.html'
$prg  = Join-Path (Split-Path -Parent $dir) 'DASHWEB.PRG'
$lat1 = [Text.Encoding]::GetEncoding(28591)

$h = [IO.File]::ReadAllText($html, [Text.Encoding]::UTF8)
foreach ($ch in $h.ToCharArray()) {
   if ([int]$ch -gt 127) { throw "dashboard.html tiene caracteres no ASCII: usar entidades HTML o \uXXXX en el JavaScript" }
}
$lineas = $h -split "`r?`n"
foreach ($l in $lineas) {
   if ($l.Trim() -match '^(ENDTEXT|#pragma)') { throw "Linea no permitida dentro de TEXT INTO: $l" }
}
if ($h -notmatch 'dashweb-version: (\d{10})') { throw 'Falta la marca dashweb-version' }
$ver = $Matches[1]

$p = [IO.File]::ReadAllText($prg, $lat1)
$ini = "//<<HTML`r`n   TEXT INTO cHtml`r`n"
$fin = "   ENDTEXT`r`n//HTML>>"
$i = $p.IndexOf($ini); $j = $p.IndexOf($fin)
if ($i -lt 0 -or $j -lt $i) { throw 'No encontre las marcas //<<HTML ... //HTML>> en DASHWEB.PRG' }

# TEXT INTO interpreta las barras invertidas como escapes (\s -> s, é -> u00e9):
# se duplican aca para que en el exe queden simples, como en el HTML.
$cuerpo = (($lineas -join "`r`n").TrimEnd("`r", "`n") + "`r`n").Replace('\', '\\')
$p = $p.Substring(0, $i + $ini.Length) + $cuerpo + $p.Substring($j)
[IO.File]::WriteAllText($prg, $p, $lat1)
"Embebido dashboard.html (version $ver, $($lineas.Count) lineas) en DASHWEB.PRG"
