/*
48 89 85 00 01 00 00 48 8B 85 80 01 00 00 48 8B DA 4C 8B AD 88 01 00 00 48 8B B5 90 01 00 00 48 89 45 A8 65 48 8B 04 25 58 00 00 00 4C 89 4C 24 78 4C 89 45 80 48 89 55 B8 48 8B 38 B8 10 00 00 00 48 89 4C 24 70 4C 89 6D B0 48 89 75 C0 80 3C 38 00 75 05 E8 53 FF CE 00 BA 50 01 00 00 48 8D 4D 00 48 03 D7 E8 52 72 90 FF 33 FF 48 8D 15 69 FC 36 01

param_2 rdx:
->
    + 0x0, struct vtable? near script stuff
    + 0x8, ptr

r8: ptr to string

rbp
+ 0x180 -> addr of string: name of script
+ 0x188 -> some flags 01 01 00 00
+ 0x190 -> ptr to werid offset (output?)

+ 0x1E0 = where r8 pointed to

*/
HookHelper@ Hook_Script_Compilation = HookHelper(
    "48 89 85 00 01 00 00 48 8B 85 80 01 00 00 48 8B DA 4C 8B AD 88 01 00 00 48 8B B5 90 01 00 00 48 89 45 A8 65 48 8B 04 25 58 00 00 00 4C 89 4C 24 78 4C 89 45 80 48 89 55 B8 48 8B 38 B8 10 00 00 00 48 89 4C 24 70 4C 89 6D B0 48 89 75 C0 80 3C 38 00 75 05 E8 53 FF CE 00 BA 50 01 00 00 48 8D 4D 00 48 03 D7 E8 52 72 90 FF 33 FF 48 8D 15 69 FC 36 01",
    0, 2, "On_Script_Compilation_Hook"
);

// r8 -> script, rbp+0x180 ->> script name
void On_Script_Compilation_Hook(uint64 r8, uint64 rbp) {
    trace('on script compilation hook - r8, rbp: ' + Text::FormatPointer(r8) + ", " + Text::FormatPointer(rbp));
    if (r8 == 0 || rbp == 0) {
        warn('[CRIT | Hook_Script_Compilation] r8 / rbp is 0');
        return;
    }
    // since r8 is a stack pointer, we expect it to be in a certain range
    if (!IsStackPtrOkay(r8) || !IsStackPtrOkay(rbp)) return;
    trace('Script compilation: accessing r8/rbp: ' + Text::FormatPointer(r8));
    auto ptr = Dev::ReadUInt64(r8);
    if (!IsHeapPtrOkay(ptr)) return;
    auto length = Dev::ReadUInt32(r8 + 0x8);
    trace('Script compilation: found a string of length ' + length);
    if (length == 0) return;
    if (length > 0x0FFFFF) {
        warn('[ERROR | Hook_Script_Compilation] script length is > 1MB');
        return;
    }
    string scriptName = ReadCompilationScriptName(rbp);
    trace('Script compilation: logging script now.');
    string theScript = Dev::ReadCString(ptr, length);
    if (scriptName.Length > 0) {
        LogParsedScript(theScript, scriptName);
    } else {
        LogParsedScript(theScript);
    }
}

string ReadCompilationScriptName(uint64 rbp) {
    trace('Script compilation: reading script name.');
    auto ppName = Dev::ReadUInt64(rbp + 0x180);
    if (!IsStackPtrOkay(ppName)) return "";
    auto pName = Dev::ReadUInt64(ppName);
    if (!IsHeapPtrOkay(pName)) return "";
    auto lenName = Dev::ReadUInt32(ppName + 0x8);
    trace('Script compilation: found a name of length ' + lenName);
    return Dev::ReadCString(pName, lenName);
}



// this works (0, 3) but only gets UI layers
// const string XmlPrepPattern = "44 89 69 2C 44 39 6A 08 75 45 48 8B 45 78 4C 8D 4D E0 48 8B 55 60 0F 28 00 66 0F 7F 45 E0 E8 BE FE FF FF 48 8B 45 68 44 39 68 0C 0F 86 AF 03 00 00 44 89 68 0C 44 38 68 0B 0F 84 97 02 00 00 48 8B 00 44 88 28 B8 01 00 00 00 E9 B6 03 00 00 0F 28 02";

// RDX: stack ptr -> string ptr -> <manialink ...>
// r11: CGameUILayer?

const string XmlPrepPattern = "E8 D7 FA FF FF 48 85 DB 0F 84 99 00 00 00 48 85 F6 0F 84 90 00 00 00 80 3E 00 0F 84 87 00 00 00 48 83 FB FF 75 0F 66 0F 1F 44 00 00 48 FF C3 80 3C 1E 00 75 F7 48 8D 4B 01 E8 DA C5 24 01";
FunctionHookHelper@ Hook_Parse_Xml = FunctionHookHelper(
    XmlPrepPattern, 0, 0, "On_ParseXml_Hook"
);

// RSI -> string

void On_ParseXml_Hook(uint64 rsi) {
    trace('on parse xml hook - rsi: ' + Text::FormatPointer(rsi));
    if (rsi == 0) {
        warn('[CRIT | Hook_Parse_Xml] rsi is 0');
        return;
    }
    // if (!IsStackPtrOkay(rsi)) return;
    // auto ptr = Dev::ReadUInt64(rsi);
    if (!IsHeapPtrOkay(rsi)) return;
    // auto length = Dev::ReadUInt32(rsi + 0x8);
    trace('ParseXml: found a string');
    string xml = Dev::ReadCString(rsi);
    if (xml.Contains("<manialink")) {
        LogParsedXml(xml);
    }
}








/*

E8 94 E6 B9 FF 48 89 83 38 02 00 00 48 85 C0 0F 85 2C 01 00 00 48 8D 93 F0 01 00 00 4C 8D 44 24 40 48 8D 4C 24 48 E8 6E 9D B9 FF 44 39 B3 E8 01 00 00 0F 85 A0 00 00 00

further up the stack (hopefulyl out of mode stuff now), after some loading so mb ui

dat_141f207e8: mwbuilder

rbc: CGameManialinkPage
    +0x160: string-ptr -> name of page
    +0x240: string-ptr,flags,len : page source, zerod later
rdx: stack ptr -> string
r9: class id (CSmArenaInterfaceManialinkScriptHandler)













PRESCRIPT

rax: cgame maniaapp playground
rbx: cscenearenaui - 2d009
rcx: ptrs, including 1 to network

r8: ptr to ptr to ... found something that looks like a stack of ML compilation things
r11: csmplayer
r13: ptr to a bunch of arena stuff












*/
