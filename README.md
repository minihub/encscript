# Encrypted File Compression and Extraction Scripts

This repository contains two scripts designed to compress a file, generate an MD5 checksum, and create an encrypted archive that can be extracted using a self-contained extraction script. The scripts are useful for securely distributing files with built-in integrity checks.

## Files

- **`encscript.sh`**: A Bash script for Linux and macOS systems.
- **`encscript.ps1`**: A PowerShell script for Windows systems.

## System Requirements

- **`encscript.sh`**: Designed for Linux and macOS systems with `ar`, `bzip2`, `openssl`, and `md5sum` or `md5` installed.
- **`encscript.ps1`**: Designed for Windows systems with `7z` (7-Zip) and `CertUtil` installed.

## How It Works

Both scripts perform the following tasks:

- **Compress the Input File**: Uses `bzip2` (Linux/macOS) or `7z` (Windows) to compress the input file.
- **Generate an MD5 Checksum**: Creates an MD5 checksum for the compressed file to ensure data integrity.
- **Create a Temporary Archive**: Combines the compressed file and its checksum into a temporary archive.
- **Generate an Extraction Script**: Creates a self-contained extraction script that includes the base64-encoded content of the temporary archive.

## Usage

### **Step 1: Compress and Encrypt a File**

1. Run the script with the file you want to compress and encrypt as an argument:
   - For Linux/macOS:
     ```bash
     ./encscript.sh <path_to_file>
     ```
   - For Windows:
     ```powershell
     .\encscript.ps1 <path_to_file>
     ```
2. The script will generate a self-contained extraction script that contains the compressed and encrypted data.

### **Step 2: Extract the File**

1. Transfer the extraction script to the target system.
2. Run the extraction script to extract the original file:
   - For Linux/macOS:
     ```bash
     ./genscript.sh
     ```
   - For Windows:
     ```powershell
     .\genscript.ps1
     ```
3. The script will extract and decompress the file, verifying its integrity in the process.

## Example

### Compressing a File

- For Linux/macOS:
```bash
./encscript.sh myfile.txt
```
- For Windows:
```powershell
.\encscript.ps1 myfile.txt
```
This will generate a self-contained extraction script that contains the compressed and encrypted version of `myfile.txt`.

### Extracting the File

- For Linux/macOS:
```bash
./genscript.sh
```
- For Windows:
```powershell
.\genscript.ps1
```
This will extract `myfile.txt` from the extraction script, decompress it, and verify its integrity.

## Notes

- Ensure that the target system has the necessary commands installed before running the extraction script.
- The extraction script is self-contained and can be distributed independently.

## License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.
