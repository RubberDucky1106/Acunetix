Function Acunetix_GetVulnerabilities
{
	[CmdletBinding(SupportsShouldProcess=$True,ConfirmImpact='Low')]
	param(
		[Parameter(ParameterSetName="p0",
		Mandatory=$true,
		ValueFromPipeline=$True,
		ValueFromPipelineByPropertyName=$True,
		Position=0)]
		$group,
		
		[Parameter(ParameterSetName="p0",
		Mandatory=$true,
		ValueFromPipeline=$True,
		ValueFromPipelineByPropertyName=$True,
		Position=0)]
		[ValidateSet("JAN","FEB","MAR","APR","MAY","JUN","JUL","AUG","SEP","OCT","NOV","DEC")]
		$month,
		
		[Parameter(ParameterSetName="p0",
		Mandatory=$true,
		ValueFromPipeline=$True,
		ValueFromPipelineByPropertyName=$True,
		Position=0)]
		[ValidatePattern("[0-9]{4}")] 
		$yyyy,
		
		[Parameter(ParameterSetName="p0",
		Mandatory=$true,
		ValueFromPipeline=$True,
		ValueFromPipelineByPropertyName=$True,
		Position=0)]
		$Server)
		)
		

	$mm = [int]($([datetime]::ParseExact($month, "MMM", $null)) | Get-Date -Format "MM")
	
	$apiKey = "0123456789abcdefghijklmnopqrstuvwxyz"
	$webclient = New-Object System.Net.WebClient
	$webclient.Headers.Add("X-Auth","$apiKey")
	$webclient.Headers.Add("Content-Type","application/json")
	$scans = $webclient.DownloadString("https://$($server):3443/api/v1/scans") | ConvertFrom-Json

	if ($($scans.scans.count) -eq 0)
	{
		Write-Host "$Server does not have any scans."
		Exit
	}
		
	#create object to contain results
	$resultList = @()
	$count = 0
	#iterate through the list of scans
	foreach ($scan in $($scans.scans))
	{
		$count++
		Write-Progress -Activity 'Processing Vulnerabilities' -Status "Processing $($count) of $($scans.scans.count) scans" -PercentComplete (($count/$($scans.scans.count)) * 100)
		#retrieve the resultID
		$scanResults = $webclient.DownloadString("https://$($server):3443/api/v1/scans/$($scan.scan_id)/results") | ConvertFrom-Json
		$resultId = $scanResults.results.result_id
		#use the resultID to retrieve all vulnerabilities from the scan
		$scanVulnResults = $webclient.DownloadString("https://$($server):3443/api/v1/scans/$($scan.scan_id)/results/$($resultID)/vulnerabilities") | ConvertFrom-Json
		#iterate through all vulnerabilities
		foreach ($vuln  in $($scanVulnResults.vulnerabilities))
		{
			# 0=info, 1=low, 2=med, 3=high
			# if vuln severity is not informational
			if ($vuln.severity -ne 0)
			{
				#if affected url contains https, port is 443
				if (($vuln.affects_url) -like "https://*")
				{
					$port = "443"
				}
				#if the affected url matches on https, port is 80
				elseif (($vuln.affects_url) -like "http://*")
				{
					$port = "80"
				}
				#extract IP from the affected URL. 
				#input -> output = https://1.1.1.1/dir/file.aspx ->  1.1.1.1
				$ip = $vuln.affects_url.replace("http://","").replace("https://","").split("/")[0]
				#create a temporary object
				$row = New-Object -TypeName PSObject
				#add necessary fields (i.e. ip/port and vuln name)
				$row | Add-Member -MemberType NoteProperty -Name "IP:Port" -Value $IP':'$Port
				$row | Add-Member -MemberType NoteProperty -Name "Vuln Name" -Value $($vuln.vt_name)
				#dump temp object into object created outside of loop
				$resultList += $row
			}
		}#end of vulns
	
		#append the object to a csv containing every server's findings
		$resultList | Select-Object -Property "IP:Port","Vuln Name" -Unique | Export-Csv -Path ("Scan Saves\$Group\Group"+ $Group + "_Findings_API.csv") -NoTypeInformation -Append	
	}
}