
$ips = @('192.168.1.1', '192.168.1.2', '192.168.1.4', '192.168.1.6', '192.168.1.7', '192.168.1.8', '192.168.1.16', '192.168.1.18', '192.168.1.22', '192.168.1.37', '192.168.1.39', '192.168.1.42')
$ports = @(554, 37777, 80, 8000, 8899, 5000, 554)
foreach ($ip in $ips) {
    foreach ($p in $ports) {
        try {
            $tcp = New-Object System.Net.Sockets.TcpClient
            $iar = $tcp.BeginConnect($ip, $p, $null, $null)
            $wh = $iar.AsyncWaitHandle.WaitOne(300, $false)
            if ($wh -and $tcp.Connected) {
                $tcp.EndConnect($iar)
                Write-Output "OPEN: $ip : $p"
            }
            $tcp.Close()
        } catch {}
    }
}
Write-Output "FINISHED_SCAN"
