# Blocks the Shift+Tab combination system-wide while leaving Shift and Tab
# working on their own. Shows a tray icon to toggle blocking, toggle
# run-at-startup, and exit. Launch via start-hidden.vbs for no console window.

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# Single instance
$createdNew = $false
$mutex = New-Object System.Threading.Mutex($true, 'Local\ShiftTabBlocker', [ref]$createdNew)
if (-not $createdNew) { exit }

Add-Type -ReferencedAssemblies System.Windows.Forms, System.Drawing -TypeDefinition @'
using System;
using System.Diagnostics;
using System.Drawing;
using System.Reflection;
using System.Runtime.InteropServices;
using System.Windows.Forms;

public static class ShiftTabHook
{
    private const int WH_KEYBOARD_LL = 13;
    private const int VK_TAB = 0x09;
    private const int VK_SHIFT = 0x10;

    public static bool Enabled = true;

    private delegate IntPtr LowLevelKeyboardProc(int nCode, IntPtr wParam, IntPtr lParam);
    // Static field keeps the delegate alive so the GC doesn't collect it.
    private static LowLevelKeyboardProc _proc = HookCallback;
    private static IntPtr _hookId = IntPtr.Zero;

    [DllImport("user32.dll", SetLastError = true)]
    private static extern IntPtr SetWindowsHookEx(int idHook, LowLevelKeyboardProc lpfn, IntPtr hMod, uint dwThreadId);

    [DllImport("user32.dll", SetLastError = true)]
    [return: MarshalAs(UnmanagedType.Bool)]
    private static extern bool UnhookWindowsHookEx(IntPtr hhk);

    [DllImport("user32.dll")]
    private static extern IntPtr CallNextHookEx(IntPtr hhk, int nCode, IntPtr wParam, IntPtr lParam);

    [DllImport("user32.dll")]
    private static extern short GetAsyncKeyState(int vKey);

    [DllImport("kernel32.dll", CharSet = CharSet.Unicode)]
    private static extern IntPtr GetModuleHandle(string lpModuleName);

    public static bool Start()
    {
        if (_hookId != IntPtr.Zero) return true;
        using (Process p = Process.GetCurrentProcess())
        using (ProcessModule m = p.MainModule)
        {
            _hookId = SetWindowsHookEx(WH_KEYBOARD_LL, _proc, GetModuleHandle(m.ModuleName), 0);
        }
        return _hookId != IntPtr.Zero;
    }

    public static void Stop()
    {
        if (_hookId != IntPtr.Zero)
        {
            UnhookWindowsHookEx(_hookId);
            _hookId = IntPtr.Zero;
        }
    }

    private static IntPtr HookCallback(int nCode, IntPtr wParam, IntPtr lParam)
    {
        if (nCode >= 0 && Enabled)
        {
            int vkCode = Marshal.ReadInt32(lParam);
            if (vkCode == VK_TAB && (GetAsyncKeyState(VK_SHIFT) & 0x8000) != 0)
            {
                return (IntPtr)1; // swallow Shift+Tab
            }
        }
        return CallNextHookEx(_hookId, nCode, wParam, lParam);
    }
}

// Shows a balloon/toast using our own icon instead of the stock system icons.
public static class TrayBalloon
{
    [StructLayout(LayoutKind.Sequential, CharSet = CharSet.Unicode)]
    private struct NOTIFYICONDATA
    {
        public int cbSize;
        public IntPtr hWnd;
        public int uID;
        public int uFlags;
        public int uCallbackMessage;
        public IntPtr hIcon;
        [MarshalAs(UnmanagedType.ByValTStr, SizeConst = 128)] public string szTip;
        public int dwState;
        public int dwStateMask;
        [MarshalAs(UnmanagedType.ByValTStr, SizeConst = 256)] public string szInfo;
        public int uTimeoutOrVersion;
        [MarshalAs(UnmanagedType.ByValTStr, SizeConst = 64)] public string szInfoTitle;
        public int dwInfoFlags;
        public Guid guidItem;
        public IntPtr hBalloonIcon;
    }

