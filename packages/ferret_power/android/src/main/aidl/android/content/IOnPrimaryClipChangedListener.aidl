package android.content;

// Mirrors the hidden framework interface, so the shell helper can register a
// clipboard listener with the system's clipboard service. At runtime the
// framework's own class is the one that loads.
oneway interface IOnPrimaryClipChangedListener {
    void dispatchPrimaryClipChanged();
}
