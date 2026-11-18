package io.sofluffy.ferret_power.shell;

oneway interface IPowerClipListener {
    // `clip` holds "text" (String) and "sensitive" (boolean).
    void onClipChanged(in Bundle clip);
}
