[AttributeUsage([AttributeTargets]::Class, Inherited = $false)]
class BuildStep : Attribute {
    [BuildType] $BuildType
    [Int32] $Order = 255

    BuildStep([BuildType]$BuildType) {
        $this.BuildType = $BuildType
    }

    BuildStep([BuildType]$BuildType, [Int32]$Order) {
        $this.BuildType = $BuildType
        $this.Order = $Order
    }
}