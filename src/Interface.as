void DrawInterfaceInner() {
    UI::BeginTabBar("nodlogtabs");

    if (UI::BeginTabItem("General")) {
        DrawGeneralTab();
        UI::EndTabItem();
    }

    if (UI::BeginTabItem("Script Parse Log")) {
        DrawScriptParseTable();
        UI::EndTabItem();
    }

    // if (UI::BeginTabItem("??")) {
    //     // DrawScriptParseTable();
    //     UI::EndTabItem();
    // }

    UI::EndTabBar();
}

void DrawGeneralTab() {
    UI::Text(IsHooked ? "Status: Enabled" : "Status: Disabled");
    if (UI::Button(IsHooked ? "Unhook On Script Parse" : "Hook On Script Parse")) {
        if (IsHooked) RemoveHook();
        else startnew(SetupScriptParseHooks);
    }
    S_HookScriptParseOnStartup = UI::Checkbox("Hook script parsing on startup?", S_HookScriptParseOnStartup);
    g_LogScriptsToOpLog = UI::Checkbox("Log Scripts to Openplanet Log?", g_LogScriptsToOpLog);
}


void DrawScriptParseTable() {
    if (UI::Button("Clear Log")) {
        ScriptParse_Logs.RemoveRange(0, ScriptParse_Logs.Length);
    }
    UI::SameLine();
    if (UI::Button("Export CSV")) {
        // ScriptParse_Logs.RemoveRange(0, ScriptParse_Logs.Length);
        startnew(ExportLogCSV);
    }
    UI::SameLine();
    g_AfterCSVOpenFolder = UI::Checkbox("Open Folder after CSV", g_AfterCSVOpenFolder);
    UI::PushStyleVar(UI::StyleVar::FramePadding, vec2(2, 0));
    if (UI::BeginChild("nodlogchild")) {
        if (UI::BeginTable("nodlog", 3, UI::TableFlags::SizingStretchProp)) {
            UI::TableSetupColumn("Time Ago", UI::TableColumnFlags::WidthFixed, 100);
            UI::TableSetupColumn("Script", UI::TableColumnFlags::WidthStretch);
            UI::TableSetupColumn("##tools", UI::TableColumnFlags::WidthFixed, 50);
            UI::ListClipper clip(ScriptParse_Logs.Length);
            while (clip.Step()) {
                for (int i = clip.DisplayStart; i < clip.DisplayEnd; i++) {
                    UI::PushID(i);
                    ScriptParse_Logs[i].DrawRow();
                    UI::PopID();
                }
            }
            UI::EndTable();
        }
    }
    UI::EndChild();
    UI::PopStyleVar();
}
