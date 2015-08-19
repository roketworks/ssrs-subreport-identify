Param([String]$reportserver,
[Boolean]$useDefaultCredentials=$true,
[String]$username="username",
[String]$password="password",
[String]$reportFolderPath, 
[String]$searchRecursive=$false)

$url = "http://$($reportserver)/reportserver/reportservice2005.asmx?WSDL";

# If not using windows authentication, authenticate with supplied username and password
if ($useDefaultCredentials -eq $false) {
    $credetials = New-Object -TypeName System.Management.Automation.PSCredential `
        -ArgumentList $username, (ConvertTo-SecureString $password -AsPlainText -Force)
}

# useDefaultCredentials true will use currenltly logged in Windows crendentials
if ($useDefaultCredentials -eq $true) {
    $ssrs = New-WebServiceProxy -uri $url -UseDefaultCredential
} else {
    $ssrs = New-WebServiceProxy -uri $url -Credential $credetials
}

$reports = $ssrs.ListChildren($reportFolderPath, $searchRecursive)

$reports | ForEach-Object {

    If ($_.Type -eq "Report") {

        $reportPath = $_.path
        $reportName = $_.Name

        Write-Host "Inspecting Report: " $reportPath

        $rdlFile = New-Object System.Xml.XmlDocument;
        [byte[]] $report = $ssrs.GetReportDefinition($reportPath);
        [System.IO.MemoryStream] $memStream = New-Object System.IO.MemoryStream(@(,$report));
        $rdlFile.Load($memStream);
  
        $rdlNodes = $rdlFile.SelectNodes("//*"); 

        $subreportCount = 0;

        for ($i = 0; $i -lt $rdlNodes.Count; $i++){

            if ($rdlNodes.Item($i).LocalName -eq "SubReport") {
                $subreportCount++;               
            }
        }

        Write-Host $subreportCount.ToString() " Subreports found"
        Write-Host ""
    }
}

