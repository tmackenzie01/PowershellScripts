$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path) -replace '\.Tests\.', '.'
#Actual script is a couple of levels up
$sut = "..\..\$sut"
. "$here\$sut"

Write-Host $here
Write-Host $sut
Describe "InstallSetups" {
    It "outputs 'Loading data...'" {
        .\..\..\InstallSetups | Should Be 'No versions found'
    }
}
