$ErrorActionPreference = 'Continue'

$vswhere = "${env:ProgramFiles(x86)}\Microsoft Visual Studio\Installer\vswhere.exe"
$vs = & $vswhere -latest -products * -property installationPath
Write-Host "VS: $vs"
$vcvars = Join-Path $vs 'VC\Auxiliary\Build\vcvars64.bat'
foreach ($line in (cmd /c "`"$vcvars`" >nul && set")) {
	$eq = $line.IndexOf('=')
	if ($eq -gt 0) {
		Set-Item -Path ("env:" + $line.Substring(0, $eq)) -Value $line.Substring($eq + 1)
	}
}

$M = '_MSVC_STL_DESTRUCTOR_TOMBSTONES'
$cases = [ordered]@{
	'none'        = @()
	'D1'          = @("/D$M=1")
	'D1 D1'       = @("/D$M=1", "/D$M=1")
	'D1 D0'       = @("/D$M=1", "/D$M=0")
	'D0 D1'       = @("/D$M=0", "/D$M=1")
	'D1 U D0'     = @("/D$M=1", "/U$M", "/D$M=0")
	'D1 U'        = @("/D$M=1", "/U$M")
	'U D1'        = @("/U$M", "/D$M=1")
	'U'           = @("/U$M")
}

function Run-Case($compiler, $name, $flags, $extra) {
	$exe = "t_$([guid]::NewGuid().ToString('N')).exe"
	$out = & $compiler /nologo /EHsc /W4 /std:c++20 @extra @flags t.cpp "/Fe$exe" 2>&1 | Out-String
	$code = $LASTEXITCODE
	$run = ''
	if (Test-Path $exe) { $run = (& ".\$exe" | Out-String).Trim() }
	Write-Host "=== [$compiler $($extra -join ' ')] $name :: $($flags -join ' ')"
	Write-Host "exit=$code"
	Write-Host ("diagnostics: " + (($out -split "`n" | Where-Object { $_ -like '*warning*' -or $_ -like '*error*' }) -join ' | '))
	Write-Host "result: $run"
}

& cl 2>&1 | Select-Object -First 1 | Write-Host

foreach ($name in $cases.Keys) { Run-Case 'cl' $name $cases[$name] @() }
foreach ($name in $cases.Keys) { Run-Case 'cl' $name $cases[$name] @('/WX') }

if (Get-Command clang-cl -ErrorAction SilentlyContinue) {
	& clang-cl --version | Select-Object -First 1 | Write-Host
	foreach ($name in $cases.Keys) { Run-Case 'clang-cl' $name $cases[$name] @() }
}

exit 0
