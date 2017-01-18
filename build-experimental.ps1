#Requires -Module Configuration, PSScriptAnalyzer

using namespace System.Management.Automation.Language

if (-not ('BuildStep' -as [Type])) {
    Add-Type '
        using System;

        [AttributeUsage(AttributeTargets.Method)]
        public class BuildStep : Attribute
        {
            public string Name;

            public BuildStep(string Name)
            {
                this.Name = Name;
            }
        }
    '
}

enum BuildType {
    Build          = 1
    BuildTest      = 2
    FunctionalTest = 3
    Release        = 4
}

enum ReleaseType {
    Build = 1
    Minor = 2
    Major = 3
}

class Build {
    #
    # Fields
    #

    Hidden [String]$Nuget
    Hidden [String]$NugetApiKey

    #
    # Properties
    #

    [String]$ModuleName
    [Version]$Version = '0.0.1'
    [BuildType]$BuildType = 'Build'
    [ReleaseType]$ReleaseType = 'Build'
    [String]$PSRepository = 'PSGallery'
        
    #
    # Constructor
    # 

    Build() {
        $this.ModuleName = (Get-Item $psscriptroot).Parent.GetDirectories((Split-Path $psscriptroot -Leaf)).Name
        $this.Nuget = "$psscriptroot\..\BuildTools\nuget.exe"
    }

    #
    # Methods
    #

    # Public

    # Runs the build
    Invoke() {

    }

    # Private

    Hidden ImportMetadata() {

    }

    Hidden GetSteps() {

    }

    # Build steps

    [BuildStep('Build')]
    Clean() {

    }
}