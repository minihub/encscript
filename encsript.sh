#!/bin/bash

set -euo pipefail  # Exit on error, unset variable, or pipeline failure

die() {
    printf "ERROR: %s\n" "$1" >&2
    exit 1
}

usage() {
    printf "Usage: %s <path_to_file>\n" "$(basename "$0")"
    exit 0
}

# Check for required commands
check_command() {
    command -v "$1" >/dev/null 2>&1 || die "$1 is not installed. Please install it first."
}

# Check for sufficient disk space
check_disk_space() {
    local required_space=$1
    local available_space
    available_space=$(df "$PWD" | awk 'NR==2 {print $4}')
    if (( available_space < required_space )); then
        die "Insufficient disk space. Required: ${required_space}K, Available: ${available_space}K"
    fi
}

# Check for required commands
check_command "ar"
check_command "bzip2"
check_command "openssl"

# Determine the checksum command based on the OS
if command -v md5sum >/dev/null 2>&1; then
    CHECKSUM_CMD="md5sum"
else
    CHECKSUM_CMD="md5"
fi

# Check if the correct number of arguments is provided
if [ "$#" -ne 1 ]; then
    usage
fi

INPUT_FILE="$1"

# Check if the provided file exists
if [ ! -f "$INPUT_FILE" ]; then
    die "File not found: $INPUT_FILE"
fi

# Check for sufficient disk space (estimate size of output files)
check_disk_space 1024  # Adjust as necessary for your use case

# Define output filenames
BZIP2_FILE="${INPUT_FILE}.bz2"
CHECKSUM_FILE="${BZIP2_FILE}.md5"
TEMP_ARCHIVE=$(mktemp) || die "Failed to create temporary archive!"
GENSCRIPT="genscript.sh"

# Cleanup function
cleanup() {
    rm -f "$BZIP2_FILE" "$CHECKSUM_FILE" "$TEMP_ARCHIVE"
}
trap cleanup EXIT

# Compress the input file with bzip2, preserving attributes
echo "Compressing the input file..."
bzip2 -k "$INPUT_FILE"
echo "Compression completed: $BZIP2_FILE"

# Generate the MD5 checksum
echo "Generating MD5 checksum..."
if [ "$CHECKSUM_CMD" = "md5sum" ]; then
    $CHECKSUM_CMD "$BZIP2_FILE" > "$CHECKSUM_FILE"
else
    md5 "$BZIP2_FILE" | awk '{print $NF, $1}' > "$CHECKSUM_FILE"
fi
echo "Checksum generated: $CHECKSUM_FILE"

# Create a temporary archive containing the bzip2 file and its checksum
echo "Creating temporary archive..."
ar rcs "$TEMP_ARCHIVE" "$BZIP2_FILE" "$CHECKSUM_FILE"
echo "Temporary archive created: $TEMP_ARCHIVE"

# Generate the genscript.sh file
echo "Generating the extraction script..."
{
    printf "#! /bin/bash\n"
    printf "# This is file \"genscript.sh\".\n"
    printf "die() { printf \"ERROR: \$1\\n\" >&2; exit 1; }\n\n"
    printf "# Check for required commands\n"
    printf "check_command() {\n"
    printf "    command -v \"\$1\" >/dev/null 2>&1 || die \"\$1 is not installed. Please install it first.\"\n"
    printf "}\n\n"
    printf "# Check for binutils (for ar) and openssl\n"
    printf "check_command \"ar\"\n"
    printf "check_command \"openssl\"\n\n"
    printf "echo \"Decoding attachment - please standby.\"\n"
    printf "{\n"
    printf "    while read LINE; do test \"\$LINE\" = \"exit\" && break; done\n"
    printf "    openssl enc -d -a;\n"
    printf "} < \"\$0\" > script.ar || {\n"
    printf "    die \"Error in base64-encoded text!\";\n"
    printf "}\n"
    printf "ar -x script.ar || die \"Cannot extract archive!\"\n"
    printf "BZIP2_FILE=\"%s\";\n" "$(basename "$BZIP2_FILE")"
    printf "CHECKSUM_FILE=\"\$BZIP2_FILE.md5\";\n"
    printf "%s -c \"\$CHECKSUM_FILE\" || {\n" "$CHECKSUM_CMD"
    printf "    die \"Checksum error in extracted bzip2 file!\";\n"
    printf "}\n"
    printf "bunzip2 -f \"\$BZIP2_FILE\" || die \"Corrupted bzip2 archive!\"\n"
    printf "echo \"Script extracted successfully!\"\n"
    printf "rm script.ar \"\$CHECKSUM_FILE\"\n"
    printf "exit\n"
    # Output the base64 encoded content of the temporary archive
    base64 "$TEMP_ARCHIVE"
} > "$GENSCRIPT" || die "Failed to create genscript.sh!"

# Make the generated script executable
chmod +x "$GENSCRIPT"
echo "Extraction script generated: $GENSCRIPT"
echo "Process completed successfully!"
