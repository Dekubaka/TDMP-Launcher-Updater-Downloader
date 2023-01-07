# Created by Dekubaka
# Teardown game on Steam: https://store.steampowered.com/app/1167630/Teardown
# Teardown multiplayer mod launcher: https://github.com/TDMP-Team/TDMP-Launcher-Updater-Public/releases/latest



# Installing Microsoft Visual C++ 2015-2022 Redistributable (x64)
function InstallVisualC {
    $vc_Redist_URL = 'https://aka.ms/vs/17/release/vc_redist.x64.exe'

    $fileName = $(Split-Path -Path $vc_Redist_URL -Leaf)
    Write-Host "Downloading $fileName" -ForegroundColor Cyan

    $ProgressPreference = 'SilentlyContinue' # Hiding the download bars as they persist through the entire program
    Invoke-WebRequest -Method Get -Uri $vc_Redist_URL -OutFile $fileName -UseBasicParsing # UseBasicParsing is for computers that don't have or have never opened IE. Allows download.

    $fileExist = Test-Path -Path .\$fileName
    if ($fileExist -eq $True) {
        Write-Host "File downloaded" -ForegroundColor Green
        Write-Host "Intstalling... This may take awhile" -ForegroundColor Yellow
        Write-Verbose "If prompted, click yes to allow install. It might be at the bottom of your task bar" -Verbose

        Start-Process -Path .\$fileName -ArgumentList "/install /quiet /norestart" -wait
        Write-Host "Install finished" -ForegroundColor Green
        Write-Host "Cleaning up files" -ForegroundColor Cyan
        Remove-Item -Path $fileName

        Write-Host "Starting .NET Desktop Runtime Install" -ForegroundColor Cyan
        InstallDotNet
    }
    else {
        Write-Error -Message "There was a problem downloading the file. Check if you can reach the download link: $vc_Redist_URL."
        Pause
    }

    
}



function InstallDotNet {

    # The .NET Desktop Runtime also includes the .NET Runtime. Commenting this out.
    # $dotNET_7_URL = 'https://download.visualstudio.microsoft.com/download/pr/87bc5966-97cc-498c-8381-bff4c43aafc6/baca88b989e7d2871e989d33a667d8e9/dotnet-runtime-7.0.0-win-x64.exe'
    # $dotNET_7_Checksum = '937519b9479e1a5499e4ab807251c969ea9d4b5a5f80a7a74928b653f24f460d01445a144f084173bdae17da5ebd60ac641601ecd4c4e35c98f223da67be0d0e'

    $dotNET_7_Desktop_URL = 'https://download.visualstudio.microsoft.com/download/pr/5b2fbe00-507e-450e-8b52-43ab052aadf2/79d54c3a19ce3fce314f2367cf4e3b21/windowsdesktop-runtime-7.0.0-win-x64.exe'
    $dotNET_7_Desktop_Checksum = 'e6281f475a58c8dc7b103d0cfd895e0f27235e25731b473514c82b77d8e555ea294f66ab3e119c5fd38c5a8f18b4a4d8508938d7cff70ab2186b47417349ea1e'

    $fileName = $(Split-Path -Path $dotNET_7_Desktop_URL -Leaf)
    Write-Host "Downloading $fileName" -ForegroundColor Cyan

    $ProgressPreference = 'SilentlyContinue' # Hiding the download bars as they persist through the entire program
    Invoke-WebRequest -Method Get -Uri $dotNET_7_Desktop_URL -OutFile $fileName -UseBasicParsing

    $fileExist = Test-Path -Path .\$fileName
    if ($fileExist -eq $True) {
        Write-Host "File downloaded" -ForegroundColor Green
        Write-Host "Checking Hashbrowns.." -ForegroundColor Yellow

        $fileHash = Get-FileHash .\$fileName -Algorithm SHA512

        if ($dotNET_7_Desktop_Checksum -eq $fileHash.Hash) {
            Write-Host "Hashbrowns looking good" -ForegroundColor Green
            Write-Host "Intstalling..." -ForegroundColor Yellow
            Write-Verbose "If prompted, click yes to allow install. It might be at the bottom of your task bar" -Verbose
            
            Start-Process -Path .\$fileName -ArgumentList "/install /quiet /norestart" -wait
            Write-Host "Install finished" -ForegroundColor Green

            Write-Host "Cleaning up files" -ForegroundColor Cyan
            Remove-Item -Path $fileName

            Write-Host "Setting up TDMP Launcher" -ForegroundColor Cyan
            TDMPLauncherSetup

        } else {
            Write-Error -Message "Hashbrowns are NOT good. This could mean the downloaded file is corrupted"
            Pause
        }

    } else {
        Write-Error -Message "There was a problem downloading the file. Check if you can reach the download link: $dotNET_7_Desktop_URL."
        Pause
    }

    return
}



