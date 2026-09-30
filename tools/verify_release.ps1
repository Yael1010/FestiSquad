$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot

Write-Host '1/4 Verificando secretos rastreados...'
& (Join-Path $PSScriptRoot 'check_secrets.ps1')

Write-Host '2/4 Ejecutando pruebas backend...'
Push-Location (Join-Path $root 'backend')
try {
    $python = $null
    $pythonCandidates = @(
        '.\.venv\Scripts\python.exe',
        '.\.venv-phase13\Scripts\python.exe'
    )
    foreach ($candidate in $pythonCandidates) {
        if (-not (Test-Path -LiteralPath $candidate)) { continue }
        & $candidate --version *> $null
        if ($LASTEXITCODE -eq 0) {
            $python = $candidate
            break
        }
    }
    if (-not $python) {
        throw 'No se encontró un entorno virtual. Crea backend/.venv e instala requirements.txt.'
    }
    & $python -m pytest -q
} finally {
    Pop-Location
}

Write-Host '3/4 Analizando Flutter...'
Push-Location (Join-Path $root 'mobile')
try {
    flutter analyze

    Write-Host '4/4 Ejecutando pruebas Flutter...'
    flutter test
} finally {
    Pop-Location
}

Write-Host 'FestiSquad está listo para generar un build candidato.' -ForegroundColor Green
