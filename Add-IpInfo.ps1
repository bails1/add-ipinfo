function Add-IpInfo {
    <#
    .SYNOPSIS
        Enriches CSV log files containing IP addresses with additional Geo IP Data.
    .DESCRIPTION
        Accepts a CSV log file containing IP addresses. Generates an enriched CSV log file containing Geo IP Data obtained from ip-api.com.
        Utilizes batch processing to minimize the required number of API requests. Implements rate limiting and retries for failed requests.
    .INPUTS
        None. Pipeline is unused.
    .OUTPUTS
        None. Pipeline is unused.
    .EXAMPLE
        PS> Add-IpInfo -InFile input.csv -OutFile out.csv

        Basic Usage.
    
    .EXAMPLE
        PS> Add-IpInfo -InFile input.csv -IpColumn ipv4_addr -OutFile out.csv

        Explicitly specified IP column name. Useful if multiple columns contain IP addresses.
    .EXAMPLE
        PS> Add-IpInfo -InFile input.csv -MaxAttempts 0 -AllowMissing -OutFile out.csv

        Do not retry failed requests and allow missing information if some requests fail.
    #>

    param (
        # Input CSV file containing IP addresses
        [Parameter(Mandatory=$true)]
        [ValidateScript({if ($_) { Test-Path -Path $_ -PathType Leaf -Include *.csv }})]
        [string] $InFile,

        # Output CSV file
        [Parameter(Mandatory=$true)]
        [string] $OutFile,

        # Name of column containing IP addresses
        [ValidateScript({if ($_) { (Import-Csv -Path $InFile | Get-Member -MemberType NoteProperty).Name -contains $_ }})]
        [string] $IpColumn,

        # CSV delimiter used for input and output files
        [char] $Delimiter = ",",

        # Fields to request from ip-api.com
        # Default: status,message,country,countryCode,region,regionName,city,zip,lat,lon,isp,org,as,asname,mobile,proxy,hosting,query
        [string] $Fields = "21229311",

        # Number of IP addresses to include in each API batch request
        [ValidateRange(1, 100)]
        [int] $BatchSize = 100,
        
        # Maximum number of attempts per API request 
        [ValidateRange(0, 20)]
        [int] $MaxAttempts = 3,

        # Allows IP info to be omitted from output if -MaxAttempts is exceed
        [switch] $AllowMissing,

        # Overwrite -OutFile if it already exists
        [switch] $Force
    )

    $CsvInput = Import-Csv -Path $InFile -Delimiter $Delimiter

    # If name of IP column is not explicitly specified
    if (-not $IpColumn) {
        # Attempt to identify IP column using regex
        foreach ($Col in $CsvInput[0].PSObject.Properties) {
            $IpRegex = "\b(?:(?:2(?:[0-4][0-9]|5[0-5])|[0-1]?[0-9]?[0-9])\.){3}(?:(?:2([0-4][0-9]|5[0-5])|[0-1]?[0-9]?[0-9]))\b"
            if ($Col.Value -match $IpRegex) {
                # Use the first column containing an IP address
                $IpColumn = $Col.Name
                break
            }
        }

        # If no column contains IP addresses
        if (-not $IpColumn) {
            throw "Could not find any column containing IP addresses"
        }
    }

    # Create a unqiue list of IP addresses from CSV
    $UniqueIpAddresses = $CsvInput | Select-Object -ExpandProperty $IpColumn | Sort-Object -Unique

    # Create an empty hash table to store information for each IP address
    $IpInfo = @{}

    # Iterate through list of unique IP addresses in batches to reduce the number of required API requests
    for ($i = 0; $i -lt $UniqueIpAddresses.Count; $i += $BatchSize) {
        # The end index for this batch will either be the current index + $BatchSize
        # or the last index of $CsvInput, which ever is smaller. This allows the last
        # batch to be smaller than $BatchSize if needed
        $BatchEndIndex = [Math]::Min($i + $BatchSize - 1, $UniqueIpAddresses.Count - 1)
        $Batch = $UniqueIpAddresses[$i..$BatchEndIndex]

        # Make API request, retry if unsuccessful
        $Success = $false
        $Attempts = 0

        while ((-not $Success) -and (($Attempts -lt $MaxAttempts) -or ($Attempts -eq 0 -and $MaxAttempts -eq 0))) {
            $ApiUrl = "http://ip-api.com/batch?fields=$Fields"

            try {
                $Response = Invoke-WebRequest -Method Post -Uri $ApiUrl -Body ($Batch | ConvertTo-Json)
                $StatusCode = $Response.StatusCode

                # If response was successful
                if ($StatusCode -eq 200) {
                    # Add IP address details to hash table
                    $Response.Content | ConvertFrom-Json -AsHashtable | ForEach-Object {
                        $IpInfo.Add($_.query, $_)
                    }
                    $Success = $true
                }
            } catch {
                $Attempts++
                $StatusCode = $_.Exception.Response.StatusCode.value__
            } finally {
                # Throw an error if max attempts is exceeded and missing data is not permitted
                if (($Attempts -ge $MaxAttempts) -and -not $AllowMissing) {
                    throw "Max API request attempts exceeded"
                }

                # Handle rate limit, don't sleep if this is the last request
                if (($BatchEndIndex -ne $UniqueIpAddresses.Count - 1) -and (($Response.Headers.'X-Rl'[0] -le 0) -or ($StatusCode -eq 429))) {
                    $Ttl = $Response.Headers.'X-Ttl'[0]
                    Write-Warning "API request limit hit... waiting $Ttl seconds"
                    Start-Sleep -Seconds $Ttl
                }
            }
        }
    }

    # Iterate through original CSV and append IP info
    # This will overwrite values in columns with names matching ip-api.com field names
    $CsvOutput = $CsvInput
    $CsvOutput | ForEach-Object {
        if ($IpInfo[$_.$IpColumn]) {
            $_ | Add-Member -NotePropertyMembers $IpInfo[$_.$IpColumn] -Force
        }
    }

    # Write CSV output if the file does not exist or force was provided
    if ($Force -or -not (Test-Path -Path $OutFile -PathType Leaf)) {
        $CsvOutput | Export-Csv -Path $OutFile -Delimiter $Delimiter
    }
}
