# Overview
This script is designed to take a file as input, compress it, generate a checksum, create an archive containing the compressed file and its checksum, and then generate a self-extracting script that can decode and extract the original file from the archive.

## Usage

```
encscript.sh /path/to/some/file
```
The script produces a self-containing `genscript.sh` shell script that extracts it's content inplace where executed, as described above.

## Breakdown
1. Shebang and Function Definitions:
   ```
   #! /bin/bash
   
   die() {
       echo "ERROR: $1" >& 2
       exit 1
   }
   ```
   - The script starts with a shebang (`#! /bin/bash`), indicating that it should be run in the Bash shell.
   - The `die` function is defined to print an error message and exit the script if an error occurs.
3. Check for Required Commands:
   ```
   check_command() {
       command -v "$1" >/dev/null 2>&1 || die "$1 is not installed. Please install it first."
   }
   
   # Check for binutils (for ar) and openssl
   check_command "ar"
   check_command "openssl"
   ```
   - The `check_command` function checks if a command is available on the system using `command -v`.
   - It checks for the presence of `ar` (from binutils) and `openssl`. If either command is not found, it calls the `die` function with an appropriate error message.
4. Argument Check:
   ```
   if [ "$#" -ne 1 ]; then
       die "Usage: $0 <path_to_file>"
   fi
   
   INPUT_FILE="$1"
   ```
   - The script checks if exactly one argument (the path to the input file) is provided. If not, it exits with a usage message.
   - The input file path is stored in the variable `INPUT_FILE`.
5. File Existence Check:
   ```
   if [ ! -f "$INPUT_FILE" ]; then
       die "File not found: $INPUT_FILE"
   fi
   ```
   The script checks if the provided file exists. If it does not, it exits with an error message.
6. Define Output Filenames:
   ```
   BZIP2_FILE="$INPUT_FILE.bz2"
   CHECKSUM_FILE="$BZIP2_FILE.md5"
   TEMP_ARCHIVE="temporary.ar"
   GENSCRIPT="genscript.sh"
   ```
   The script defines several output filenames:
   - `BZIP2_FILE`:    The name of the compressed file.
   - `CHECKSUM_FILE`: The name of the MD5 checksum file.
   - `TEMP_ARCHIVE`:  The name of the temporary archive file.
   - `GENSCRIPT`:     The name of the generated script file.
7. Compress the Input File:
   ```
   bzip2 -k "$INPUT_FILE" || die "Failed to compress the file!"
   ```
   The script compresses the input file using `bzip2` with the `-k` option to keep the original file. If compression fails, it exits with an error message.
8. Generate the MD5 Checksum:
   ```
   md5sum "$BZIP2_FILE" > "$CHECKSUM_FILE" || die "Failed to generate checksum!"
   ```
   The script generates an MD5 checksum for the compressed file and saves it to the checksum file. If this fails, it exits with an error message.
9. Create a Temporary Archive:
   ```
   ar rcs "$TEMP_ARCHIVE" "$BZIP2_FILE" "$CHECKSUM_FILE" || die "Failed to create archive!"
   ```
   The script creates a temporary archive using `ar`, which includes the compressed file and its checksum. If this fails, it exits with an error message.
10. Generate the `genscript.sh` File:
    ```
    {
      echo "#! /bin/bash"
      echo "# This is file \"genscript.sh\"."
      ...
      # Output the base64 encoded content of the temporary archive
      base64 "$TEMP_ARCHIVE"
    } > "$GENSCRIPT" || die "Failed to create genscript.sh!"
    ```
    The script generates a new shell script named `genscript.sh`. This script contains:
     - A shebang and a `die` function.
     - A function to check for required commands (`ar` and `openssl`).
     - Logic to decode the base64-encoded content of the temporary archive and extract the files.
     - Commands to verify the checksum and decompress the bzip2 file.
       
    The base64-encoded content of the temporary archive is appended to the end of the generated script.
11. Clean Up Temporary Files:
    ```
    rm "$BZIP2_FILE" "$CHECKSUM_FILE" "$TEMP_ARCHIVE"
    ```
