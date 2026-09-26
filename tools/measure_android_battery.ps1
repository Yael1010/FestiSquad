param(
    [string]$Package = "com.example.festisquad",
    [string]$Output = ".\battery-phase7.txt"
)

$ErrorActionPreference = "Stop"
if (-not (Get-Command adb -ErrorAction SilentlyContinue)) {
    throw "adb no está disponible. Instala Android Platform Tools y agrégalo al PATH."
}

Write-Host "Reiniciando estadísticas para $Package..."
adb shell dumpsys batterystats --reset | Out-Null
Write-Host "Usa FestiSquad durante 60 minutos con mapa y segundo plano activos."
Read-Host "Presiona Enter al terminar la sesión"

$report = adb shell dumpsys batterystats $Package
$report | Set-Content -Path $Output -Encoding utf8
Write-Host "Evidencia guardada en $Output"
Write-Host "Registra batería inicial/final. El criterio de aceptación es consumo <= 10 puntos porcentuales en una hora."
