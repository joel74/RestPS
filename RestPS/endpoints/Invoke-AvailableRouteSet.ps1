function Invoke-AvailableRouteSet
{
    <#
	.DESCRIPTION
		This function defines the available Routes (Rest Methods and Commands/Scripts).
	.EXAMPLE
        Invoke-AvailableRouteSet
	.NOTES
        This will return null.
    #>
    $script:Routes = @(
        @{
            'RequestType'    = 'GET'
            'RequestURL'     = '/proc'
            'RequestCommand' = 'Get-Process -ErrorAction SilentlyContinue | Select-Object -PropertyName ProcessName -ErrorAction SilentlyContinue'
        }
        @{
            'RequestType'    = 'GET'
            'RequestURL'     = '/endpoint/status'
            'RequestCommand' = 'return 1'
        }
        @{
            'RequestType'    = 'GET'
            'RequestURL'     = '/endpoint/routes'
            'RequestCommand' = "C:\RestPS\EndPoints\GET\Invoke-GetRoutes.ps1"
        }
        @{
            'RequestType'    = 'GET'
            'RequestURL'     = '/process'
            'RequestCommand' = 'C:\RestPS\endpoints\GET\Invoke-GetProcess.ps1'
        }
        @{
            'RequestType'    = 'PUT'
            'RequestURL'     = '/Service'
            'RequestCommand' = 'C:\RestPS\endpoints\PUT\Invoke-GetProcess.ps1'
        }
        @{
            'RequestType'    = 'POST'
            'RequestURL'     = '/data'
            'RequestCommand' = 'C:\RestPS\endpoints\POST\Invoke-GetProcess.ps1'
        }
        @{
            'RequestType'    = 'DELETE'
            'RequestURL'     = '/data'
            'RequestCommand' = 'C:\RestPS\endpoints\DELETE\Invoke-GetProcess.ps1'
        }
    )
}
Invoke-AvailableRouteSet