bool CopiableValue(const string &in value) {
    if (ClickableLabel("", value, "")) {
        SetClipboard(value);
        return true;
    }
    return false;
}
bool CopiableLabelValue(const string &in label, const string &in value) {
    if (ClickableLabel(label, value)) {
        SetClipboard(value);
        return true;
    }
    return false;
}

bool ClickableLabel(const string &in label, const string &in value, const string &in between = ": ") {
    UI::Text(label.Length > 0 ? label + between + value : value);
    HandOnHover();
    return UI::IsItemClicked();
}

void SetClipboard(const string &in msg) {
    IO::SetClipboard(msg);
    Notify("Copied: " + msg);
}

void HandOnHover() {
    if (UI::IsItemHovered()) {
        UI::SetMouseCursor(UI::MouseCursor::Hand);
    }
}
