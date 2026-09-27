
/*
In Microsoft SQL Server, comments are non-executing text strings used to document code or temporarily disable execution. SQL Server supports two primary syntax types for comments:

Single-line comments: Begin with two hyphens (--) and continue to the end of the line. These can appear on their own line or at the end of a code statement. 
Block (multi-line) comments: Begin with /* and end with */. These can span multiple lines or comment out sections within a single line of code. 
For SQL Server Management Studio (SSMS) and Azure Data Studio, you can quickly comment or uncomment selected code using the keyboard shortcuts Ctrl+K, Ctrl+C (comment) and Ctrl+K, Ctrl+U (uncomment).  Comments are ignored by the server, have no maximum length, and support nesting (e.g., a block comment inside another block comment). 


vscode word wrap

To enable or toggle word wrap in Visual Studio Code, press **Alt+Z** (Windows/Linux) or **Option+Z** (Mac). This shortcut toggles the setting for the current session, allowing you to switch between wrapped and unwrapped views quickly.

To make word wrap the permanent default for all files, add the following configuration to your **settings.json**:

```json
"editor.wordWrap": "on"
```

The `editor.wordWrap` setting accepts four values:
*   **off**: Lines never wrap (default).
*   **on**: Lines wrap at the editor's viewport width.
*   **wordWrapColumn**: Lines wrap at a specific column defined by `editor.wordWrapColumn`.
*   **bounded**: Lines wrap at the minimum of the viewport width and `editor.wordWrapColumn`.

The **user** `settings.json` is located at:

| OS | Path |
|---|---|
| **Windows** | `%APPDATA%\Code\User\settings.json` |
| **macOS** | `~/Library/Application Support/Code/User/settings.json` |
| **Linux** | `~/.config/Code/User/settings.json` |

**Workspace** settings live in a `.vscode/settings.json` file at the root of your project folder.

The fastest way to open it is via the **Command Palette** (`Ctrl+Shift+P` / `Cmd+Shift+P`) → type **`Preferences: Open User Settings (JSON)`**.

Example settings.json:

{
    "editor.wordWrap": "on",
    "editor.fontSize": 14,
    "editor.tabSize": 2,
    "editor.minimap.enabled": false,
    "editor.formatOnSave": true,
    "editor.cursorBlinking": "smooth",
    "files.autoSave": "onFocusChange",
    "workbench.colorTheme": "Default Dark Modern",
    "editor.renderWhitespace": "selection"
}   

That's expected — the `.vscode` folder is **not** created automatically. It only appears once VS Code writes something to it (e.g., you change a workspace setting, configure a debugger, or an extension saves a config).

To create it yourself, just make the folder and file manually:

1. In your project root, create a folder named `.vscode`
2. Inside it, create a file named `settings.json`
3. Add your settings:

```json
{
    "editor.wordWrap": "on"
}
```

Alternatively, the quickest way is via the **Command Palette** (`Ctrl+Shift+P`) → type **`Preferences: Open Workspace Settings (JSON)`** — VS Code will create both the folder and file for you if they don't exist yet.



*/