    [DllImport("shell32.dll", CharSet = CharSet.Unicode)]
    private static extern bool Shell_NotifyIcon(int dwMessage, ref NOTIFYICONDATA lpData);

    private const int NIM_MODIFY = 1;
    private const int NIF_INFO = 0x10;
    private const int NIIF_USER = 0x4;
    private const int NIIF_NOSOUND = 0x10;
    private const int NIIF_LARGE_ICON = 0x20;

    public static bool Show(NotifyIcon ni, string title, string text, Icon icon)
    {
        try
        {
            BindingFlags bf = BindingFlags.NonPublic | BindingFlags.Instance;
            NativeWindow win = (NativeWindow)typeof(NotifyIcon).GetField("window", bf).GetValue(ni);
            int id = (int)typeof(NotifyIcon).GetField("id", bf).GetValue(ni);

            NOTIFYICONDATA d = new NOTIFYICONDATA();
            d.cbSize = Marshal.SizeOf(typeof(NOTIFYICONDATA));
            d.hWnd = win.Handle;
            d.uID = id;
            d.uFlags = NIF_INFO;
            d.szInfoTitle = title;
            d.szInfo = text;
            d.dwInfoFlags = NIIF_USER | NIIF_LARGE_ICON | NIIF_NOSOUND;
            d.hBalloonIcon = icon.Handle;
            d.uTimeoutOrVersion = 1000;
            return Shell_NotifyIcon(NIM_MODIFY, ref d);
        }
        catch
        {
            return false;
        }
    }
}

// Dark colors for the right-click menu.
public class DarkMenuColors : ProfessionalColorTable
{
    static readonly Color Bg = Color.FromArgb(43, 43, 43);
    static readonly Color Hover = Color.FromArgb(65, 65, 65);
    static readonly Color Line = Color.FromArgb(80, 80, 80);

    public override Color ToolStripDropDownBackground { get { return Bg; } }
    public override Color ImageMarginGradientBegin { get { return Bg; } }
    public override Color ImageMarginGradientMiddle { get { return Bg; } }
    public override Color ImageMarginGradientEnd { get { return Bg; } }
    public override Color MenuBorder { get { return Line; } }
    public override Color MenuItemBorder { get { return Hover; } }
    public override Color MenuItemSelected { get { return Hover; } }
    public override Color MenuItemSelectedGradientBegin { get { return Hover; } }
    public override Color MenuItemSelectedGradientEnd { get { return Hover; } }
    public override Color SeparatorDark { get { return Line; } }
    public override Color SeparatorLight { get { return Line; } }
    public override Color CheckBackground { get { return Bg; } }
    public override Color CheckSelectedBackground { get { return Hover; } }
    public override Color CheckPressedBackground { get { return Hover; } }
}

public class ThemedMenuRenderer : ToolStripProfessionalRenderer
{
    private readonly Color _fg;

    public ThemedMenuRenderer(bool dark) : base(dark ? (ProfessionalColorTable)new DarkMenuColors() : new ProfessionalColorTable())
    {
        _fg = dark ? Color.FromArgb(240, 240, 240) : SystemColors.MenuText;
        RoundedEdges = false;
    }

    protected override void OnRenderItemText(ToolStripItemTextRenderEventArgs e)
    {
        e.TextColor = _fg;
        base.OnRenderItemText(e);
    }

    protected override void OnRenderItemCheck(ToolStripItemImageRenderEventArgs e)
    {
        Rectangle r = e.ImageRectangle;
        e.Graphics.SmoothingMode = System.Drawing.Drawing2D.SmoothingMode.AntiAlias;
        using (Pen p = new Pen(_fg, 2f))
        {
            e.Graphics.DrawLines(p, new Point[] {
                new Point(r.Left + 3, r.Top + r.Height / 2),
                new Point(r.Left + r.Width / 2 - 1, r.Bottom - 4),
                new Point(r.Right - 3, r.Top + 4)
            });
        }
    }
}
'@

