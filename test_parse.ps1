
$path = "j:\replica_lab\temp_unzip_apac\5.documents_APAC0.edt"
$content = Get-Content -Raw -Path $path
try {
    $json = $content | ConvertFrom-Json -Depth 100
    Write-Host "SUCCESS: Parsed $($path). Type: $($json.type)"
}
catch {
    Write-Host "FAILURE: Could not parse $($path): $($_.Exception.Message)"
}
