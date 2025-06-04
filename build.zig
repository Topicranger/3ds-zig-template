const std = @import("std");
const builtin = @import("builtin");

// 3DS values
const appFilename = "apptemplate";
const appTitle = "App template";
const appDescription = "Built with Zig, devkitARM, and libctru";
const appAuthor = "YourName";

// devkitPro paths
const devkitPro = "/opt/devkitpro"; //or the path to your installation, e.g. "c:/devkitPro"
const devkitProToolsDir = devkitPro ++ "/tools/bin";
const devkitARMCompilerDir = devkitPro ++ "/devkitARM/bin";
const devkitARMIncludeDir = devkitPro ++ "/devkitARM/arm-none-eabi/include";
const ctruIncludeDir = devkitPro ++ "/libctru/include";
const ctruLibDir = devkitPro ++ "/libctru/lib";
const ctruDir = devkitPro ++ "/libctru";

pub fn build(b: *std.Build) void {
    // step 1
    // check if we need windows file extensions
    const extension = if (builtin.target.os.tag == .windows) ".exe" else "";

    // check if all required tools are available before providing an option to
    // build for the 3DS
    const dkp3dsx = b.findProgram(&.{"3dsxtool" ++ extension}, &.{devkitProToolsDir}) catch "";
    const dkpsmdh = b.findProgram(&.{"smdhtool" ++ extension}, &.{devkitProToolsDir}) catch "";
    const dkpgcc = b.findProgram(&.{"arm-none-eabi-gcc" ++ extension}, &.{devkitARMCompilerDir}) catch "";
    if (dkp3dsx.len == 0 or dkpsmdh.len == 0 or dkpgcc.len == 0) {
        return;
    }

    // step 2
    const optimize = b.standardOptimizeOption(.{});
    const target: std.Target.Query = .{
        .cpu_arch = .arm,
        .os_tag = .freestanding,
        .abi = .eabihf,
        .cpu_model = .{ .explicit = &std.Target.arm.cpu.mpcore },
    };

    const obj = b.addObject(.{
        .name = appFilename,
        .target = b.resolveTargetQuery(target),
        .optimize = optimize,
        .root_source_file = b.path("src/main.zig"), //TODO: refactor to modules
    });
    obj.linkLibC();
    obj.addIncludePath(.{ .src_path = .{ .owner = b, .sub_path = devkitPro ++ "/portlibs/3ds/include" } });
    obj.addIncludePath(.{ .src_path = .{ .owner = b, .sub_path = ctruIncludeDir } });
    obj.addIncludePath(.{ .src_path = .{ .owner = b, .sub_path = devkitARMIncludeDir } });

    const wf = b.addWriteFiles();

    // step 3
    const elf = b.addSystemCommand(&(.{dkpgcc}));

    elf.setCwd(wf.getDirectory());
    elf.addArgs(&.{
        "-specs=3dsx.specs",
        "-g",
        "-march=armv6k",
        "-mtune=mpcore",
        "-mfloat-abi=hard",
        "-mtp=soft",
    });
    _ = elf.addPrefixedOutputFileArg("-Wl,-Map,", appFilename ++ ".map");
    elf.addArtifactArg(obj);
    elf.addArgs(&.{
        "-L" ++ ctruLibDir,
        "-lctru",
    });
    const out_elf = elf.addPrefixedOutputFileArg("-o", appFilename ++ ".elf");

    // step 4
    const icon = ctruDir ++ "/default_icon.png";
    const smdh = b.addSystemCommand(&.{dkpsmdh});
    smdh.setCwd(wf.getDirectory());
    smdh.addArgs(&.{
        "--create",
        appTitle,
        appDescription,
        appAuthor,
        icon,
    });
    const out_smdh = smdh.addOutputFileArg(appFilename ++ ".smdh");

    // step 5
    const dsx = b.addSystemCommand(&.{dkp3dsx});
    dsx.setCwd(wf.getDirectory());
    dsx.addFileArg(out_elf);
    const out_dsx = dsx.addOutputFileArg(appFilename ++ ".3dsx");
    dsx.addPrefixedFileArg("--smdh=", out_smdh);

    const install_3dsx = b.addInstallFileWithDir(out_dsx, .prefix, appFilename ++ ".3dsx");
    const ds_step = b.step("3ds", "Build 3DS executable");
    ds_step.dependOn(&install_3dsx.step);

    // Run in emulator
    const azahar = b.findProgram(&.{"azahar"}, &.{}) catch "";
    const emulate = if (azahar.len > 0) cmd: {
        break :cmd b.addSystemCommand(&.{azahar});
    } else cmd: {
        const flatpak = b.findProgram(&.{"flatpak"}, &.{}) catch "";
        if (flatpak.len == 0) {
            return;
        }
        break :cmd b.addSystemCommand(&.{ flatpak, "run", "org.azahar_emu.Azahar" });
    };
    emulate.addFileArg(out_dsx);
    const run_step = b.step("run", "Run in Azahar");
    run_step.dependOn(&emulate.step);
}
