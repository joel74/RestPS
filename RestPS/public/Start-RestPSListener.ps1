function Start-RestPSListener
{
    <#
	.DESCRIPTION
        Start a HTTP listener on a specified port.
    .PARAMETER Port
        A Port can be specified, but is not required, Default is 8080.
    .PARAMETER SSLThumbprint
        A SSLThumbprint can be specified, but is not required.
    .PARAMETER RestPSLocalRoot
        A RestPSLocalRoot be specified, but is not required. Default is c:\RestPS
    .PARAMETER AppGuid
        A AppGuid can be specified, but is not required.
    .PARAMETER VerificationType
        A VerificationType is optional - Accepted values are:
            -"VerifyRootCA": Verifies the Root CA of the Server and Client Cert Match.
            -"VerifySubject": Verifies the Root CA, and the Client is on a User provide ACL.
            -"VerifyUserAuth": Provides an option for Advanced Authentication, plus the RootCA,Subject Checks.
    .PARAMETER RoutesFilePath
        A Custom Routes file can be specified, but is not required, default is included in the module.
	.EXAMPLE
        Start-RestPSListener
    .EXAMPLE
        Start-RestPSListener -Port 8081
    .EXAMPLE
        Start-RestPSListener -Port 8081 -RoutesFilePath C:\temp\customRoutes.ps1
    .EXAMPLE
        Start-RestPSListener -RoutesFilePath C:\temp\customRoutes.ps1
    .EXAMPLE
        Start-RestPSListener -RoutesFilePath C:\temp\customRoutes.ps1 -VerificationType VerifyRootCA -SSLThumbprint $Thumb -AppGuid $Guid
	.NOTES
		No notes at this time.
    #>
    [CmdletBinding(
        SupportsShouldProcess = $true,
        ConfirmImpact = "Low"
    )]
    [OutputType([boolean])]
    [OutputType([Hashtable])]
    [OutputType([String])]
    param(
        [Parameter()][String]$RoutesFilePath = "null",
        [Parameter()][String]$RestPSLocalRoot = "c:\RestPS",
        [Parameter()][String]$Port = 8080,
        [Parameter()][String]$SSLThumbprint,
        [Parameter()][String]$AppGuid = ((New-Guid).Guid),
        [ValidateSet("VerifyRootCA", "VerifySubject", "VerifyUserAuth")]
        [Parameter()][String]$VerificationType,
		[Parameter()][Switch]$EnableLogging
	)
    # Set a few Flags
    $script:Status = $true
    $script:ValidateClient = $true
    if ($pscmdlet.ShouldProcess("Starting HTTP Listener."))
    {
        $script:listener = New-Object System.Net.HttpListener
        Invoke-StartListener -Port $Port -SSLThumbPrint $SSLThumbprint -AppGuid $AppGuid
        # Run until you send a GET request to /shutdown
        Do
        {
            # Capture requests as they come in (not Asyncronous)
            # Routes can be configured to be Asyncronous in Nature.
            $script:Request = Invoke-GetContext
            $script:ProcessRequest = $true
            $script:result = $null

            # Perform Client Verification if SSLThumbprint is present and a Verification Method is specified
            if ($VerificationType -ne "")
            {
                Get-ClientCertInfo
                $msg = "Validating Client CN: $script:SubjectName"
                Write-Output $msg
                $msg | Out-File $Script:LogsPath\Listener.log -Append
                $script:ProcessRequest = (Invoke-ValidateClient -VerificationType $VerificationType -RestPSLocalRoot $RestPSLocalRoot)
            }
            else
            {
                $msg = "Not Validating Client"
                Write-Output $msg
                $msg | Out-File $Script:LogsPath\Listener.log -Append
                $script:ProcessRequest = $true
            }

            # Determine if a Body was sent with the Client request
            $script:Body = Invoke-GetBody

            # Request Handler Data
            $RequestType = $script:Request.HttpMethod
            $RawRequestURL = $script:Request.RawUrl
            # Specific args will need to be parsed in the Route commands/scripts
            $RequestURL, $RequestArgs = $RawRequestURL.split("?")

            if ($script:ProcessRequest -eq $true)
            {


                # Break from loop if GET request sent to /shutdown
                if ($RequestURL -match '/EndPoint/Shutdown$')
                {
                    $msg = "Received Request to shutdown Endpoint."
                    Write-Output $msg
                    $msg | Out-File $Script:LogsPath\Listener.log -Append
                    $script:result = "Shutting down ReST Endpoint."
                    $script:Status = $false
                    $script:HttpCode = 200
                }
                else
                {
                    # Attempt to process the Request.
                    $msg = "Processing RequestType: $RequestType URL: $RequestURL Args: $RequestArgs"
#                    Write-Output $msg
                    $msg | Out-File $Script:LogsPath\Listener.log -Append


                    $checkedDate = Get-Date -format "dd-MMM-yyyy HH:mm:ss"
                    $msg = "Started processing: $checkedDate"
 #                   Write-Output $msg
                    $msg | Out-File $Script:LogsPath\Listener.log -Append

                    if ($RoutesFilePath -eq "null")
                    {
                        $RoutesFilePath = "Invoke-AvailableRouteSet"
                    }
                    $script:result = Invoke-RequestRouter -RequestType "$RequestType" -RequestURL "$RequestURL" -RoutesFilePath "$RoutesFilePath" -RequestArgs "$RequestArgs"
                }
            }
            else
            {
                $msg = "Not Processing RequestType: $RequestType URL: $RequestURL Args: $RequestArgs"
#                Write-Output $msg
                $msg | Out-File $Script:LogsPath\Listener.log -Append
                $script:result = "401 Client failed Verification or Authentication"
            }
            # Setup a placeholder to deliver a response
            $script:Response = $script:context.Response
            # Convert the returned data to JSON and set the HTTP content type to JSON
            $script:Response.ContentType = 'application/json'
            $script:Response.StatusCode = 200
			
			# If the EnableLogging switch is set, log output
            # Otherwise, stream it back to requestor.
			if ($EnableLogging){
				Invoke-LogOutput
			}
			else {
				Invoke-StreamOutput
			}
        } while ($script:Status -eq $true)
        #Terminate the listener
        Invoke-StopListener -Port $Port
        "Listener Stopped" | Out-File $Script:LogsPath\Listener.log -Append
        # Write-Output "Listener Stopped"
    }
    else
    {
        # -WhatIf was used.
        return $false
    }
}