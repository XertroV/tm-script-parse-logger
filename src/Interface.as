void DrawInterfaceInner() {
    UI::BeginTabBar("nodlogtabs");

    if (UI::BeginTabItem("General")) {
        DrawGeneralTab();
        UI::EndTabItem();
    }

    if (UI::BeginTabItem("Nod Log")) {
        DrawNodLogTable();
        UI::EndTabItem();
    }

    // if (UI::BeginTabItem("??")) {
    //     // DrawNodLogTable();
    //     UI::EndTabItem();
    // }

    UI::EndTabBar();
}

void DrawGeneralTab() {
    UI::Text(IsHooked ? "Status: Enabled" : "Status: Disabled");
    if (UI::Button(IsHooked ? "Unhook On Load Nods" : "Hook On Load Nods")) {
        if (IsHooked) RemoveNodHooks();
        else startnew(SetupNodHooks);
    }
    S_HookNodsOnStartup = UI::Checkbox("Hook nod loads on startup?", S_HookNodsOnStartup);
    g_LogLoadedNodsToOpLog = UI::Checkbox("Log Nods to Openplanet Log?", g_LogLoadedNodsToOpLog);
}


void DrawNodLogTable() {
    if (UI::Button("Clear Log")) {
        NodLoad_Logs.RemoveRange(0, NodLoad_Logs.Length);
    }
    UI::SameLine();
    if (UI::Button("Export CSV")) {
        // NodLoad_Logs.RemoveRange(0, NodLoad_Logs.Length);
        startnew(ExportNodLogCSV);
    }
    UI::SameLine();
    g_AfterCSVOpenFolder = UI::Checkbox("Open Folder after CSV", g_AfterCSVOpenFolder);
    UI::PushStyleVar(UI::StyleVar::FramePadding, vec2(2, 0));
    if (UI::BeginChild("nodlogchild")) {
        if (UI::BeginTable("nodlog", 8, UI::TableFlags::SizingStretchProp)) {
            UI::ListClipper clip(NodLoad_Logs.Length);
            while (clip.Step()) {
                for (int i = clip.DisplayStart; i < clip.DisplayEnd; i++) {
                    UI::PushID(i);
                    NodLoad_Logs[i].DrawRow();
                    UI::PopID();
                }
            }
            UI::EndTable();
        }
    }
    UI::EndChild();
    UI::PopStyleVar();
}
