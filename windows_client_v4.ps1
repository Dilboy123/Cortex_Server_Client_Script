# Script with error handeling and installing the GTB agent
Add-Type -AssemblyName System.IO.Compression.FileSystem

function Receive-File {
    param (
        [string]$filename,
        [string]$remoteHost,
        [int]$port,
        [int]$retryAttempts = 2, # Changed to allow two attempts
        [int]$retryDelay = 5,
        [string]$destinationFolder = "C:\ReceivedFiles1" # Default folder 
    )

    $clientSocket = $null
    $fileStream = $null
    $networkStream = $null
    $successful = $false

    # Check if the destination folder already exists
    if (Test-Path -Path $destinationFolder) {
        Write-Host "Destination folder is already available."
        return 
    } else {
        
        New-Item -ItemType Directory -Path $destinationFolder
        Write-Host "Created folder: $destinationFolder"
    }

    # Combine the folder path with the filename
    $fullFilePath = Join-Path -Path $destinationFolder -ChildPath (Split-Path -Leaf $filename)

    for ($attempt = 0; $attempt -lt $retryAttempts; $attempt++) {
        try {
            
            $clientSocket = New-Object System.Net.Sockets.TcpClient
           
            $clientSocket.Connect($remoteHost, $port)
            Write-Host "Connected to server $remoteHost`:$port on attempt $($attempt + 1)"
            
            
            $fileStream = [System.IO.File]::OpenWrite($fullFilePath)
            $networkStream = $clientSocket.GetStream()
            $buffer = New-Object byte[] 1024

            $totalBytesRead = 0

            while ($true) {
                $bytesRead = $networkStream.Read($buffer, 0, $buffer.Length)
                if ($bytesRead -le 0) {
                    break
                }
                $fileStream.Write($buffer, 0, $bytesRead)
                $totalBytesRead += $bytesRead
            }
            
            Write-Host "File saved at location: $fullFilePath"
            Write-Host "Total bytes received: $totalBytesRead"
            Write-Host "File received successfully"
            $successful = $true
            break

        } catch [System.Net.Sockets.SocketException] {
            Write-Host "Socket error: $_"
            Write-Host "Retrying in $retryDelay seconds..."
            Start-Sleep -Seconds $retryDelay
        } catch [System.IO.IOException] {
            Write-Host "File I/O error: $_"
            break
        } catch {
            Write-Host "An unexpected error occurred: $_"
            break
        } finally {
            if ($networkStream -ne $null) {
                $networkStream.Close()
                Write-Host "Network stream closed"
            }
            if ($fileStream -ne $null) {
                $fileStream.Close()
                Write-Host "File stream closed"
            }
            if ($clientSocket -ne $null) {
                $clientSocket.Close()
                Write-Host "Socket closed"
            }
        }
    }

    if (-not $successful) {
        Write-Host "Failed to receive the file after $retryAttempts attempts."
    }

   # Unzip the file if it is a zip file
    if ($filename -like "*.zip") {
        try {
            $unzipPath = Join-Path -Path $destinationFolder -ChildPath (Split-Path -Leaf ($filename -replace ".zip", ""))
            [System.IO.Compression.ZipFile]::ExtractToDirectory($fullFilePath, $unzipPath)
            Write-Host "File unzipped to: $unzipPath"
            
            # Delete the original zip file
            Remove-Item -Path $fullFilePath -Force
            Write-Host "Deleted original ZIP file: $fullFilePath"

            # Check if bat file exists
            $batFile = Join-Path -Path $unzipPath -ChildPath "gtbin.bat"
            if (Test-Path -Path $batFile) {
                Write-Host "Bat file found. Executing as Domain Administrator..."

                
                $username = "connexit\Administrator"  # domain\admin username
                $password = ConvertTo-SecureString "Nuwan@123" -AsPlainText -Force  # password
                $adminCredential = New-Object System.Management.Automation.PSCredential($username, $password)

                # Start the batch file
                Start-Process -FilePath $batFile -Credential $adminCredential -Wait
                Write-Host "Bat executed successfully as Domain Administrator."
            } else {
                Write-Host "Bat file not found in $unzipPath"
            }

        } catch {
            Write-Host "Error unzipping or executing file: $_"
        }
    }
}

# Parameters
$filename = "GTB.zip"
$remoteHost = "192.168.9.206"
$port = 3000

# Call the function
Receive-File -filename $filename -remoteHost $remoteHost -port $port
