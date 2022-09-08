[CmdletBinding()]
param (
    [Parameter(Mandatory)]
    [ValidateScript({ Test-Path $_ -PathType Container || Throw '-ModPath must be a directory' })]
    [string]
    $ModPath,

    [Parameter(Mandatory)]
    [string]
    $KeyName,

    [Parameter()]
    [ValidateScript({ Test-Path $_ -PathType Container || Throw '-ArmaToolsPath must be a directory' })]
    [string]
    $ArmaToolsPath = ${env:ARMA3TOOLS}
)

Begin {
    # Verify DSCreateKey is found
    $dsCreateKeyExe = Join-Path -Path ${ArmaToolsPath} -ChildPath 'DSSignFile/DSCreateKey.exe'
    if (-Not (Test-Path -Path $dsCreateKeyExe -PathType Leaf)) {
        Throw 'DSCreateKey.exe not found'
    }

    # Verify DSSignFile is found
    $dsSignExe = Join-Path -Path ${ArmaToolsPath} -ChildPath 'DSSignFile/DSSignFile.exe'
    if (-Not (Test-Path -Path $dsSignExe -PathType Leaf)) {
        Throw 'DSSignFile.exe not found'
    }
}

Process {
    # Create key pair
    & $dsCreateKeyExe ${KeyName}
    $publicKey = ./${KeyName}.bikey
    $privateKey = ./${KeyName}.biprivatekey
    Test-Path $publicKey -PathType Leaf || Test-Path $privateKey -PathType Leaf || Throw 'Keypair creation failed'

    # Sign pbo files
    Get-ChildItem ${ModPath} -Filter *.pbo -Recurse | ForEach-Object {
        & $dsSignExe $privateKey $_.FullName  
    }

    # Copy public key
    New-Item -ItemType 'directory' ${ModPath}/keys -Force | Out-Null
    Move-Item $publicKey ${ModPath}/keys
}

End {
    # Force delete private key
    Remove-Item $privateKey -Force
}