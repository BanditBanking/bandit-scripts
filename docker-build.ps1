Function Get-WordsFromPascalCase {
    Param([Parameter(Mandatory=$true)] [string]$String)
    $Words = $String -CSplit "(?=[A-Z])"
    $Words = $Words | Where-Object { $_ }
    $Words = $Words | ForEach-Object { $_.ToLower() }
    return $Words
}

Function Convert-ToPascalCase {
    Param([Parameter(Mandatory=$true)] [string]$String)
    $Words = $String -Split "[-_\s]+"
    $Words = $Words | ForEach-Object { $_.Substring(0,1).ToUpper() + $_.Substring(1) }
    $String = $Words -Join ""
    return $String
}

Function Convert-ToCamelCase {
    Param([Parameter(Mandatory=$true, ValueFromPipeline=$true)] [string]$String)
    $Words = Get-WordsFromPascalCase -String $String
    $Words = $Words | ForEach-Object { $_.Substring(0,1).ToUpper() + $_.Substring(1) }
    $String = $Words -Join ""
    $String = $String.Substring(0,1).ToLower() + $String.Substring(1)
    return $String
}

Function Convert-ToKebabCase {
    Param([Parameter(Mandatory=$true)] [string]$String)
    $Words = Get-WordsFromPascalCase -String $String
    $String = $Words -Join "-"
    return $String
}

Function Convert-ToSnakeCase {
    Param([Parameter(Mandatory=$true)] [string]$String)
    $Words = Get-WordsFromPascalCase -String $String
    $String = $Words -Join "_"
    return $String
}

Function Get-ProjectNameFromDirectory {
    Param([Parameter(Mandatory=$false)] [string]$Type = "KebabCase")

    $CurrentDirectory = Get-Location
    while (!(Test-Path ".git")) {
        Set-Location ..
    }

    $ProjectDirectory = Get-Location
    Set-Location $CurrentDirectory

    $ProjectDirectory = $ProjectDirectory -split "\\"
    $ProjectDirectory = $ProjectDirectory[-1]

    $CamelCaseName = Convert-ToPascalCase -String $ProjectDirectory

    if ($Type -eq "CamelCase") {
        $ProjectDirectory = Convert-ToCamelCase -String $ProjectDirectory
    }   

    elseif ($Type -eq "SnakeCase") {
        $ProjectDirectory = Convert-ToSnakeCase -String $ProjectDirectory
    }

    elseif ($Type -eq "KebabCase") {
        $ProjectDirectory = Convert-ToKebabCase -String $ProjectDirectory
    }

    elseif ($Type -eq "PascalCase") {
        $ProjectDirectory = $CamelCaseName
    }

    return $ProjectDirectory
}

Function Get-ProjectNameFromFile {
    $ProjectName = Get-Content -Path "project-name.txt"
    return $ProjectName.Trim()
}

Function Get-ProjectName {
    if (Test-Path "project-name.txt") {
        return Get-ProjectNameFromFile
    }
    else {
        return Get-ProjectNameFromDirectory -Type "KebabCase"
    }
}

function Get-LastContainerImageVersion {
    param (
        [string]$RegistryUrl,
        [string]$Repository,
        [string]$ContainerName,
        [string]$Username,
        [string]$Password
    )

    $base64AuthInfo = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(("{0}:{1}" -f $Username,$Password)))
    $headers = @{ Authorization = "Basic $base64AuthInfo" }

    $url = "$RegistryUrl/v2/$Repository/$ContainerName/tags/list"
    $response = Invoke-RestMethod -Method Get -Uri $url -Headers $headers

    $tags = $response.tags
    $last_tag = $tags | Sort-Object -Descending | Select-Object -First 1

    if (!$last_tag -or $last_tag -eq "latest") {
        return "0.0.0"
    }

    return $last_tag
}

