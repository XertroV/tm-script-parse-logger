bool IsHooked = false;

void SetupNodHooks() {
    if (NodsToLoad.Length == 0) {
        PopulateNodsToLoad();
        yield();
    }
    IsHooked = true;
    for (uint i = 0; i < NodsToLoad.Length; i++) {
        AddHook(NodsToLoad[i]);
    }
    trace('Hooked nod loading for ' + LoadedHooks.GetSize() + ' nods');
}

void RemoveNodHooks() {
    if (!IsHooked) return;
    IsHooked = false;
    auto loaded = LoadedHooks.GetKeys();
    trace('Unhooking ' + loaded.Length + ' nods');
    for (uint i = 0; i < loaded.Length; i++) {
        RemHook(Text::ParseUInt(loaded[i]));
    }

}

dictionary LoadedHooks;

void AddHook(uint id) {
    RegisterLoadCallback(id);
    LoadedHooks[tostring(id)] = true;
}

void RemHook(uint id) {
    UnregisterLoadCallback(id);
    LoadedHooks.Delete(tostring(id));
}

uint[] NodsToLoad;

void PopulateNodsToLoad() {
    NodsToLoad.RemoveRange(0, NodsToLoad.Length);
    auto opJson = Json::FromFile(IO::FromDataFolder("OpenplanetNext.json"));
    auto nsJson = opJson["ns"];
    auto nss = nsJson.GetKeys();
    for (uint n = 0; n < nss.Length; n++) {
        yield();
        PopulateNodsToLoad_NsJson(nsJson[nss[n]]);
        trace("Loaded classes in namespace: " + nss[n]);
    }
    for (uint i = 0; i < ExtraClassIds.Length; i++) {
        NodsToLoad.InsertLast(ExtraClassIds[i]);
    }
    trace("Loaded " + NodsToLoad.Length + " nod types");
}

void PopulateNodsToLoad_NsJson(Json::Value@ classes) {
    auto names = classes.GetKeys();
    for (uint i = 0; i < names.Length; i++) {
        auto cls = classes[names[i]];
        if (!cls.HasKey("i")) continue;
        auto hexId = string(cls["i"]);
        uint32 id = ParseHexUint(hexId);
        NodsToLoad.InsertLast(id);
    }
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
