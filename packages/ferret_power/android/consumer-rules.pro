# Started by class name: by Shizuku (the user service) and by app_process
# (the root helper). R8 can't see those uses.
-keep class io.sofluffy.ferret_power.shell.PowerShellService { *; }
-keep class io.sofluffy.ferret_power.shell.ShellMain { *; }
-keep class io.sofluffy.ferret_power.shell.IPowerShellService** { *; }
-keep class io.sofluffy.ferret_power.shell.IPowerClipListener** { *; }
-keep class android.content.IOnPrimaryClipChangedListener** { *; }
