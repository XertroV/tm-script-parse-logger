const string HOOK_PARSE_PATTERN = "48 8B 84 24 ?? ?? 00 00 48 8B 8C 24 ?? ?? 00 00 48 89 44 24 ?? 8B";

HookHelper@ HookScriptParsing = HookHelper(
    HOOK_PARSE_PATTERN, 0, 3, "OnHook_ScriptParse"
);

// Stack pointer at r14 to ptr to the script as a string.
void OnHook_ScriptParse(uint64 r14) {
    trace('on script parse hook: ' + Text::FormatPointer(r14));
    if (r14 == 0) {
        warn('[CRIT | Hook_ScriptParse] r14 is 0');
        return;
    }
    // since r14 is a stack pointer, we expect it to be in a certain range
    if (!IsStackPtrOkay(r14)) return;
    auto ptr = Dev::ReadUInt64(r14);
    if (!IsHeapPtrOkay(ptr)) return;
    auto length = Dev::ReadUInt32(r14 + 0x8);
    if (length == 0) return;
    if (length > 0x0FFFFF) {
        warn('[ERROR | Hook_ScriptParse] script length is > 1MB');
        return;
    }
    string theScript = Dev::ReadCString(ptr, length);
    LogParsedScript(theScript);
}

bool IsHeapPtrOkay(uint64 ptr) {
    if (ptr < 0xFFEEEEDDDD) {
        warn('[CRIT | Hook_ScriptParse] heap ptr is < 0xFFEEEEDDDD');
        return false;
    }
    if (ptr > 0x4FFEEEEDDDD) {
        warn('[CRIT | Hook_ScriptParse] heap ptr is > 0x4FFEEEEDDDD');
        return false;
    }
    return true;

}

bool IsStackPtrOkay(uint64 ptr) {
    // since this is a stack pointer, we expect it to be in a certain range
    if (ptr < 0xFEEEEDDDD) {
        warn('[CRIT | Hook_ScriptParse] stack ptr is < 0xFEEEEDDDD');
        return false;
    }
    if (ptr > 0xFFEEEEDDDD) {
        warn('[CRIT | Hook_ScriptParse] stack ptr is > 0xFFEEEEDDDD');
        return false;
    }
    return true;
}
