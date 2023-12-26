/** Called when a Nod is loaded from a file. You have to call `RegisterLoadCallback` first before this is called. This callback is meant as an early callback for a loaded nod. If you're not sure whether you need an early callback and you can avoid using this callback, then avoid using this function.
*/
void OnLoadCallback(CMwNod@ nod) {
    auto cls = Reflection::TypeOf(nod);
    auto fid = cast<CSystemFidFile>(GetFidFromNod(nod));
    LogLoadedNod(cls, fid);
    // trace('Nod loaded of type: ' + cls.Name + " | " + Text::Format("%08x", cls.ID));
}

void LogLoadedNod(const Reflection::MwClassInfo@ cls, CSystemFidFile@ fid) {
    NodLoad_Logs.InsertLast(NodLoad_Log(cls, fid));
}

NodLoad_Log@[] NodLoad_Logs;

const string GameDataDir = Fids::GetGameFolder("").FullDirName;
const string ProgDataDir = Fids::GetProgramDataFolder("").FullDirName;
const string UserDataDir = Fids::GetUserFolder("").FullDirName;

class NodLoad_Log {
    CSystemFidFile@ fid;
    const Reflection::MwClassInfo@ cls;
    int64 loadTime;
    string clsId;
    string fidPath;
    string fidRawPath;
    string fidSize;
    uint64 nodPtr;
    string nodPtrStr;

    NodLoad_Log(const Reflection::MwClassInfo@ cls, CSystemFidFile@ fid) {
        @this.cls = cls;
        @this.fid = fid;
        loadTime = Time::Now;
        PopulateValues();
    }

    protected void PopulateValues() {
        clsId = Text::Format("%08x", cls.ID);
        if (fid is null) return;
        fidPath = (fid.ParentFolder is null ? "<>\\" : string(fid.ParentFolder.FullDirName)) + ("\\$9f5" + fid.FileName);
        fidRawPath = fidPath;
        if (fidPath.StartsWith(GameDataDir)) {
            fidPath = "\\$888<game>\\\\$aaa" + fidPath.SubStr(GameDataDir.Length);
        } else if (fidPath.StartsWith(ProgDataDir)) {
            fidPath = "\\$888<prog>\\\\$aaa" + fidPath.SubStr(ProgDataDir.Length);
        } else if (fidPath.StartsWith(UserDataDir)) {
            fidPath = "\\$888<user>\\\\$aaa" + fidPath.SubStr(UserDataDir.Length);
        }

        fidSize = GetFidSize(fid);
        nodPtr = GetPointerFromFid(fid);
        nodPtrStr = Text::FormatPointer(nodPtr);
    }

    string get_HumanTimeDelta() {
        return HumanizeTime((loadTime - int64(Time::Now)) / 1000);
    }

    // cols = 8
    void DrawRow() {
        UI::TableNextRow();

        UI::TableNextColumn();
        UI::Text(HumanTimeDelta);

        UI::TableNextColumn();
        UI::Text(clsId);

        UI::TableNextColumn();
        UI::Text(cls.Name);

        UI::TableNextColumn();
        // UI::Text(cls.UserName);

        UI::TableNextColumn();
        UI::Text(fidPath);
        HandOnHover();
        if (UI::IsItemClicked()) { SetClipboard(fidRawPath); }

        UI::TableNextColumn();
        UI::Text(fidSize);

        UI::TableNextColumn();
        CopiableValue(nodPtrStr);

        UI::TableNextColumn();
        if (UI::Button(Icons::Cube + "##" + nodPtrStr)) {
            ExploreNod(fid);
        }
        if (fid.Container !is null) {
            UI::SameLine();
            bool clicked = UI::Button(Icons::Cube + " Pack##" + nodPtrStr);
            AddSimpleTooltip(fid.Container.FileName);
            if (clicked) ExploreNod(fid.Container);
        }
    }
}

string GetFidSize(CSystemFidFile@ fid) {
    auto usize = fid.ByteSize;
    if (usize == 0) {
        usize = fid.ByteSizeEd << 10;
    }
    if (usize == 0) return "-";
    float size = float(usize);
    uint mag = 0;
    while (size > 1024.0 && mag < 3) {
        mag++;
        size /= 1024.0;
    }
    return Text::Format("%.1f ", size) + (mag == 0 ? "B" : mag == 1 ? "KB" : mag == 2 ? "MB" : "GB");
}



uint16 GetOffset(const string &in className, const string &in memberName) {
    // throw exception when something goes wrong.
    auto ty = Reflection::GetType(className);
    auto memberTy = ty.GetMember(memberName);
    if (memberTy.Offset == 0xFFFF) throw("Invalid offset: 0xFFFF");
    return memberTy.Offset;
}
uint16 GetOffset(CMwNod@ obj, const string &in memberName) {
    if (obj is null) return 0xFFFF;
    // throw exception when something goes wrong.
    auto ty = Reflection::TypeOf(obj);
    if (ty is null) throw("could not find a type for object");
    auto memberTy = ty.GetMember(memberName);
    if (memberTy is null) throw(ty.Name + " does not have a child called " + memberName);
    if (memberTy.Offset == 0xFFFF) throw("Invalid offset: 0xFFFF");
    return memberTy.Offset;
}


const uint16 O_FIDFILE_NOD = GetOffset("CSystemFidFile", "Nod");


uint64 GetPointerFromFid(CSystemFidFile@ fid) {
    return Dev::GetOffsetUint64(fid, O_FIDFILE_NOD);
}

