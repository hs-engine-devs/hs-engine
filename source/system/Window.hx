package system;

#if windows
@:buildXml('
    <target id="haxe">
        <lib name="dwmapi.lib" if="windows" />
    </target>
')
@:cppFileCode('
    #include <Windows.h>
    #include <dwmapi.h>
    #include <tchar.h>

    #ifndef DWMWA_USE_IMMERSIVE_DARK_MODE
        #define DWMWA_USE_IMMERSIVE_DARK_MODE 20
    #endif

    void forceDarkMode() {
        HWND hwnd = GetActiveWindow();
        BOOL dark = TRUE;
        DwmSetWindowAttribute(hwnd, DWMWA_USE_IMMERSIVE_DARK_MODE, &dark, sizeof(dark));
    }
')
#end

@:dox(hide)
class Window {
    #if windows
    @:functionCode('forceDarkMode();')
    public static function setDarkMode():Void {}

    public static function darkMode():Void {
        setDarkMode();
        lime.app.Application.current.window.borderless = true;
        lime.app.Application.current.window.borderless = false;
    }
    #end
}
