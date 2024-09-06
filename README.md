# Cortex Server Client Script

This script facilitates the transfer of files from Cortex to a PC.

## Prerequisites

- Ensure that port 3000 is open.

## Instructions

1. Rename the GTB agent file to `GTB.msi`
2. Create a zip file containing the batch file and the GTB MSI file.
3. Update the server-side zip file path as follows, replacing it with the correct location on your system:

   ```python
   filename = r"C:\Users\Dilanka\Downloads\SendFolder\GTB.zip"  # Path to your zip file
   ```

   Ensure that the file path points to the correct directory on your machine.

### If you need PowerShell server-side script run the "powershell__Server_v2.ps1" script

--- 

