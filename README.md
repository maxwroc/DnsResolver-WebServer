# DnsResolver-WebServer
Simple powershell web server example. 

### server.ps1

Starts web server listening on given address.

Usage: .\server.ps1 -Url "http://localhost:8080"

### client.ps1

Client script for fetching resolved ips from server. It can update hosts file if the UpdateHostsFile flag was used.

Usage: .\client.ps1 -Server "http://server-host:8080" -HostToResolve host-name -UpdateHostsFile

### server-runner.ps1

Helper script for starting web server. Creates a background job for server instance. It can wait for user input to stop the server or just run it in background. When it runs in background you can easily stop it by Stop switch/flag.