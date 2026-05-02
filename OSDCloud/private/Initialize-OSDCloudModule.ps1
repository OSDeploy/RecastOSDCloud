function Initialize-OSDCloudModule {
    <#
    .SYNOPSIS
        Initializes the OSDeployWinPEDrivers functions by applying PSDefaultParameterValues.

    .DESCRIPTION
        Applies a two-layer PSDefaultParameterValues system at module load time:

        Layer 1 - Module defaults: flat key-value pairs in default.json (module root)
        Layer 2 - User overrides:  $script:OSDCloudUserPSDefaultParameterValuesPath (cache\osdeploywinpedrivers\default.json)

        The user override file is loaded last, so any key it defines overwrites the module
        default for the same key. Keys present only in the module defaults are unaffected.

        Single-line (//) and block (/* */) comments are stripped before parsing so that
        annotated JSON files are supported.

    .INPUTS
        None. This function does not accept pipeline input.

    .OUTPUTS
        None.

    .NOTES
        Author:  David Segura
        Company: Recast Software
        Change Summary:
        - Initial implementation of two-layer PSDefaultParameterValues loading.
        - Layer 1 source moved from module.json into default.json (flat key-value structure).
        - Layer 2 path changed to $script:OSDCloudUserPSDefaultParameterValuesPath.
    #>
    [CmdletBinding()]
    param ()

    # Path to the user-scoped PSDefaultParameterValues
    $script:OSDCloudUserPSDefaultParameterValuesPath = 'X:\PSDefaultParameterValues.json'

    Set-OSDCloudPSDefaultParameterValues -ModuleDefaultsPath $script:OSDCloudPSDefaultParameterValuesPath -UserDefaultsPath $script:OSDCloudUserPSDefaultParameterValuesPath
}
