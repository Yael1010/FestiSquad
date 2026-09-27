$ErrorActionPreference = "Stop"

$candidateFiles = git ls-files --cached --others --exclude-standard
$sensitiveNames = $candidateFiles | Select-String -Pattern (
    '(^|/)(\.env($|\.)|client_secret.*\.json$|service-account.*\.json$|' +
    'google-services\.json$|GoogleService-Info\.plist$|.*\.(pem|key|p12|pfx|jks|keystore)$)'
)
$allowedExamples = $sensitiveNames | Where-Object {
    $_.Line -notmatch '\.env(\.[^/]+)?\.example$'
}

$secretPatterns = @(
    'BEGIN (RSA |EC |OPENSSH )?PRIVATE KEY',
    'AIza[0-9A-Za-z_-]{30,}',
    'gh[pousr]_[0-9A-Za-z]{20,}',
    'sk_(live|test)_[0-9A-Za-z]+'
)
$patternHits = foreach ($pattern in $secretPatterns) {
    git grep --untracked -n -I -E $pattern -- . ':(exclude)tools/check_secrets.ps1' 2>$null
}

$credentialAssignments = git grep --untracked -n -I -E `
    '^(JWT_SECRET|SPOTIFY_CLIENT_SECRET|GOOGLE_CLIENT_SECRET|DATABASE_URL)=.+' `
    -- . ':(exclude)tools/check_secrets.ps1' 2>$null |
    Where-Object {
        $_ -notmatch '\.example:' -and
        $_ -notmatch '=\s*(\.\.\.|changeme|change-me|your_|<)'
    }

if ($allowedExamples -or $patternHits -or $credentialAssignments) {
    Write-Error (
        "Se detectaron posibles secretos en archivos candidatos al commit.`n" +
        "$allowedExamples`n$patternHits`n$credentialAssignments"
    )
}

Write-Host "OK: no se detectaron secretos en archivos rastreados o candidatos al commit."
