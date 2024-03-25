$path_to_pubspec = "D:\source\repos\flutter\anychat\pubspec.yaml"
(Get-Content -Path $path_to_pubspec -Raw) -match 'version: (\d+\.\d+\.\d+\+\d+)' | Out-Null
$current_version = $matches[1]
$current_version_without_build = $current_version -replace '\+.*'
$gitcount = (git log | Select-String -Pattern '^commit' | Measure-Object).Count
$new_version = "$current_version_without_build+$gitcount"
Write-Output "Setting pubspec.yaml version $current_version to $new_version"
#(Get-Content $path_to_pubspec) -replace "version: $current_version", "version: $new_version" | Set-Content $path_to_pubspec


# (Get-Content $path_to_pubspec) |
# ForEach-Object { $_ -replace $current_version, $new_version 
# Write-Output $_ $current_version $new_version } | 
# Set-Content $path_to_pubspec

# Read the content of the file
$content = Get-Content $path_to_pubspec
Set-Content $path_to_pubspec $null

# Loop through each line and replace the old value with the new value
foreach ($line in $content) {
    $line = $line -replace [Regex]::Escape($current_version), $new_version
    $line | Out-File -FilePath $path_to_pubspec -Append
}
