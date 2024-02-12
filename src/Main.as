const string PLUGIN_NAME = Meta::ExecutingPlugin().Name;
const string PLUGIN_ICON = Icons::FireExtinguisher;
const string MenuTitle = "\\$83f" + PLUGIN_ICON + "\\$z " + PLUGIN_NAME;

const bool HasPermissions = Meta::IsDeveloperMode();

[Setting hidden]
bool g_LogScriptsToOpLog = false;

[Setting hidden]
bool g_AfterCSVOpenFolder = false;

void Main() {
    // auto testScript = "/**\\n\\n#Const    ScriptName	    \"Libs/Nadeo/CMGame/Modes/Legacy/XmlRpc2_Base.Script.txt\"\\n\\n */";
    // auto test = ScriptParse_Log(testScript);
    // auto match1 = Regex::Search(testScript, "#Const", Regex::Flags::Extended);
    // auto match2 = Regex::Search(testScript, "#Const([ \\t])+");
    // auto match3 = Regex::Search(testScript, "#Const([ \\t])+ScriptName");
    // auto match4 = Regex::Search(testScript, "#Const([ \\t])+ScriptName([ \\t])+");
    // auto match5 = Regex::Search(testScript, "#Const([ \\t])+ScriptName([ \\t])+\"");
    // trace("Match1: " + match1[0].Length);
    // trace("Match2: " + match2[0].Length);
    // trace("Match3: " + match3[0].Length);
    // trace("Match4: " + match4[0].Length);
    // trace("Match5: " + match5[0].Length);

    if (!HasPermissions) {
        NotifyError("You must be running in developer mode to use this plugin.");
        return;
    }
    startnew(LoadFonts);
    startnew(RemoveWindowsCoro);
    if (!S_HookScriptParseOnStartup) return;

    startnew(SetupScriptParseHooks);
}

void Unload() {
    RemoveHook();
    CheckUnhookAllRegisteredHooks();
}
void OnDestroyed() { Unload(); }
void OnDisabled() { Unload(); }

UI::Font@ g_MonoFont;
UI::Font@ g_BoldFont;
UI::Font@ g_BigFont;
UI::Font@ g_MidFont;
void LoadFonts() {
    @g_BoldFont = UI::LoadFont("DroidSans-Bold.ttf");
    @g_MonoFont = UI::LoadFont("DroidSansMono.ttf");
    @g_BigFont = UI::LoadFont("DroidSans.ttf", 26);
    @g_MidFont = UI::LoadFont("DroidSans.ttf", 20);
}

void Notify(const string &in msg) {
    UI::ShowNotification(Meta::ExecutingPlugin().Name, msg);
    trace("Notified: " + msg);
}

void NotifyError(const string &in msg) {
    warn(msg);
    UI::ShowNotification(Meta::ExecutingPlugin().Name + ": Error", msg, vec4(.9, .3, .1, .3), 15000);
}

void NotifyWarning(const string &in msg) {
    warn(msg);
    UI::ShowNotification(Meta::ExecutingPlugin().Name + ": Warning", msg, vec4(.9, .6, .2, .3), 15000);
}


string HumanizeTime(int64 secondsDelta) {
    auto abs = Math::Abs(secondsDelta);
    auto units = abs < 60 ? " s" : abs < 3600 ? " m" : " h";
    auto val = abs / (abs < 60 ? 1 : abs < 3600 ? 60 : 3600);
    auto dir = secondsDelta <= 0 ? " ago" : " away";
    return tostring(val) + units + dir;
}


// show the window immediately upon installation
[Setting hidden]
bool ShowWindow = true;


/** Render function called every frame intended only for menu items in `UI`. */
void RenderMenu() {
    if (UI::MenuItem(MenuTitle, "", ShowWindow)) {
        ShowWindow = !ShowWindow;
    }
}



/** Render function called every frame intended for `UI`.
*/
void RenderInterface() {
    if (!ShowWindow) return;
    UI::SetNextWindowSize(800, 560, UI::Cond::FirstUseEver);
    UI::PushStyleColor(UI::Col::FrameBg, vec4(.2, .2, .2, .5));
    if (UI::Begin(MenuTitle, ShowWindow)) {
        UI::PushFont(g_MonoFont);

        if (HasPermissions) {
            DrawInterfaceInner();
        } else {
            UI::Text("\\$f80 Not running in dev mode!");
        }

        UI::PopFont();
    }
    UI::End();
    UI::PopStyleColor();
}

void AddSimpleTooltip(const string &in msg) {
    if (UI::IsItemHovered()) {
        UI::SetNextWindowSize(400, 0, UI::Cond::Appearing);
        UI::BeginTooltip();
        UI::TextWrapped(msg);
        UI::EndTooltip();
    }
}
