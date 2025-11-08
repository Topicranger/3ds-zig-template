This is a very basic template to kickstart _your_ zig adventures on 3DS 🦎

> [!WARNING]
> This template is outdated and doesn't build in newer versions of zig.
> <br>It actually just exists because others were even older at the time.
> <br>A keen eye should be able to fix the problem; PRs welcome!

## Dependencies

- zig = `0.14.1`
- devkitPro for 3ds development

## Usage

Make a copy of the environment file `env.zig.zon.sample` and rename it to
`env.zig.zon`. Alternatively, run `cp env.zig.zon.sample env.zig.zon`.
Then, edit it to set the path of your devkitPro installation and the IP
address of your 3DS.

The following build options are now available:

- `zig build 3ds` - builds to zig-out
- `zig build run` - builds and runs the app in an emulator
- `zig build launch` - builds and runs the app in the homebrew launcher via
  3dslink NetLoader

App description and more are stored in the buildfile. Customize it and make it
your own!
