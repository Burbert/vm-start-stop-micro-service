# Input bindings are passed in via param block.
param($Timer)

$url = "$($env:CHECKER_URL)?code=$($env:ACCESS_KEY)"
Invoke-WebRequest -Method GET -Uri $url