function TDMPLauncherSetup {
    Write-Host "Getting latest version from github" -ForegroundColor Cyan

    $latestReleaseURI = "https://github.com/TDMP-Team/TDMP-Launcher-Updater-Public/releases/latest"
    $latestRelease = Invoke-WebRequest -Method Get -Uri $latestReleaseURI  -Headers @{"Accept"="application/json"} -UseBasicParsing
    $latestVersion = ($latestRelease.Content | ConvertFrom-Json)."tag_name"
    Write-Host "Latest version is $latestVersion" -ForegroundColor Cyan

    Write-Host "Downloading zip..." -ForegroundColor Yellow
    $downloadUri = "https://github.com/TDMP-Team/TDMP-Launcher-Updater-Public/releases/download/$latestVersion/TDMP-Launcher-Updater-$latestVersion.zip"
    $fileName = $(Split-Path -Path $downloadUri -Leaf) # zip file name

    $ProgressPreference = 'SilentlyContinue' # Hiding the download bars as they persist through the entire program
    Invoke-WebRequest -Method Get -Uri $downloadUri -OutFile $fileName -UseBasicParsing
    Write-Host "Zip-a-Dee-Doo-Dah downloaded" -ForegroundColor Green

    Write-Host "Unzippping" -ForegroundColor Yellow
    Expand-Archive .\$fileName -Force # Overwriting zip file if already exists.
    
    $folderName = (Get-Item -Path .\$fileName).BaseName

    $folderExist = Test-Path -Path .\$folderName
    if ($folderExist -eq $false){
        Write-Error -Message "There was a problem unzipping your pan... I mean, the downloaded files. Please try again."
        Pause
        exit
    }

    Write-Host "Pants Unzipped..." -ForegroundColor Green
    Write-Verbose "Moving TDMP Launcher to your documents folder and creating a desktop shortcut" -Verbose

    $desktop = [environment]::getfolderpath("desktop")
    $documentsFolder = [environment]::getfolderpath("mydocuments")
    $documentsFolderExist = Test-Path -Path "$documentsFolder\$folderName" # Checking for TDMP folder
    if ($documentsFolderExist -eq $false){
        Move-Item -Path ".\$folderName\$folderName" -Destination $documentsFolder # Moving inner folder
        Write-Host "Folder moved" -ForegroundColor Green

        Write-Host "Creating desktop shortcut" -ForegroundColor Yellow
        $WshShell = New-Object -comObject WScript.Shell
        $Shortcut = $WshShell.CreateShortcut("$desktop\Teardown Multiplayer Launcher.lnk")
        $Shortcut.TargetPath = "$documentsFolder\$folderName\LauncherUpdater.exe"
        $Shortcut.WorkingDirectory = "$documentsFolder\$folderName"
        $Shortcut.Save()

        Write-Host "Cleaning up files" -ForegroundColor Cyan
        Remove-Item -Path $fileName 
        Remove-Item -Path $folderName -Recurse

        Write-Host "IT'S TIME TO TEARDOWN GAMER!" -ForegroundColor Green
        Start-Process -Path "$desktop\Teardown Multiplayer Launcher.lnk" # Start launcher from shortcut
        Start-Sleep -Duration 5
        

    } elseif ($folderExist -eq $true) {
        Write-Verbose "Looks like there is a teardown launcher folder already in your documents. If there is a problem then delete the folder and try again." -Verbose
        Start-Sleep -Duration 5

        Write-Host "Cleaning up files" -ForegroundColor Cyan
        Remove-Item -Path $fileName
        Remove-Item -Path $folderName -Recurse

        Write-Host "Updating Desktop Shortcut..." -ForegroundColor Yellow
        $WshShell = New-Object -comObject WScript.Shell
        $Shortcut = $WshShell.CreateShortcut("$desktop\Teardown Multiplayer Launcher.lnk")
        $Shortcut.TargetPath = "$documentsFolder\$folderName\LauncherUpdater.exe"
        $Shortcut.WorkingDirectory = "$documentsFolder\$folderName"
        $Shortcut.Save()

        Write-Host "IT'S TIME TO TEARDOWN GAMER!" -ForegroundColor Green
        Start-Process -Path "$desktop\Teardown Multiplayer Launcher.lnk"
        Start-Sleep -Duration 10
    }
    
    
}


# Script Start
Push-Location $PSScriptRoot

InstallVisualC

Pop-Location