This is a very basic template to kickstart _your_ zig adventures on 3DS 🦎

Here be dragons - zig is still in development and things might have changed
already!<br> It actually just exists because others were outdated.

## Dependencies

- zig >= `0.14.0`
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
