package io.sofluffy.ferret_power.shell;

import io.sofluffy.ferret_power.shell.IPowerClipListener;

// What Ferret may ask of its helper running as the shell user. A short, fixed
// list: there is no way to run an arbitrary command through it.
interface IPowerShellService {
    // Shizuku calls this transaction when the service must go away.
    void destroy() = 16777114;

    // The clipboard text of `userId` as "text" and "sensitive", or null.
    Bundle readClipboard(int userId) = 1;

    // Reports every copy to `listener`. False when the system refused.
    boolean watchClipboard(int userId, IPowerClipListener listener) = 2;

    void unwatchClipboard() = 3;

    // Runs one of the fixed commands in ShellGrants for `packageName`.
    boolean grant(String grant, String packageName, String listenerComponent) = 4;
}
