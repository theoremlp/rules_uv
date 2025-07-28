"uv based export rules"

load("@rules_python//python:defs.bzl", "PyRuntimeInfo")
load(":transition_to_target.bzl", "transition_to_target")

_PY_TOOLCHAIN = "@bazel_tools//tools/python:toolchain_type"

_DEFAULT_ARGS = [
    "--all-extras",
    "--no-emit-workspace",
    "--no-sources"
]

_COMMON_ATTRS = {
    "pyproject_toml": attr.label(mandatory = True, allow_single_file = True),
    "requirements_txt": attr.label(mandatory = True, allow_single_file = True),
    "python_platform": attr.string(),
    "py3_runtime": attr.label(),
    "data": attr.label_list(allow_files = True),
    "uv_args": attr.string_list(default = _DEFAULT_ARGS),
    "extra_args": attr.string_list(),
    "env": attr.string_dict(),
    "_uv": attr.label(default = "@multitool//tools/uv", executable = True, cfg = transition_to_target),
}

def _python_runtime(ctx):
    if ctx.attr.py3_runtime:
        return ctx.attr.py3_runtime[PyRuntimeInfo]
    py_toolchain = ctx.toolchains[_PY_TOOLCHAIN]
    return py_toolchain.py3_runtime

def _uv_export(
        ctx,
        template,
        executable,
        generator_label,
        uv_args,
        extra_args):
    py3_runtime = _python_runtime(ctx)
    compile_command = "bazel run {label}".format(label = str(generator_label))

    args = []
    args += uv_args
    args += extra_args
    args.append("--python={python}".format(python = py3_runtime.interpreter.short_path))

    ctx.actions.expand_template(
        template = template,
        output = executable,
        substitutions = {
            "{{uv}}": ctx.executable._uv.short_path,
            "{{args}}": " \\\n    ".join(args),
            "{{requirements_txt}}": ctx.file.requirements_txt.short_path,
            "{{compile_command}}": compile_command,
        },
    )

def _runfiles(ctx):
    py3_runtime = _python_runtime(ctx)
    runfiles = ctx.runfiles(
        files = [ctx.file.pyproject_toml, ctx.file.requirements_txt] + ctx.files.data,
        transitive_files = py3_runtime.files,
    )
    runfiles = runfiles.merge(ctx.attr._uv[0].default_runfiles)
    return runfiles

def _uv_export_impl(ctx):
    executable = ctx.actions.declare_file(ctx.attr.name)
    _uv_export(
        ctx = ctx,
        template = ctx.file._template,
        executable = executable,
        generator_label = ctx.label,
        uv_args = ctx.attr.uv_args,
        extra_args = ctx.attr.extra_args,
    )
    return [
        DefaultInfo(
            executable = executable,
            runfiles = _runfiles(ctx),
        ),
        RunEnvironmentInfo(
            environment = ctx.attr.env,
        ),
    ]

uv_export = rule(
    attrs = _COMMON_ATTRS | {
        "_template": attr.label(default = "//uv/private:uv_export.sh", allow_single_file = True),
    },
    toolchains = [_PY_TOOLCHAIN],
    implementation = _uv_export_impl,
    executable = True,
)

def _uv_export_test_impl(ctx):
    executable = ctx.actions.declare_file(ctx.attr.name)
    _uv_export(
        ctx = ctx,
        template = ctx.file._template,
        executable = executable,
        generator_label = ctx.attr.generator_label.label,
        uv_args = ctx.attr.uv_args,
        extra_args = ctx.attr.extra_args,
    )

    return [
        DefaultInfo(
            executable = executable,
            runfiles = _runfiles(ctx),
        ),
        RunEnvironmentInfo(
            environment = ctx.attr.env,
            # Ensures that .netrc can be detected by uv
            # See https://github.com/theoremlp/rules_uv/issues/103
            inherited_environment = ["HOME"],
        ),
    ]

uv_export_test = rule(
    attrs = _COMMON_ATTRS | {
        "generator_label": attr.label(mandatory = True),
        "_template": attr.label(default = "//uv/private:uv_export_test.sh", allow_single_file = True),
    },
    toolchains = [_PY_TOOLCHAIN],
    implementation = _uv_export_test_impl,
    test = True,
)
