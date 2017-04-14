class BuildTask {
    [String]$Name

    [BuildType]$Stage

    [ScriptBlock]$ValidWhen = { $true }

    [Int32]$Order = 1024

    [ScriptBlock]$Implementation

    BuildTask([String]$name, [BuildType]$stage) {
        $this.Name = $name
        $this.Stage = $stage
    }
}