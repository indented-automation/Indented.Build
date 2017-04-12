class BuildTask {
    [String] $Name

    [BuildType]$Stage

    [ScriptBlock] $ValidWhen

    [Int32] $Order

    [ScriptBlock] $Implementation

    BuildTask([String] $name, [BuildType] $stage) {
        $this.Name = $name
        $this.Stage = $stage
    }
}