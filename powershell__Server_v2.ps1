# Error handling file with sending percentage working script without concurrent sessions
function Send-File {
    param (
        [string]$filename,
        [string]$serverHost,
        [int]$port
    )

    # Create a TCP listener
    try {
        $listener = [System.Net.Sockets.TcpListener]::new([System.Net.IPAddress]::Parse($serverHost), $port)
        $listener.Start()
        Write-Host "Server listening on $serverHost : $port"
    }
    catch {
        Write-Host "Error: Failed to start TCP listener. $_"
        return
    }

    while ($true) {
        try {
            # Accept a connection from a client
            $client = $listener.AcceptTcpClient()
            $stream = $client.GetStream()
            $clientEndpoint = $client.Client.RemoteEndPoint
            Write-Host "Got connection from $clientEndpoint"

            # Open the file and send it in chunks
            $fileStream = [System.IO.File]::OpenRead($filename)
            $fileSize = $fileStream.Length
            $totalBytesSent = 0
            $buffer = New-Object byte[] 1024

            while (($bytesRead = $fileStream.Read($buffer, 0, $buffer.Length)) -gt 0) {
                $stream.Write($buffer, 0, $bytesRead)
                $totalBytesSent += $bytesRead
                $percentage = [math]::Round(($totalBytesSent / $fileSize) * 100, 2)
                Write-Host -NoNewline "`rSending: $percentage% complete"
            }

            Write-Host "`nFile sent successfully to $clientEndpoint"
            $fileStream.Close()
        }
        catch {
            Write-Host "`nError: $_"
        }
        finally {
            if ($stream) { $stream.Close() }
            if ($client) { $client.Close() }
        }
    }

    try {
        $listener.Stop()
    }
    catch {
        Write-Host "Error: Failed to stop TCP listener. $_"
    }
}

function Get-PrivateIP {
    $socket = New-Object Net.Sockets.Socket([Net.Sockets.AddressFamily]::InterNetwork, [Net.Sockets.SocketType]::Dgram, [Net.Sockets.ProtocolType]::Udp)
    try {
        $socket.Connect('8.8.8.8', 80)
        $ip = $socket.LocalEndPoint.Address.ToString()
    }
    catch {
        Write-Host "Error: Unable to determine private IP. $_"
        $ip = '127.0.0.1'
    }
    finally {
        $socket.Close()
    }
    return $ip
}

# Get the private IP address
$privateIP = Get-PrivateIP
Write-Host "Private IP : $privateIP"

# Main script execution
$filename = "C:\Users\Dilanka\Downloads\SendFolder\GTB.zip"  
$serverHost = $privateIP           
$port = 3000                       

Send-File -filename $filename -serverHost $serverHost -port $port
