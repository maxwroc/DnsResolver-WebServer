# DnsResolver-WebServer
Simple powershell web server example. It is a client-server app resolving host names on the remote/server machine.

### server.ps1

Starts web server listening on given address.

Usage: ``.\server.ps1 -Url "http://localhost:8080"``

### client.ps1

Client script for fetching resolved ips from server. It can update hosts file if the UpdateHostsFile flag was used.

Usage: ``.\client.ps1 -Server "http://server-host:8080" -HostToResolve host-name -UpdateHostsFile``

Server address parameter is being cached in local file so you can skip it in the following commands.

### server-runner.ps1

Helper script for starting web server. Creates a background job for server instance. It can wait for user input to stop the server or just run it in background. When it runs in background you can easily stop it by Stop switch/flag.

Usage:
* ``.\server-runner.ps1 -Url "http://localhost:8080"``

  Starts server instance and waits for Ctrl+C keyboard combination to stop the server.
* ``.\server-runner.ps1 -Url "http://localhost:8080" -RunInBackground``

  Starts server instance in background.
* ``.\server-runner.ps1 -Url "http://localhost:8080" -Stop``

  Terminates running server instance
