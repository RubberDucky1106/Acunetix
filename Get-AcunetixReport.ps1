Function Get-AcunetixReport
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
		$Server)
		)
	
	#retrieve all reports from the server
	$apiKey = "0123456789abcdefghijklmnopqrstuvwxyz"
	$webclient = New-Object System.Net.WebClient
	$webclient.Headers.Add("X-Auth","$apiKey")
	$webclient.Headers.Add("Content-Type","application/json")
	$reports = $webclient.DownloadString("https://$($server):3443/api/v1/reports") | ConvertFrom-Json
	$count = 0
	#iterate through the list of targets from the csv
	foreach ($target in $targets)
	{
		$count++
        Write-Progress -Activity 'Gathering Reports' -Status "Processing $($count) of $($targets.count) targets" -PercentComplete (($count/$targets.count) * 100)
		#iterate through the list of reports, comparing each target to each report
		foreach ($report in $($reports.reports))
		{
			#replace http with 80; or https as 443; (443;1.1.1.1). Join with colon on first/second index swapped (1.1.1.1:443)
			$cleanedReport = $report.source.description.replace("http://","80;").replace("https://","443;") -Join (":")
			#if the IP:Port is the same in target and report, 
			if ($target -eq $cleanedReport)
			{
				# view the downloads property from the reports and get the PDF, not the HTML
				$pdf = $report.download | where {$_ -like "*.pdf"}
				#need to extract Majcom from report.source.description (e.g. https://1.1.1.1;<MAJCOM>)
				$Majcom = $report.source.description.split(";")[1]
				# split the target on the colon, left side is IP, right side is port
				$ip = $target.split(":")[0]
				$port = $target.split(":")[1]
				#ultimately, file name will be called IP_PORT.pdf
				$fileName = $ip + "_" + $port + ".pdf"
				# use downloadfile method to download the pdf and save it on P:\
				$downloadFile = $webclient.DownloadFile("https://$($server):3443/$($pdf)", "\Reports\$Group\$fileName")
				$downloadFile | out-file $SKDirectory\"download responds.txt" -append #testing stuffs
			}
		}#end reports
	}#end targets
}
