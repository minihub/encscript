# Set strict mode to catch errors
Set-StrictMode -Version Latest

function Die {
    param (
        [string]$Message
    )
    Write-Host "ERROR: $Message" -ForegroundColor Red
    exit 1
}

# Input file
$InputFile = $args[0]

# Resolve the path to handle relative paths
$ResolvedInputFile = Resolve-Path $InputFile

# Check if the provided file exists
if (-not (Test-Path $ResolvedInputFile)) {
    Die "File not found: $ResolvedInputFile"
}

# Determine the current execution path
$ExecutionPath = Get-Location

# Define output filenames
$BaseName = [System.IO.Path]::GetFileName($ResolvedInputFile)  # Full filename with extension
$ZipFile = Join-Path -Path $ExecutionPath -ChildPath ("$BaseName.zip")
$GenScript = Join-Path -Path $ExecutionPath -ChildPath "genscript.ps1"

# Compress the input file using 7-Zip and suppress output
Write-Host "Compressing the input file..."
& "C:\Program Files\7-Zip\7z.exe" a "$ZipFile" "$ResolvedInputFile" > $null 2>&1
if ($LASTEXITCODE -ne 0) {
    Die "Compression failed."
}
#Write-Host "Compression completed: $ZipFile"

# Check if the zip file was created successfully
if (-not (Test-Path $ZipFile)) {
    Die "Zip file not found after compression: $ZipFile"
}

# Read the compressed file into a byte array and encode it to Base64
$Bytes = [IO.File]::ReadAllBytes($ZipFile)
$Base64String = [Convert]::ToBase64String($Bytes)

# Generate the extraction script
@"
# This is file "genscript.ps1".

function Die {
    param (
        [string]`$Message
    )
    Write-Host "ERROR: `$Message" -ForegroundColor Red
    exit 1
}

# Base64 encoded string
`$Base64String = '$Base64String'

# Define the output zip file (in-place)
`$ZipFile = Join-Path -Path (Get-Location) -ChildPath "$BaseName.zip"

# Convert the Base64 string to a byte array
`$bytes = [Convert]::FromBase64String(`$Base64String)

# Decode the Base64 string and write it to a zip file
[IO.File]::WriteAllBytes(`$ZipFile, [Convert]::FromBase64String(`$Base64String))
Write-Host "Zip file created: `$ZipFile"

# Extract the zip file
if (-not (Test-Path `$ZipFile)) {
    Die "Zip file not found: `$ZipFile"
	exit 1
}

# Use the current directory as the destination path
`$DestinationPath = Get-Location

# Extract the zip file
try {
    Expand-Archive -Path `$ZipFile -DestinationPath `$DestinationPath -Force
    Write-Host "Extraction completed successfully!"
} catch {
    Write-Host "ERROR: Failed to extract zip file. `$_"
    exit 1
}

# Clean up temporary files
Remove-Item -Path `$ZipFile -Force
#Write-Host "Temporary zip file removed."

"@ | Set-Content -Path $GenScript

# Make the generated script executable
Remove-Item -Path $ZipFile -Force
Write-Host "Extraction script generated: $GenScript"
Write-Host "Process completed successfully!"
