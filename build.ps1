# Configure and build MrNutzRecomp on Windows.
#
# Windows is not a validated target for this port yet. The framework fetches
# SDL3 when no system package is found; set SDL3_DIR only to use a specific
# installation.
$ErrorActionPreference = 'Stop'

$Root = Split-Path -Parent $MyInvocation.MyCommand.Path
$BuildDir = if ($env:BUILD_DIR) { $env:BUILD_DIR } else { Join-Path $Root 'build' }
$BuildType = if ($env:CMAKE_BUILD_TYPE) { $env:CMAKE_BUILD_TYPE } else { 'Release' }

$Args = @('-S', $Root, '-B', $BuildDir, '-DCMAKE_BUILD_TYPE=' + $BuildType)
if ($env:SDL3_DIR) { $Args += '-DSDL3_DIR=' + $env:SDL3_DIR }

cmake @Args
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
cmake --build $BuildDir --config $BuildType --parallel
exit $LASTEXITCODE
