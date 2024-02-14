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

    for (uint i = 0; i < LogsWithActiveWindow.Length; i++) {
        LogsWithActiveWindow[i].DrawWindow();
    }
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
            UI::TableSetupColumn("Time Ago", UI::TableColumnFlags::WidthFixed, 70);
            UI::TableSetupColumn("Script Name", UI::TableColumnFlags::WidthStretch);
            // UI::TableSetupColumn("Script", UI::TableColumnFlags::WidthFixed, 1);
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


void DrawLinesAndNumbers(const string &in filename, string[]@ lines) {
    UI::ListClipper clip(lines.Length);
    auto cursorStart = UI::GetCursorPos();
    auto extraWidth = Draw::MeasureString(". ").x + UI::GetStyleVarVec2(UI::StyleVar::ItemSpacing).x * 2.;
    auto max_line_number = lines.Length;
    auto ln_max_str_len = tostring(max_line_number).Length;
    auto lnNbsWidth = Draw::MeasureString(("00000").SubStr(0, ln_max_str_len)).x + extraWidth;
    vec2 cursorPos;
    while (clip.Step()) {
        for (int i = clip.DisplayStart; i < clip.DisplayEnd; i++) {
            UI::PushID(i);
            cursorPos = UI::GetCursorPos();
            UI::Text("\\$999" + (i + 1) + ". ");
            UI::SetCursorPos(cursorPos + vec2(lnNbsWidth, 0));
            UI::Text(lines[i]);
            UI::PopID();
        }
    }
}
