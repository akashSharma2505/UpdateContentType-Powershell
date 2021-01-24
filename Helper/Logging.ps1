# Going to check if the Logs folder exists, otherwise create it

$isAzure = $false
if (Test-Path variable:global:EXECUTION_CONTEXT_FUNCTIONDIRECTORY)
{
    # Path to directory in Azure
    $PSScriptRoot = $EXECUTION_CONTEXT_FUNCTIONDIRECTORY
    $isAzure = $true
}

$LOG_DIR = ($PSScriptRoot + "\_logs")

if ((Test-Path $LOG_DIR) -eq $false)
{
    mkdir $LOG_DIR | Out-Null
}

Function Write-LoggedMessage()
{
    param
    (
        [Parameter(Mandatory = $false)][string] $Text = [string]::Empty,
        [Parameter(Mandatory = $false)][ConsoleColor] $ForegroundColor = "White",
        [Parameter(Mandatory = $false)][Switch] $NoNewline	
    )

    if ($isAzure)
    {
        # Write to output (logging for Application Insights)
        Write-Output $Text
    }
    else
    {
        # Write to host
        if ($NoNewline)
        {
            Write-Host $Text -ForegroundColor $ForegroundColor -NoNewline
        }
        else
        {
            Write-Host $Text -ForegroundColor $ForegroundColor
        }
    }
    # Write to file
    if ($Script:WRITE_TO_FILE)
    {
        $Text = "[$([DateTime]::Now)]" + " " + $Text
        $Text | Out-File $Script:LOG_PATH -NoClobber -Append
    }
}


function Create-LogFile
{  
    param
    (
        [Parameter(Mandatory = $false)][string] $Text = [string]::Empty,
        [Parameter(Mandatory = $false)][string] $FileName = [string]::"SampleLogFile",
        [Parameter(Mandatory = $false)][ConsoleColor] $ForegroundColor = "White",
        [Parameter(Mandatory = $false)][Switch] $NoNewline	
    )

    # save the current color
    $fc = $host.UI.RawUI.ForegroundColor

    # set the new color
    $host.UI.RawUI.ForegroundColor = $ForegroundColor
    
    if ($isAzure)
    {
        # Write to output (logging for Application Insights)
        Write-Output $Text
    }
    else
    {
        # Write to host
        if ($NoNewline)
        {
            Write-Host $Text -ForegroundColor $ForegroundColor -NoNewline
        }
        else
        {
            Write-Host $Text -ForegroundColor $ForegroundColor
        }
    }
    #
    $Script:LOG_TAGID_PATH=$LOG_DIR + "\$FileName" + ".log"
    # Write to file
    if ($Script:WRITE_TO_FILE)
    {
        $Text = "[$([DateTime]::Now)]" + " " + $Text
        $Text | Out-File $Script:LOG_TAGID_PATH -NoClobber -Append
    }

    # restore the original color
    $host.UI.RawUI.ForegroundColor = $fc
}


Function Run
{
    param (
        [Parameter(Mandatory = $false)][string]$message,
        [Parameter(Mandatory = $false)][Scriptblock]$scriptBlock,
        [Parameter(Mandatory = $false)][switch]$noThrow
    )

    #Yellow: started
    #Green: success
    #Magenta: error
    #Red: exception
    $messageString=$message.Split(";")[0]
    $messageColor=$message.Split(";")[1]
    if ($messageString)
    {
        if ($scriptBlock)
        {
            if($messageColor){
            Write-LoggedMessage $messageString -ForegroundColor $messageColor -NoNewline
            }
            else{
            Write-LoggedMessage $messageString -ForegroundColor Yellow -NoNewline

            }
        }
        else
        {
            Write-LoggedMessage $messageString -ForegroundColor Yellow
            return
        }
    }
    
    $returnValue = [void]

    if ($scriptBlock)
    {
        if($message)
        {
            Write-LoggedMessage " ..." -ForegroundColor White -NoNewline
        }

        try
        {
            $returnValue = $scriptBlock.Invoke()
        }
        catch
        {
            $ex = $_.Exception
            while ($ex.InnerException)
            {
                $ex = $ex.InnerException
            }
            
            Write-LoggedMessage " Error" -ForegroundColor "Magenta"
            Write-LoggedMessage ("ErrorMessage: " + $ex.Message) -ForegroundColor "Red"
            Write-LoggedMessage ("ScriptStackTrace: " + $_.ScriptStackTrace) -ForegroundColor "Red"
            Write-LoggedMessage ("StackTrace: " + $ex.StackTrace) -ForegroundColor "Red"

            if ($noThrow)
            {
                return
            }
            else
            {
                throw $ex
            }
        }

        if ($message)
        {
            Write-LoggedMessage " Done!" -ForegroundColor Green
        }
    }

    if ($returnValue -ne [void])
    {
        return $returnValue
    }
}

Function Write-StartMessage()
{
    param
    (
        [Parameter(Mandatory = $true)][string]$ScriptVersion
    )

    "*********************************************************************************" | Out-File $Script:LOG_PATH
    "Started processing at [$([DateTime]::Now)]" | Out-File $Script:LOG_PATH -NoClobber -Append
    "*********************************************************************************" | Out-File $Script:LOG_PATH -NoClobber -Append
    "Running script version at [$ScriptVersion]" | Out-File $Script:LOG_PATH -NoClobber -Append
    "*********************************************************************************" | Out-File $Script:LOG_PATH -NoClobber -Append
    "Script executed by user [" + ($env:userdomain + "\" + $env:username) + "]" | Out-File $Script:LOG_PATH -NoClobber -Append
    "*********************************************************************************" | Out-File $Script:LOG_PATH -NoClobber -Append
    "" | Out-File $Script:LOG_PATH -NoClobber -Append
}

Function Write-EndMessage()
{
    param
    (
    )

    "" | Out-File $Script:LOG_PATH -NoClobber -Append
    "*********************************************************************************" | Out-File $Script:LOG_PATH -NoClobber -Append
    "Stopped processing at [$([DateTime]::Now)]" | Out-File $Script:LOG_PATH -NoClobber -Append
    "*********************************************************************************" | Out-File $Script:LOG_PATH -NoClobber -Append
} 

Function Initialize-Log()
{
    param
    (
        [Parameter(Mandatory = $false)][string]$LogPath,
        [Parameter(Mandatory = $false)][bool]$WriteToFile = $true
    )

    if ($LogPath)
    {
        $Script:LOG_PATH = $LogPath
    }
    else
    {
        $Script:LOG_PATH = $LOG_DIR + "\" + (Get-Date).ToString("yyyyMMdd-HHmmss") + ".log"
    }
    $Script:LOG_TAGID_PATH = $LOG_DIR + "\KopplingPlats_NOT_FOUND" + (Get-Date).ToString("yyyyMMdd-HHmmss") + ".log"
    $Script:WRITE_TO_FILE = $WriteToFile
}
