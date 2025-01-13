#! /bin/bash

die() {
    echo "ERROR: $1" >& 2
    exit 1
}

# Check for required commands
check_command() {
    command -v "$1" >/dev/null 2>&1 || die "$1 is not installed. Please install it first."
}

# Check for binutils (for ar) and openssl
check_command "ar"
check_command "openssl"

# Check if the correct number of arguments is provided
if [ "$#" -ne 1 ]; then
    die "Usage: $0 <path_to_file>"
fi

INPUT_FILE="$1"

# Check if the provided file exists
if [ ! -f "$INPUT_FILE" ]; then
    die "File not found: $INPUT_FILE"
fi

# Define output filenames
BZIP2_FILE="$INPUT_FILE.bz2"
CHECKSUM_FILE="$BZIP2_FILE.md5"
TEMP_ARCHIVE="temporary.ar"
GENSCRIPT="genscript.sh"

# Compress the input file with bzip2, preserving attributes
bzip2 -k "$INPUT_FILE" || die "Failed to compress the file!"

# Generate the MD5 checksum
md5sum "$BZIP2_FILE" > "$CHECKSUM_FILE" || die "Failed to generate checksum!"

# Create a temporary archive containing the bzip2 file and its checksum
ar rcs "$TEMP_ARCHIVE" "$BZIP2_FILE" "$CHECKSUM_FILE" || die "Failed to create archive!"

# Generate the genscript.sh file
{
    echo "#! /bin/bash"
    echo "# This is file \"genscript.sh\"."
    echo "die() { echo \"ERROR: \$1\" >& 2; exit 1; }"
    echo ""
    echo "# Check for required commands"
    echo "check_command() {"
    echo "    command -v \"\$1\" >/dev/null 2>&1 || die \"\$1 is not installed. Please install it first.\""
    echo "}"
    echo ""
    echo "# Check for binutils (for ar) and openssl"
    echo "check_command \"ar\""
    echo "check_command \"openssl\""
    echo ""
    echo "echo \"Decoding attachment - please standby.\""
    echo "{"
    echo "    while read LINE; do test \"\$LINE\" = \"exit\" && break; done"
    echo "    openssl enc -d -a;"
    echo "} < \"\$0\" > script.ar || {"
    echo "    die \"Error in base64-encoded text!\";"
    echo "}"
    echo "ar -x script.ar || die \"Cannot extract archive!\""
    echo "BZIP2_FILE=\"$(basename "$BZIP2_FILE")\";"
    echo "CHECKSUM_FILE=\"\$BZIP2_FILE.md5\";"
    echo "md5sum -c \"\$CHECKSUM_FILE\" || {"
    echo "    die \"Checksum error in extracted bzip2 file!\";"
    echo "}"
    echo "bunzip2 -f \"\$BZIP2_FILE\" || die \"Corrupted bzip2 archive!\""
    echo "echo \"Script extracted successfully!\""
    echo "rm script.ar \"\$CHECKSUM_FILE\""
    echo "exit"
    # Output the base64 encoded content of the temporary archive
    base64 "$TEMP_ARCHIVE"
} > "$GENSCRIPT" || die "Failed to create genscript.sh!"

# Clean up temporary files
rm "$BZIP2_FILE" "$CHECKSUM_FILE" "$TEMP_ARCHIVE"

echo "Shell script generated successfully: $GENSCRIPT"

# Make the generated script executable
chmod +x "$GENSCRIPT" || die "Failed to make $GENSCRIPT executable!"
