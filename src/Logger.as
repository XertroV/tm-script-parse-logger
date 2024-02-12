void LogParsedScript(const string &in script) {
    ScriptParse_Logs.InsertLast(ScriptParse_Log(script));
}

ScriptParse_Log@[] ScriptParse_Logs;
ScriptParse_Log@[] LogsWithActiveWindow;
ScriptParse_Log@[] RemoveWindows;
void RemoveLogWindow(ScriptParse_Log@ log) {
    RemoveWindows.InsertLast(log);
}
void RemoveWindowsCoro() {
    while (true) {
        yield();
        if (RemoveWindows.Length == 0) continue;
        for (uint i = 0; i < RemoveWindows.Length; i++) {
            auto ix = LogsWithActiveWindow.FindByRef(RemoveWindows[i]);
            if (ix != -1) {
                LogsWithActiveWindow.RemoveAt(ix);
            }
        }
        RemoveWindows.RemoveRange(0, RemoveWindows.Length);
    }
}

class ScriptParse_Log {
    int64 loadTime;
    string script;
    string scriptSafeRender;
    string fidPath;
    string fidRawPath;
    string fidSize;
    string scriptHash;
    bool _windowVisible = false;
    string scriptName = "?";
    bool foundName = false;
    string windowTitle = "?";
    string fileName = "?";

    ScriptParse_Log(const string &in script) {
        this.script = script;
        PopulateValues();

        loadTime = Time::Now;
        // PopulateValues();
        if (g_LogScriptsToOpLog) LogToOpLog();
    }

    bool windowVisible {
        get { return _windowVisible; }
        set {
            if (_windowVisible == value) return;
            _windowVisible = value;
            if (value) LogsWithActiveWindow.InsertLast(this);
            else {
                RemoveLogWindow(this);
            }
        }
    }

    void LogToOpLog() {
        trace('Parsing Script: ' + loadTime + ' | ' + script);
    }

    protected void PopulateValues() {
        scriptHash = Crypto::MD5(script);
        scriptSafeRender = script.SubStr(0, 4096).Trim().Replace('\n', '\\n').Replace('\r', '\\r');
        auto match = Regex::Search(scriptSafeRender, "#Const[ \\t][ \\tA-Za-z_]*(ScriptName|PageUID)[ \\t][ \\t]*\"([^\"]+)\"");
        if (match.Length >= 3) {
            foundName = true;
            scriptName = match[2].Replace("\\", "/");
            windowTitle = scriptName;
            auto nameParts = scriptName.Split("/");
            fileName = nameParts[nameParts.Length - 1];
            nameParts[nameParts.Length - 1] = "\\$8f8" + fileName;
            scriptName = "\\$aaa" + string::Join(nameParts, "/");
        } else {
            scriptName = "\\$aaa" + scriptHash.SubStr(0, 7) + "  \\$z" + scriptSafeRender;
            windowTitle = "Script: " + scriptHash.SubStr(0, 7);
        }
    }

    void DrawWindow() {
        if (windowVisible) {
            UI::SetNextWindowSize(600, 400, UI::Cond::FirstUseEver);
            if (UI::Begin("Script: " + scriptName, windowVisible)) {
                UI::Text(script);
            }
            UI::End();
        }
    }

    string get_HumanTimeDelta() {
        return HumanizeTime((loadTime - int64(Time::Now)) / 1000);
    }

    // cols = 3
    void DrawRow() {
        UI::TableNextRow();

        UI::TableNextColumn();
        UI::Text(HumanTimeDelta);
        // HandOnHover();
        // if (UI::IsItemClicked()) { SetClipboard(HumanTimeDelta); }

        UI::TableNextColumn();
        UI::Text(scriptName);

        HandOnHover();
        AddSimpleTooltip("Click to copy script.\nHash: " + scriptHash);
        if (UI::IsItemClicked()) { SetClipboard(script); }

        UI::TableNextColumn();
        if (UI::Button(Icons::SearchPlus + "##" + scriptHash)) {
            this.windowVisible = true;
        }
        AddSimpleTooltip("Show script in new window");
        // if (fid !is null && fid.Container !is null) {
        //     UI::SameLine();
        //     bool clicked = UI::Button(Icons::Cube + " Pack##" + nodPtrStr);
        //     AddSimpleTooltip(fid.Container.FileName);
        //     if (clicked) ExploreNod(fid.Container);
        // }
    }

    string AsCSVRow() {
        return ('___SCRIPT START___, ' + loadTime + ', ' + script);
    }
}

// string GetFidSize(CSystemFidFile@ fid) {
//     auto usize = fid.ByteSize;
//     if (usize == 0) {
//         usize = fid.ByteSizeEd << 10;
//     }
//     if (usize == 0) return "-";
//     float size = float(usize);
//     uint mag = 0;
//     while (size > 1024.0 && mag < 3) {
//         mag++;
//         size /= 1024.0;
//     }
//     return Text::Format("%.1f ", size) + (mag == 0 ? "B" : mag == 1 ? "KB" : mag == 2 ? "MB" : "GB");
// }



// uint16 GetOffset(const string &in className, const string &in memberName) {
//     // throw exception when something goes wrong.
//     auto ty = Reflection::GetType(className);
//     auto memberTy = ty.GetMember(memberName);
//     if (memberTy.Offset == 0xFFFF) throw("Invalid offset: 0xFFFF");
//     return memberTy.Offset;
// }
// uint16 GetOffset(CMwNod@ obj, const string &in memberName) {
//     if (obj is null) return 0xFFFF;
//     // throw exception when something goes wrong.
//     auto ty = Reflection::TypeOf(obj);
//     if (ty is null) throw("could not find a type for object");
//     auto memberTy = ty.GetMember(memberName);
//     if (memberTy is null) throw(ty.Name + " does not have a child called " + memberName);
//     if (memberTy.Offset == 0xFFFF) throw("Invalid offset: 0xFFFF");
//     return memberTy.Offset;
// }


// const uint16 O_FIDFILE_NOD = GetOffset("CSystemFidFile", "Nod");


// uint64 GetPointerFromFid(CSystemFidFile@ fid) {
//     return Dev::GetOffsetUint64(fid, O_FIDFILE_NOD);
// }

void ExportLogCSV() {
    auto filename = "ScriptParseLog_" + Time::Stamp + ".csv";
    IO::File f(IO::FromStorageFolder(filename), IO::FileMode::Write);
    for (uint i = 0; i < ScriptParse_Logs.Length; i++) {
        f.WriteLine(ScriptParse_Logs[i].AsCSVRow());
    }
    f.Close();
    Notify("Saved Script Parse Log CSV: " + IO::FromStorageFolder(filename));
    if (g_AfterCSVOpenFolder) {
        OpenExplorerPath(IO::FromStorageFolder(""));
    }
}