Function ReadVersionInput
{
    param (
        [string]$DefaultVersion
    )

    do {
        $ImageVersion = Read-Host "New image version [$DefaultVersion]"
        if ($ImageVersion -eq '') {
            $ImageVersion = $DefaultVersion
        }
    } until ($ImageVersion -match '^\d+\.\d+\.\d+$')

    return $ImageVersion
}

function Increment-VersionString {
    param (
        [string]$VersionString
    )

    $versionNumbers = $VersionString.Split('.')
    $lastNumber = [int]$versionNumbers[-1]
    $versionNumbers[-1] = ($lastNumber + 1).ToString()

    return $versionNumbers -join '.'
}

Function DisplayHelperBanner {
    param (
        [string]$ProjectName
    )


    Write-Host -ForegroundColor Blue "
    ██████╗  █████╗ ███╗   ██╗██████╗ ██╗████████╗
    ██╔══██╗██╔══██╗████╗  ██║██╔══██╗██║╚══██╔══╝
    ██████╔╝███████║██╔██╗ ██║██║  ██║██║   ██║   
    ██╔══██╗██╔══██║██║╚██╗██║██║  ██║██║   ██║   
    ██████╔╝██║  ██║██║ ╚████║██████╔╝██║   ██║   
    ╚═════╝ ╚═╝  ╚═╝╚═╝  ╚═══╝╚═════╝ ╚═╝   ╚═╝   
Banking Analytics Network for Data Insight and Telemetry
"
    Write-Host "Docker Manager for $ProjectName `r`n"
}

# Script
$ProjectName = Get-ProjectName

DisplayHelperBanner -ProjectName $ProjectName

Write-Host "Fetching $ProjectName last version..."

$LastVersion = Get-LastContainerImageVersion -RegistryUrl "https://registry.tristesse.lol" -Repository "p/masi-integratedproject/containers" -ContainerName $ProjectName -Username "bc3130e9-9cdd-43ce-9601-08280cf46780" -Password "eyJhbGciOiJSUzUxMiJ9.eyJzdWIiOiJiYzMxMzBlOS05Y2RkLTQzY2UtOTYwMS0wODI4MGNmNDY3ODAiLCJhdWQiOiJiYzMxMzBlOS05Y2RkLTQzY2UtOTYwMS0wODI4MGNmNDY3ODAiLCJvcmdEb21haW4iOiJzcGFjZSIsIm5hbWUiOiJTaGVsbCIsImlzcyI6Imh0dHBzOlwvXC9zcGFjZS50cmlzdGVzc2UubG9sIiwicGVybV90b2tlbiI6IjJOUEFubzN5Zm12dSIsInByaW5jaXBhbF90eXBlIjoiU0VSVklDRSIsImlhdCI6MTY3OTA2ODkwNH0.DE697Hniv9-9KUjqu7s4Maj2uOL_usB_07iAwIJMJGw7EJu3R6owVsuIITkS0CfIYj5dCZjMO8TIEeKaMYj4J_B3Ykvfq-WADi6uiD97o8zhWq8O5xL8M4IWNjTSqCxs1mFCGVtqp3v6EYdqPC5kwl2fQd9lt89sGEUss9Rmm4DYe58qDMgt7m3EDbMfltOoHtXim-HSITTjlEk6pWFa5wxt4dTGl7-H_ty2VjpnRq6yZI0sd9CgVc89XQOZPmIeU5eChheWEhRW5w4yX9n9qpnoDg4txxWFRQSU9FghREGG6GmXz_Vg79bQmxFUy3QhUDP1pB9PoB1U1DNB9epb1RA3jNgDdB6-yxPigLo2lyPXMfB-ssbeXd-vEgDNIvDf4l84QnteQyipmDRxCBeokJjXHRR1KCb-z1xk84q2JevsHyCcXD-3SValx7LEMsDDvklYg-Lt5OwpnTjX-sJ3iYxj5zglWcln79F9YhZg1TdBhHajrwvGcJTmwgq_8urGQBzzpCDQgDxdshLsxLbuR-ujbglM74sUo70WO8rkpGRXd59E5gNxnUl18A5Jnhd3peoIrS6BoT95y75EclhTT2fy-btfeZ0Jh7fDmlI3wgDIyd5b4macqgveyCLmEdFhzXUM3RofBgqedccJPW4dpSwLqAt3PvRrE85A_lrQMiU"

