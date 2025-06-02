# Add-IpInfo

Enriches CSV log files containing IP addresses with additional Geo IP Data.

Accepts a CSV log file containing IP addresses. Generates an enriched CSV log file containing Geo IP Data obtained from [ip-api.com](https://ip-api.com/). Utilizes batch processing to minimize the required number of API requests. Implements rate limiting and retries for failed requests.

# Usage

```powershell
PS> Get-Help Add-IpInfo -Full

NAME
    Add-IpInfo

SYNOPSIS
    Enriches CSV log files containing IP addresses with additional Geo IP Data.


SYNTAX
    Add-IpInfo [-InFile] <String> [-OutFile] <String> [[-IpColumn] <String>] [[-Delimiter] <Char>] [[-Fields] <String>] [[-BatchSize] <Int32>] [[-MaxAttempts] <Int32>] [-AllowMissing] [-Force] [<CommonParameters>]


DESCRIPTION
    Accepts a CSV log file containing IP addresses. Generates an enriched CSV log file containing Geo IP Data obtained from ip-api.com.
    Utilizes batch processing to minimize the required number of API requests. Implements rate limiting and retries for failed requests.


PARAMETERS
    -InFile <String>
        Input CSV file containing IP addresses

        Required?                    true
        Position?                    1
        Default value
        Accept pipeline input?       false
        Aliases
        Accept wildcard characters?  false

    -OutFile <String>
        Output CSV file

        Required?                    true
        Position?                    2
        Default value
        Accept pipeline input?       false
        Aliases
        Accept wildcard characters?  false

    -IpColumn <String>
        Name of column containing IP addresses

        Required?                    false
        Position?                    3
        Default value
        Accept pipeline input?       false
        Aliases
        Accept wildcard characters?  false

    -Delimiter <Char>
        CSV delimiter used for input and output files

        Required?                    false
        Position?                    4
        Default value                ,
        Accept pipeline input?       false
        Aliases
        Accept wildcard characters?  false

    -Fields <String>
        Fields to request from ip-api.com
        Default: status,message,country,countryCode,region,regionName,city,zip,lat,lon,isp,org,as,asname,mobile,proxy,hosting,query

        Required?                    false
        Position?                    5
        Default value                21229311
        Accept pipeline input?       false
        Aliases
        Accept wildcard characters?  false

    -BatchSize <Int32>
        Number of IP addresses to include in each API batch request

        Required?                    false
        Position?                    6
        Default value                100
        Accept pipeline input?       false
        Aliases
        Accept wildcard characters?  false

    -MaxAttempts <Int32>
        Maximum number of attempts per API request

        Required?                    false
        Position?                    7
        Default value                3
        Accept pipeline input?       false
        Aliases
        Accept wildcard characters?  false

    -AllowMissing [<SwitchParameter>]
        Allows IP info to be omitted from output if -MaxAttempts is exceed

        Required?                    false
        Position?                    named
        Default value                False
        Accept pipeline input?       false
        Aliases
        Accept wildcard characters?  false

    -Force [<SwitchParameter>]
        Overwrite -OutFile if it already exists

        Required?                    false
        Position?                    named
        Default value                False
        Accept pipeline input?       false
        Aliases
        Accept wildcard characters?  false

    <CommonParameters>
        This cmdlet supports the common parameters: Verbose, Debug,
        ErrorAction, ErrorVariable, WarningAction, WarningVariable,
        OutBuffer, PipelineVariable, and OutVariable. For more information, see
        about_CommonParameters (https://go.microsoft.com/fwlink/?LinkID=113216).

INPUTS
    None. Pipeline is unused.


OUTPUTS
    None. Pipeline is unused.


    -------------------------- EXAMPLE 1 --------------------------

    PS>Add-IpInfo -InFile input.csv -OutFile out.csv

    Basic Usage.




    -------------------------- EXAMPLE 2 --------------------------

    PS>Add-IpInfo -InFile input.csv -IpColumn ipv4_addr -OutFile out.csv

    Explicitly specified IP column name. Useful if multiple columns contain IP addresses.




    -------------------------- EXAMPLE 3 --------------------------

    PS>Add-IpInfo -InFile input.csv -MaxAttempts 0 -AllowMissing -OutFile out.csv

    Do not retry failed requests and allow missing information if some requests fail.





RELATED LINKS

```

# Example

```powershell
PS> Get-Content .\sample.csv
"timestamp","username","loginStatus","ip"
"2025-06-02T17:18:12","StArGaZeR42","Success","9.63.56.29"     
"2025-06-02T17:23:12","MoonChAs3r","Success","155.182.145.95"  
"2025-06-02T17:44:57","QuickSiLver9","Success","223.58.107.102"
"2025-06-02T18:04:16","EchoWaves88","Failure","79.94.105.233"  
"2025-06-02T18:44:29","EchoWaves88","Success","79.94.105.233"  
"2025-06-02T18:32:02","MystiC_Vibe","Success","54.225.130.151" 
"2025-06-02T18:47:39","ShAdOwHuNtEr","Success","181.74.250.116"
"2025-06-02T19:12:15","CosM1cDream","Success","24.63.15.145"   
"2025-06-02T19:38:48","SilentWh1sper","Success","158.94.115.57"
"2025-06-02T19:47:22","Fr0stFire","Success","65.248.78.165"


PS> Add-IpInfo -InFile .\sample.csv -OutFile .\output.csv


PS> > Get-Content .\output.csv
"timestamp","username","loginStatus","ip","status","country","countryCode","region","regionName","city","zip","lat","lon","isp","org","as","asname","mobile","proxy","hosting","query"
"2025-06-02T17:18:12","StArGaZeR42","Success","9.63.56.29","success","Canada","CA","QC","Quebec","Montreal","H4X","45.5019","-73.5674","IBM","IBM","","","False","False","False","9.63.56.29"
"2025-06-02T17:23:12","MoonChAs3r","Success","155.182.145.95","success","United States","US","SC","South Carolina","McClellanville","29458","33.208","-79.385","Bank of America","Bank of America","","","False","False","False","155.182.145.95"
"2025-06-02T17:44:57","QuickSiLver9","Success","223.58.107.102","success","South Korea","KR","11","Seoul","Seoul","04625","37.5614","126.996","SK Telecom","SK Telecom","AS9644 SK Telecom","SKTELECOM-NET-AS","True","False","False","223.58.107.102"
"2025-06-02T18:04:16","EchoWaves88","Failure","79.94.105.233","success","France","FR","IDF","Île-de-France","Fontainebleau","77300","48.4126","2.6949","Societe Francaise Du Radiotelephone - SFR SA","SFR User Data","AS15557 Societe Francaise Du Radiotelephone - SFR SA","LDCOMNET","False","False","False","79.94.105.233"
"2025-06-02T18:44:29","EchoWaves88","Success","79.94.105.233","success","France","FR","IDF","Île-de-France","Fontainebleau","77300","48.4126","2.6949","Societe Francaise Du Radiotelephone - SFR SA","SFR User Data","AS15557 Societe Francaise Du Radiotelephone - SFR SA","LDCOMNET","False","False","False","79.94.105.233"
"2025-06-02T18:32:02","MystiC_Vibe","Success","54.225.130.151","success","United States","US","VA","Virginia","Ashburn","20149","39.0438","-77.4874","Amazon.com, Inc.","AWS EC2 (us-east-1)","AS14618 Amazon.com, Inc.","AMAZON-AES","False","False","True","54.225.130.151"
"2025-06-02T18:47:39","ShAdOwHuNtEr","Success","181.74.250.116","success","Chile","CL","RM","Santiago Metropolitan","Santiago","34033","-33.4521","-70.6536","Telmex Servicios Empresariales S.A.","Telmex Servicios Empresariales S.A","AS6535 Telmex Servicios Empresariales S.A.","Telmex Servicios Empresariales S.A.","False","False","False","181.74.250.116"
"2025-06-02T19:12:15","CosM1cDream","Success","24.63.15.145","success","United States","US","MA","Massachusetts","Watertown","02472","42.3725","-71.1814","Comcast Cable Communications","Comcast Cable Communications Holdings, Inc","AS7922 Comcast Cable Communications, LLC","COMCAST-7922","False","False","False","24.63.15.145"
"2025-06-02T19:38:48","SilentWh1sper","Success","158.94.115.57","success","United Kingdom","GB","ENG","England","Hendon","NW4 4BT","51.5893","-0.227971","Middlesex University","Middlesex University","","","False","False","False","158.94.115.57"
"2025-06-02T19:47:22","Fr0stFire","Success","65.248.78.165","success","United States","US","TX","Texas","San Angelo","76903","31.4712","-100.4385","Verizon Communications","MCI Communications Services, Inc. d/b/a Verizon Business","AS701 Verizon Business","UUNET","False","False","False","65.248.78.165"
```
