Function Clear-AcunetixGUI
{
[CmdletBinding(SupportsShouldProcess=$True,ConfirmImpact='Low')]
	param(
		[Parameter(ParameterSetName="p0",
		Mandatory=$false,
		ValueFromPipeline=$True,
		ValueFromPipelineByPropertyName=$True,
		Position=0)]
		$Server)
	
	$apiKey = "0123456789abcdefghijklmnopqrstuvwxyz"
	$webclient = New-Object System.Net.WebClient
	$webclient.Headers.Add("X-Auth","$apiKey")
	$webclient.Headers.Add("Content-Type","application/json")
	$reports = $webclient.DownloadString("https://$($server):3443/api/v1/reports") | ConvertFrom-Json		
	Foreach ($report in $($reports.reports))
	{
		$count++
		Write-Progress -Activity 'Removing Reports from Web Application' -Status "Processing $($count) of $($reports.reports.count) Scans" -PercentComplete (($count/$($reports.reports.count)) * 100)
		#delete reports 
		Invoke-WebRequest -Uri "https://$($server):3443/api/v1/reports/$($report.report_id)" -Method "DELETE" -ContentType "application/json" -Headers @{"X-Auth"="$apiKey"} | Out-Null
	}
	
	$count = 0
	#get list of targets and take response and convert to JSON object
	$targets = $webclient.DownloadString("https://$($server):3443/api/v1/targets") | ConvertFrom-Json		
	Foreach ($target in $($targets.targets))
	{
		$count++
		Write-Progress -Activity 'Removing Targets from Web Application' -Status "Processing $($count) of $($targets.targets.count) Scans" -PercentComplete (($count/$($targets.targets.count)) * 100)
		#delete targets (which also deletes scans)
		Invoke-WebRequest -Uri "https://$($server):3443/api/v1/targets/$($target.target_id)" -Method "DELETE" -ContentType "application/json" -Headers @{"X-Auth"="$apiKey"} | Out-Null
	}
}