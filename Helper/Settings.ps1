Function DQC-LoadSettings
{
    param(
        $path
    )

    $config = Run "Loading settings" { Get-Content -Raw -Path $path | ConvertFrom-Json }
    DQC-SetGlobalVariables $config ""
}

Function DQC-SetGlobalVariables
{
    param(
        $obj,
        [string]$parentName
    )

    if ($obj.GetType().Name -ne "PSCustomObject")
    {
        Set-Variable -Name $parentName -Value $obj -Scope Global
        return
    }

    foreach($subObj in $obj.PSObject.Properties)
    {
        DQC-SetGlobalVariables $subObj.Value ($parentName + $subObj.Name)
    }
}
