const ds = @import("3ds.zig");

pub fn main() void {
    ds.gfxInitDefault();
    defer ds.gfxExit();

    _ = ds.consoleInit(ds.GFX_TOP, null);

    _ = ds.printf("\x1b[16;20HHello, Mario!\n");
    _ = ds.printf("\x1b[17;9HThe princess is in another castle!");
    _ = ds.printf("\x1b[30;16HPress Start to exit.\n");

    // Main loop
    while (ds.aptMainLoop()) {

        // Your code goes here

        ds.hidScanInput();

        const kDown = ds.hidKeysDown();
        if (kDown & ds.KEY_START > 0) break;

        ds.gfxFlushBuffers();
        ds.gfxSwapBuffers();
        ds.gspWaitForEvent(ds.GSPGPU_EVENT_VBlank0, true);
    }
}