Start-Sleep -Seconds 1.5

cls 

DisplayHelperBanner

Write-Host "Last $ProjectName version : [$LastVersion]`r`n"

$DefaultVersion = Increment-VersionString -VersionString $LastVersion

$ImageVersion = ReadVersionInput -DefaultVersion $DefaultVersion

Write-Host "`r`n"

$DockerfilePath = Get-ChildItem -Recurse -Filter Dockerfile | Select-Object -First 1 -Property FullName

if (!$DockerfilePath) {
    Write-Error "No Dockerfile found"
}

cmd.exe /c docker build . -t registry.tristesse.lol/p/masi-integratedproject/containers/${ProjectName}:$ImageVersion -f $DockerfilePath.FullName

cmd.exe /c docker login registry.tristesse.lol -u="bc3130e9-9cdd-43ce-9601-08280cf46780" -p="eyJhbGciOiJSUzUxMiJ9.eyJzdWIiOiJiYzMxMzBlOS05Y2RkLTQzY2UtOTYwMS0wODI4MGNmNDY3ODAiLCJhdWQiOiJiYzMxMzBlOS05Y2RkLTQzY2UtOTYwMS0wODI4MGNmNDY3ODAiLCJvcmdEb21haW4iOiJzcGFjZSIsIm5hbWUiOiJTaGVsbCIsImlzcyI6Imh0dHBzOlwvXC9zcGFjZS50cmlzdGVzc2UubG9sIiwicGVybV90b2tlbiI6IjJOUEFubzN5Zm12dSIsInByaW5jaXBhbF90eXBlIjoiU0VSVklDRSIsImlhdCI6MTY3OTA2ODkwNH0.DE697Hniv9-9KUjqu7s4Maj2uOL_usB_07iAwIJMJGw7EJu3R6owVsuIITkS0CfIYj5dCZjMO8TIEeKaMYj4J_B3Ykvfq-WADi6uiD97o8zhWq8O5xL8M4IWNjTSqCxs1mFCGVtqp3v6EYdqPC5kwl2fQd9lt89sGEUss9Rmm4DYe58qDMgt7m3EDbMfltOoHtXim-HSITTjlEk6pWFa5wxt4dTGl7-H_ty2VjpnRq6yZI0sd9CgVc89XQOZPmIeU5eChheWEhRW5w4yX9n9qpnoDg4txxWFRQSU9FghREGG6GmXz_Vg79bQmxFUy3QhUDP1pB9PoB1U1DNB9epb1RA3jNgDdB6-yxPigLo2lyPXMfB-ssbeXd-vEgDNIvDf4l84QnteQyipmDRxCBeokJjXHRR1KCb-z1xk84q2JevsHyCcXD-3SValx7LEMsDDvklYg-Lt5OwpnTjX-sJ3iYxj5zglWcln79F9YhZg1TdBhHajrwvGcJTmwgq_8urGQBzzpCDQgDxdshLsxLbuR-ujbglM74sUo70WO8rkpGRXd59E5gNxnUl18A5Jnhd3peoIrS6BoT95y75EclhTT2fy-btfeZ0Jh7fDmlI3wgDIyd5b4macqgveyCLmEdFhzXUM3RofBgqedccJPW4dpSwLqAt3PvRrE85A_lrQMiU"

cmd.exe /c docker push registry.tristesse.lol/p/masi-integratedproject/containers/${ProjectName}:$ImageVersion

Write-Host -ForegroundColor Green "Image successfully published at registry.tristesse.lol/p/masi-integratedproject/containers/${ProjectName}:$ImageVersion`r`n"
Write-Host -NoNewLine 'Press any key to continue...';

$null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown');