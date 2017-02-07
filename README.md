# Indented.Build

Indented.Build is a build script generator for PowerShell modules. The goals of the generator are as follows:

1. Creates optionally updatable build scripts.
2. Updates (or can update) existing build scripts.
3. Does not increase the number of required modules.

The following modules are required by generated scripts:

* Configuration
* Pester
* PSScriptAnalyzer