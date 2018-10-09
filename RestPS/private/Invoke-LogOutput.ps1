function Invoke-LogOutput
{
    <#
	.DESCRIPTION
		This function will log output back to the Client.
	.EXAMPLE
        Invoke-StreamOutput
	.NOTES
        This will log the data sent. Eventually it will log the listener responses.
    #>
    # Process the Return data and log it.
    $script:result | ConvertTo-Json | out-file $Script:LogsPath\RequestContent.log -Append
    
}