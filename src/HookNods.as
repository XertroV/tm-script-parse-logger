bool IsHooked {
    get {
        return HookScriptParsing.IsApplied();
    }
}

void SetupScriptParseHooks() {
    trace('Hooked script parsing');
    HookScriptParsing.Apply();
}

void RemoveHook() {
    trace('Unhooked script parsing');
    HookScriptParsing.Unapply();
}


uint64 ParseHexUint(const string &in ptr) {
    string _ptr = ptr.Trim().ToLower();
    if (_ptr.StartsWith("0x")) {
        _ptr = _ptr.SubStr(2);
    }
    uint64 r = 0;
    for (uint i = 0; i < _ptr.Length; i++) {
        auto c = _ptr[i];
        if (0x30 <= c && c <= 0x39) {
            r = (r << 4) + (c - 0x30);
        } else if (0x61 <= c && c <= 0x66) {
            r = (r << 4) + (c - 0x61 + 10);
        } else {
            warn('hex parse error for: ' + _ptr);
            throw('char at (' + i + ') out of range: ' + c);
        }
    }
    return r;
}