$runKey   = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Run'
$runName  = 'ShiftTabBlocker'
$launcher = Join-Path $PSScriptRoot 'start-hidden.vbs'
$themeKey = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize'

function Test-Startup {
    $null -ne (Get-ItemProperty -Path $runKey -Name $runName -ErrorAction SilentlyContinue)
}

# Returns @{ Taskbar = <dark?>; Apps = <dark?> } from the Windows theme settings.
function Get-Theme {
    $p = Get-ItemProperty -Path $themeKey -ErrorAction SilentlyContinue
    @{
        Taskbar = ($null -ne $p -and $p.SystemUsesLightTheme -eq 0)
        Apps    = ($null -ne $p -and $p.AppsUseLightTheme -eq 0)
    }
}

# Icons: put on.ico / off.ico (or on.png / off.png) in the icons folder to
# override. Otherwise a built-in icon is drawn to suit the taskbar theme.
function New-DrawnIcon([bool]$on, [bool]$dark) {
    $bmp = New-DrawnBitmap $on $dark 32
    [System.Drawing.Icon]::FromHandle($bmp.GetHicon())
}

# Draws the key icon at any size (artwork is laid out on a 32x32 grid).
function New-DrawnBitmap([bool]$on, [bool]$dark, [int]$size) {
    $bmp = New-Object System.Drawing.Bitmap $size, $size
    $g = [System.Drawing.Graphics]::FromImage($bmp)
    $g.ScaleTransform($size / 32.0, $size / 32.0)
    $g.SmoothingMode = 'AntiAlias'
    $g.TextRenderingHint = 'AntiAliasGridFit'

    # Same gray key for ON and OFF; ON adds the red "no" sign on top.
    if ($dark) {
        $bg = [System.Drawing.Color]::FromArgb(110, 110, 110)
        $fg = [System.Drawing.Color]::FromArgb(220, 220, 220)
    } else {
        $bg = [System.Drawing.Color]::FromArgb(150, 150, 150)
        $fg = [System.Drawing.Color]::White
    }

    $path = New-Object System.Drawing.Drawing2D.GraphicsPath
    $r = 8
    $path.AddArc(1, 1, $r, $r, 180, 90); $path.AddArc(31 - $r, 1, $r, $r, 270, 90)
    $path.AddArc(31 - $r, 31 - $r, $r, $r, 0, 90); $path.AddArc(1, 31 - $r, $r, $r, 90, 90)
    $path.CloseFigure()
    $g.FillPath((New-Object System.Drawing.SolidBrush $bg), $path)

    $font = New-Object System.Drawing.Font('Segoe UI Symbol', 13, [System.Drawing.FontStyle]::Bold, [System.Drawing.GraphicsUnit]::Pixel)
    $fmt = New-Object System.Drawing.StringFormat
    $fmt.Alignment = 'Center'; $fmt.LineAlignment = 'Center'
    $g.DrawString([string][char]0x21E7 + [char]0x21E5, $font, (New-Object System.Drawing.SolidBrush $fg), (New-Object System.Drawing.RectangleF(0, 0, 32, 32)), $fmt)

    if ($on) {
        $pen = New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(230, 60, 60), 3)
        $g.DrawEllipse($pen, 3, 3, 26, 26)
        $g.DrawLine($pen, 8, 24, 24, 8)
    }
    $g.Dispose()
    $bmp
}

function Get-TrayIcon([string]$name, [bool]$on, [bool]$dark) {
    $dir = Join-Path $PSScriptRoot 'icons'
    $candidates = @()
    if ($dark) { $candidates += "$name-dark.ico", "$name-dark.png" }
    $candidates += "$name.ico", "$name.png"
    foreach ($c in $candidates) {
        $file = Join-Path $dir $c
        if (-not (Test-Path $file)) { continue }
        try {
            if ($file -like '*.ico') { return New-Object System.Drawing.Icon($file, 32, 32) }
            $img = [System.Drawing.Image]::FromFile($file)
            $bmp = New-Object System.Drawing.Bitmap($img, 32, 32)
            $img.Dispose()
            return [System.Drawing.Icon]::FromHandle($bmp.GetHicon())
        } catch { }
    }
    New-DrawnIcon $on $dark
}

