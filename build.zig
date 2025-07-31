const std = @import("std");
const builtin = @import("builtin");

const Env = struct {
    ip_3ds: []const u8,
};
const env: Env = @import("env.zig.zon");

// 3DS values
const app_filename = "apptemplate";
const app_title = "App template";
const app_description = "Built with Zig, devkitARM, and libctru";
const app_author = "YourName";

// devkitPro paths
const devkitpro = "/opt/devkitpro"; //or the path to your installation, e.g. "c:/devkitPro"
const devkitpro_tools_dir = devkitpro ++ "/tools/bin";
const devkitarm_compiler_dir = devkitpro ++ "/devkitARM/bin";
const devkitarm_include_dir = devkitpro ++ "/devkitARM/arm-none-eabi/include";
const ctru_include_dir = devkitpro ++ "/libctru/include";
const ctru_lib_dir = devkitpro ++ "/libctru/lib";
const ctru_dir = devkitpro ++ "/libctru";

pub fn build(b: *std.Build) void {
    // step 1
    // check if we need windows file extensions
    const extension = if (builtin.target.os.tag == .windows) ".exe" else "";

    // check if all required tools are available before providing an option to
    // build for the 3DS
    const dkp_3dsx = b.findProgram(&.{"3dsxtool" ++ extension}, &.{devkitpro_tools_dir}) catch "";
    const dkp_smdh = b.findProgram(&.{"smdhtool" ++ extension}, &.{devkitpro_tools_dir}) catch "";
    const dkp_gcc = b.findProgram(&.{"arm-none-eabi-gcc" ++ extension}, &.{devkitarm_compiler_dir}) catch "";
    if (dkp_3dsx.len == 0 or dkp_smdh.len == 0 or dkp_gcc.len == 0) {
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
        .name = app_filename,
        .target = b.resolveTargetQuery(target),
        .optimize = optimize,
        .root_source_file = b.path("src/main.zig"), //TODO: refactor to modules
    });
    obj.linkLibC();
    obj.addIncludePath(.{ .src_path = .{ .owner = b, .sub_path = devkitpro ++ "/portlibs/3ds/include" } });
    obj.addIncludePath(.{ .src_path = .{ .owner = b, .sub_path = ctru_include_dir } });
    obj.addIncludePath(.{ .src_path = .{ .owner = b, .sub_path = devkitarm_include_dir } });

    const wf = b.addWriteFiles();

    // step 3
    const elf = b.addSystemCommand(&(.{dkp_gcc}));

    elf.setCwd(wf.getDirectory());
    elf.addArgs(&.{
        "-specs=3dsx.specs",
        "-g",
        "-march=armv6k",
        "-mtune=mpcore",
        "-mfloat-abi=hard",
        "-mtp=soft",
    });
    _ = elf.addPrefixedOutputFileArg("-Wl,-Map,", app_filename ++ ".map");
    elf.addArtifactArg(obj);
    elf.addArgs(&.{
        "-L" ++ ctru_lib_dir,
        "-lctru",
    });
    const out_elf = elf.addPrefixedOutputFileArg("-o", app_filename ++ ".elf");

    // step 4
    const icon = ctru_dir ++ "/default_icon.png";
    const smdh = b.addSystemCommand(&.{dkp_smdh});
    smdh.setCwd(wf.getDirectory());
    smdh.addArgs(&.{
        "--create",
        app_title,
        app_description,
        app_author,
        icon,
    });
    const out_smdh = smdh.addOutputFileArg(app_filename ++ ".smdh");

    // step 5
    const dsx = b.addSystemCommand(&.{dkp_3dsx});
    dsx.setCwd(wf.getDirectory());
    dsx.addFileArg(out_elf);
    const out_dsx = dsx.addOutputFileArg(app_filename ++ ".3dsx");
    dsx.addPrefixedFileArg("--smdh=", out_smdh);

    const install_3dsx = b.addInstallFileWithDir(out_dsx, .prefix, app_filename ++ ".3dsx");
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

    // Run on device
    const dslink = b.findProgram(&.{"3dslink"}, &.{devkitpro_tools_dir}) catch "3dslink";
    const upload = b.addSystemCommand(&.{ dslink, "-a", env.ip_3ds });
    upload.addFileArg(out_dsx);
    const upload_step = b.step("launch", "Run in The Homebrew Launcher via 3dslink NetLoader");
    upload_step.dependOn(&upload.step);
}
