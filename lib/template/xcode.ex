defmodule DebugNIF.Template.Xcode do
  def generate(output_dir, cwd, erlexec, commands, user_commands, env) do
    project_workspace = Path.join([output_dir, "project.xcworkspace"])
    xcschemes_dir = Path.join([output_dir, "xcshareddata", "xcschemes"])
    xcschemes_dir_workspace = Path.join([project_workspace, "xcshareddata", "xcschemes"])
    test_xcscheme = Path.join([xcschemes_dir, "mix.xcscheme"])
    test_xcscheme_workspace = Path.join([xcschemes_dir_workspace, "mix.xcscheme"])
    pbxproj = Path.join([output_dir, "project.pbxproj"])

    with :ok <- File.mkdir_p(xcschemes_dir),
         :ok <- File.mkdir_p(xcschemes_dir_workspace),
         mix_xcscheme <- xcscheme(:mix, cwd, erlexec, commands, user_commands, env),
         :ok <- File.write(test_xcscheme, mix_xcscheme),
         :ok <- File.write(test_xcscheme_workspace, mix_xcscheme),
         :ok <- File.write(pbxproj, project_pbxproj()) do
      :ok
    else
      error -> error
    end
  end

  defp xcscheme(:mix, cwd, erlexec, commands, user_commands, env) do
    user_commands = Enum.join(user_commands, " ")
    user_commands_enabled =
      if String.length(user_commands) > 0 do
        "YES"
      else
        "NO"
      end
    """
    <?xml version="1.0" encoding="UTF-8"?>
    <Scheme
        LastUpgradeVersion = "1340"
        version = "1.3">
        <BuildAction
          parallelizeBuildables = "YES"
          buildImplicitDependencies = "YES">
          <BuildActionEntries>
              <BuildActionEntry
                buildForTesting = "YES"
                buildForRunning = "YES"
                buildForProfiling = "YES"
                buildForArchiving = "YES"
                buildForAnalyzing = "YES">
                <BuildableReference
                    BuildableIdentifier = "primary"
                    BlueprintIdentifier = "CCDCF61628A4AB3200211AF9"
                    BuildableName = "mix"
                    BlueprintName = "mix"
                    ReferencedContainer = "container:debug_nif.xcodeproj">
                </BuildableReference>
              </BuildActionEntry>
          </BuildActionEntries>
        </BuildAction>
        <TestAction
          buildConfiguration = "Debug"
          selectedDebuggerIdentifier = "Xcode.DebuggerFoundation.Debugger.LLDB"
          selectedLauncherIdentifier = "Xcode.DebuggerFoundation.Launcher.LLDB"
          shouldUseLaunchSchemeArgsEnv = "YES">
          <Testables>
          </Testables>
        </TestAction>
        <LaunchAction
          buildConfiguration = "Debug"
          selectedDebuggerIdentifier = "Xcode.DebuggerFoundation.Debugger.LLDB"
          selectedLauncherIdentifier = "Xcode.DebuggerFoundation.Launcher.LLDB"
          launchStyle = "0"
          useCustomWorkingDirectory = "YES"
          customWorkingDirectory = "#{cwd}"
          ignoresPersistentStateOnLaunch = "NO"
          debugDocumentVersioning = "YES"
          debugServiceExtension = "internal"
          allowLocationSimulation = "YES">
          <PathRunnable
              runnableDebuggingMode = "0"
              FilePath = "#{erlexec}">
          </PathRunnable>
          <CommandLineArguments>
              <CommandLineArgument
                argument = "#{Enum.join(commands, " ")}"
                isEnabled = "YES">
              </CommandLineArgument>
              <CommandLineArgument
                argument = "#{user_commands}"
                isEnabled = "#{user_commands_enabled}">
              </CommandLineArgument>
          </CommandLineArguments>
          <EnvironmentVariables>
              <EnvironmentVariable
                key = "ROOTDIR"
                value = "#{env["ROOTDIR"]}"
                isEnabled = "YES">
              </EnvironmentVariable>
              <EnvironmentVariable
                key = "EMU"
                value = "#{env["EMU"]}"
                isEnabled = "YES">
              </EnvironmentVariable>
              <EnvironmentVariable
                key = "BINDIR"
                value = "#{env["BINDIR"]}"
                isEnabled = "YES">
              </EnvironmentVariable>
              <EnvironmentVariable
                key = "START_BOOT"
                value = "#{env["START_BOOT"]}"
                isEnabled = "YES">
              </EnvironmentVariable>
          </EnvironmentVariables>
        </LaunchAction>
        <ProfileAction
          buildConfiguration = "Release"
          shouldUseLaunchSchemeArgsEnv = "YES"
          savedToolIdentifier = ""
          useCustomWorkingDirectory = "NO"
          debugDocumentVersioning = "YES">
          <MacroExpansion>
              <BuildableReference
                BuildableIdentifier = "primary"
                BlueprintIdentifier = "CCDCF61628A4AB3200211AF9"
                BuildableName = "mix"
                BlueprintName = "mix"
                ReferencedContainer = "container:debug_nif.xcodeproj">
              </BuildableReference>
          </MacroExpansion>
        </ProfileAction>
        <AnalyzeAction
          buildConfiguration = "Debug">
        </AnalyzeAction>
        <ArchiveAction
          buildConfiguration = "Release"
          revealArchiveInOrganizer = "YES">
        </ArchiveAction>
    </Scheme>
    """
  end

  defp project_pbxproj do
    """
    // !$*UTF8*$!
    {
      archiveVersion = 1;
      classes = {
      };
      objectVersion = 55;
      objects = {

    /* Begin PBXAggregateTarget section */
        CCDCF61628A4AB3200211AF9 /* mix */ = {
          isa = PBXAggregateTarget;
          buildConfigurationList = CCDCF61728A4AB3200211AF9 /* Build configuration list for PBXAggregateTarget "mix" */;
          buildPhases = (
          );
          dependencies = (
          );
          name = "mix";
          productName = "mix";
        };
    /* End PBXAggregateTarget section */

    /* Begin PBXGroup section */
        CCDCF60F28A4AAEA00211AF9 = {
          isa = PBXGroup;
          children = (
          );
          sourceTree = "<group>";
        };
    /* End PBXGroup section */

    /* Begin PBXProject section */
        CCDCF61028A4AAEA00211AF9 /* Project object */ = {
          isa = PBXProject;
          attributes = {
            BuildIndependentTargetsInParallel = 1;
            LastUpgradeCheck = 1340;
            TargetAttributes = {
              CCDCF61628A4AB3200211AF9 = {
                CreatedOnToolsVersion = 13.4.1;
              };
            };
          };
          buildConfigurationList = CCDCF61328A4AAEA00211AF9 /* Build configuration list for PBXProject "debug_nif" */;
          compatibilityVersion = "Xcode 13.0";
          developmentRegion = en;
          hasScannedForEncodings = 0;
          knownRegions = (
            en,
            Base,
          );
          mainGroup = CCDCF60F28A4AAEA00211AF9;
          projectDirPath = "";
          projectRoot = "";
          targets = (
            CCDCF61628A4AB3200211AF9 /* mix */,
          );
        };
    /* End PBXProject section */

    /* Begin XCBuildConfiguration section */
        CCDCF61428A4AAEA00211AF9 /* Debug */ = {
          isa = XCBuildConfiguration;
          buildSettings = {
          };
          name = Debug;
        };
        CCDCF61528A4AAEA00211AF9 /* Release */ = {
          isa = XCBuildConfiguration;
          buildSettings = {
          };
          name = Release;
        };
        CCDCF61828A4AB3200211AF9 /* Debug */ = {
          isa = XCBuildConfiguration;
          buildSettings = {
            CODE_SIGN_STYLE = Automatic;
            PRODUCT_NAME = "$(TARGET_NAME)";
          };
          name = Debug;
        };
        CCDCF61928A4AB3200211AF9 /* Release */ = {
          isa = XCBuildConfiguration;
          buildSettings = {
            CODE_SIGN_STYLE = Automatic;
            PRODUCT_NAME = "$(TARGET_NAME)";
          };
          name = Release;
        };
    /* End XCBuildConfiguration section */

    /* Begin XCConfigurationList section */
        CCDCF61328A4AAEA00211AF9 /* Build configuration list for PBXProject "debug_nif" */ = {
          isa = XCConfigurationList;
          buildConfigurations = (
            CCDCF61428A4AAEA00211AF9 /* Debug */,
            CCDCF61528A4AAEA00211AF9 /* Release */,
          );
          defaultConfigurationIsVisible = 0;
          defaultConfigurationName = Release;
        };
        CCDCF61728A4AB3200211AF9 /* Build configuration list for PBXAggregateTarget "mix" */ = {
          isa = XCConfigurationList;
          buildConfigurations = (
            CCDCF61828A4AB3200211AF9 /* Debug */,
            CCDCF61928A4AB3200211AF9 /* Release */,
          );
          defaultConfigurationIsVisible = 0;
          defaultConfigurationName = Release;
        };
    /* End XCConfigurationList section */
      };
      rootObject = CCDCF61028A4AAEA00211AF9 /* Project object */;
    }
    """
  end
end