# --- Toast notifications with our own header icon ---------------------------
# Windows takes a notification's header icon and name from the sending app.
# Registering an AppUserModelID (per-user, no admin) lets us set both.
$appId   = 'ShiftTabBlocker'
$dataDir = Join-Path $env:LOCALAPPDATA 'ShiftTabBlocker'
$script:notifier = $null

# PNG used as the notification header icon for the given theme.
function Get-HeaderPng([bool]$dark) {
    if (-not (Test-Path $dataDir)) { New-Item -ItemType Directory -Path $dataDir | Out-Null }
    $iconDir = Join-Path $PSScriptRoot 'icons'
    $names = @()
    if ($dark) { $names += 'on-dark' }
    $names += 'on'
    foreach ($n in $names) {
        $png = Join-Path $iconDir "$n.png"
        if (Test-Path $png) { return $png }
        $ico = Join-Path $iconDir "$n.ico"
        if (Test-Path $ico) {
            try {
                $out = Join-Path $dataDir "header-custom-$n.png"
                (New-Object System.Drawing.Icon($ico, 64, 64)).ToBitmap().Save($out, [System.Drawing.Imaging.ImageFormat]::Png)
                return $out
            } catch { }
        }
    }
    # Name the file by its content hash: Windows caches header icons by path,
    # so a new design needs a new file name to show up.
    $theme = if ($dark) { 'dark' } else { 'light' }
    $tmp = Join-Path $dataDir "header-$theme.tmp.png"
    (New-DrawnBitmap $true $dark 64).Save($tmp, [System.Drawing.Imaging.ImageFormat]::Png)
    $md5 = [System.Security.Cryptography.MD5]::Create()
    $hash = ([System.BitConverter]::ToString($md5.ComputeHash([System.IO.File]::ReadAllBytes($tmp))) -replace '-', '').Substring(0, 8)
    $md5.Dispose()
    $out = Join-Path $dataDir "header-$theme-$hash.png"
    Move-Item -Path $tmp -Destination $out -Force
    $out
}

function Register-ToastApp([bool]$dark) {
    try {
        $k = "HKCU:\Software\Classes\AppUserModelId\$appId"
        if (-not (Test-Path $k)) { New-Item -Path $k -Force | Out-Null }
        Set-ItemProperty -Path $k -Name DisplayName -Value 'Shift+Tab blocker'
        Set-ItemProperty -Path $k -Name IconUri -Value (Get-HeaderPng $dark)
        Set-ItemProperty -Path $k -Name ShowInSettings -Value 0 -Type DWord

        if ($null -eq $script:notifier) {
            $null = [Windows.UI.Notifications.ToastNotificationManager, Windows.UI.Notifications, ContentType = WindowsRuntime]
            $null = [Windows.Data.Xml.Dom.XmlDocument, Windows.Data.Xml.Dom.XmlDocument, ContentType = WindowsRuntime]
            $script:notifier = [Windows.UI.Notifications.ToastNotificationManager]::CreateToastNotifier($appId)
        }
    } catch {
        $script:notifier = $null
    }
}

function Show-Notification([string]$title, [string]$text) {
    if ($null -ne $script:notifier) {
        try {
            $esc = [System.Security.SecurityElement]
            $xml = New-Object Windows.Data.Xml.Dom.XmlDocument
            $xml.LoadXml("<toast><visual><binding template='ToastGeneric'><text>$($esc::Escape($title))</text><text>$($esc::Escape($text))</text></binding></visual><audio silent='true'/></toast>")
            $toast = New-Object Windows.UI.Notifications.ToastNotification $xml
            # Same tag/group replaces the previous toast instead of piling up.
            $toast.Tag = 'state'
            $toast.Group = 'blocker'
            $toast.ExpirationTime = [DateTimeOffset]::Now.AddSeconds(10)
            $script:notifier.Show($toast)
            return
        } catch { }
    }
    # Fallback: classic tray balloon.
    $icon = if ([ShiftTabHook]::Enabled) { $script:iconOn } else { $script:iconOff }
    if (-not [TrayBalloon]::Show($tray, $title, $text, $icon)) {
        $tray.ShowBalloonTip(1000, $title, $text, [System.Windows.Forms.ToolTipIcon]::None)
    }
}

