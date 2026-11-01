const std = @import("std");
const ThisBuild = @This();

pub const Options = struct {
    /// The target architecture for which the module will be built.
    target: ?std.Build.ResolvedTarget = null,
    /// The optimization mode used to compile the module.
    optimize: ?std.lang.Optimize = null,
    pub fn initFromOptions(b: *std.Build) Options {
        return .{
            .target = b.standardTargetOptions(.{}),
            .optimize = b.standardOptimizeOption(.{}),
        };
    }

    /// Create the `bit_tree` module in the caller's build graph.
    ///
    /// Intended for parent packages that want a single shared instance:
    /// ```zig
    /// const bit_tree_mod = (@import("bit_tree").Options{
    ///     .target = target,
    ///     .optimize = optimize,
    /// }).getModule(b);
    /// ```
    /// Uses `dependencyFromBuildZig` so source paths stay correct when
    /// called from a parent build via `@import("bit_tree")`.
    pub fn getModule(self: Options, b: *std.Build) *std.Build.Module {
        const target = self.target orelse b.standardTargetOptions(.{});
        const optimize = self.optimize orelse b.standardOptimizeOption(.{});
        const self_dep = b.dependencyFromBuildZig(ThisBuild, .{
            .target = target,
            .optimize = optimize,
        });
        return b.createModule(.{
            .root_source_file = self_dep.path("src/root.zig"),
            .target = target,
            .optimize = optimize,
        });
    }
};

fn createModuleOwn(b: *std.Build, options: Options) *std.Build.Module {
    const target = options.target orelse b.standardTargetOptions(.{});
    const optimize = options.optimize orelse b.standardOptimizeOption(.{});
    return b.addModule("bit_word", .{
        .root_source_file = b.path("src/root.zig"),
        .target = target,
        .optimize = optimize,
    });
}

pub fn build(b: *std.Build) void {
    const options = Options.initFromOptions(b);
    const mod = createModuleOwn(b, options);

    const mod_tests = b.addTest(.{
        .root_module = mod,
    });

    const run_mod_tests = b.addRunArtifact(mod_tests);

    const test_step = b.step("test", "Run tests");
    test_step.dependOn(&run_mod_tests.step);
}