$tray = New-Object System.Windows.Forms.NotifyIcon
$menu = New-Object System.Windows.Forms.ContextMenuStrip
$itemEnabled = New-Object System.Windows.Forms.ToolStripMenuItem('Enabled')
$itemStartup = New-Object System.Windows.Forms.ToolStripMenuItem('Run at startup')
$itemExit    = New-Object System.Windows.Forms.ToolStripMenuItem('Exit')
[void]$menu.Items.Add($itemEnabled)
[void]$menu.Items.Add($itemStartup)
[void]$menu.Items.Add((New-Object System.Windows.Forms.ToolStripSeparator))
[void]$menu.Items.Add($itemExit)
$tray.ContextMenuStrip = $menu

$script:themeKeyStr = ''
function Update-Theme {
    $t = Get-Theme
    $key = "$($t.Taskbar)|$($t.Apps)"
    if ($key -eq $script:themeKeyStr) { return }
    $script:themeKeyStr = $key
    $script:iconOn  = Get-TrayIcon 'on'  $true  $t.Taskbar
    $script:iconOff = Get-TrayIcon 'off' $false $t.Taskbar
    $menu.Renderer = New-Object ThemedMenuRenderer($t.Apps)
    $menu.BackColor = if ($t.Apps) { [System.Drawing.Color]::FromArgb(43, 43, 43) } else { [System.Drawing.SystemColors]::Menu }
    Register-ToastApp $t.Taskbar
    Update-Tray
}

function Update-Tray {
    $on = [ShiftTabHook]::Enabled
    $itemEnabled.Checked = $on
    if ($on) {
        $tray.Icon = $script:iconOn
        $tray.Text = 'Shift+Tab blocker: ON'
    } else {
        $tray.Icon = $script:iconOff
        $tray.Text = 'Shift+Tab blocker: OFF'
    }
}

function Switch-Blocking {
    [ShiftTabHook]::Enabled = -not [ShiftTabHook]::Enabled
    Update-Tray
    if ([ShiftTabHook]::Enabled) {
        Show-Notification 'Blocking ON' 'Shift+Tab is blocked'
    } else {
        Show-Notification 'Blocking OFF' 'Shift+Tab works normally'
    }
}

$itemEnabled.add_Click({ Switch-Blocking })

$itemStartup.Checked = Test-Startup
$itemStartup.add_Click({
    if (Test-Startup) {
        Remove-ItemProperty -Path $runKey -Name $runName -ErrorAction SilentlyContinue
    } else {
        Set-ItemProperty -Path $runKey -Name $runName -Value "wscript.exe `"$launcher`""
    }
    $itemStartup.Checked = Test-Startup
})

$itemExit.add_Click({ [System.Windows.Forms.Application]::Exit() })

$tray.add_MouseClick({
    param($sender, $e)
    if ($e.Button -eq [System.Windows.Forms.MouseButtons]::Left) { Switch-Blocking }
})

# Re-check the Windows theme every few seconds so icons/menu follow light/dark changes.
$themeTimer = New-Object System.Windows.Forms.Timer
$themeTimer.Interval = 3000
$themeTimer.add_Tick({ Update-Theme })

try {
    if (-not [ShiftTabHook]::Start()) {
        [System.Windows.Forms.MessageBox]::Show('Failed to install keyboard hook.', 'Shift+Tab blocker') | Out-Null
        exit 1
    }
    Update-Theme
    $tray.Visible = $true
    $themeTimer.Start()
    [System.Windows.Forms.Application]::Run()
}
finally {
    $themeTimer.Stop()
    [ShiftTabHook]::Stop()
    $tray.Visible = $false
    $tray.Dispose()
    $mutex.ReleaseMutex()
    $mutex.Dispose()
}
