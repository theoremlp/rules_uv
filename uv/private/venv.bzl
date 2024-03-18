"uv based venv generation"

_PY_TOOLCHAIN = "@bazel_tools//tools/python:toolchain_type"

def _uv_template(ctx, template, executable):
    py_toolchain = ctx.toolchains[_PY_TOOLCHAIN]
    ctx.actions.expand_template(
        template = template,
        output = executable,
        substitutions = {
            "{{uv}}": ctx.executable._uv.short_path,
            "{{requirements_txt}}": ctx.file.requirements_txt.short_path,
            "{{resolved_python}}": py_toolchain.py3_runtime.interpreter.short_path,
        },
    )

def _runfiles(ctx):
    py_toolchain = ctx.toolchains[_PY_TOOLCHAIN]
    runfiles = ctx.runfiles(
        files = [ctx.file.requirements_txt],
        transitive_files = py_toolchain.py3_runtime.files,
    )
    runfiles = runfiles.merge(ctx.attr._uv.default_runfiles)
    return runfiles

def _venv_impl(ctx):
    executable = ctx.actions.declare_file(ctx.attr.name)
    _uv_template(ctx, ctx.file._template, executable)
    return DefaultInfo(
        executable = executable,
        runfiles = _runfiles(ctx),
    )

_venv = rule(
    attrs = {
        "requirements_txt": attr.label(mandatory = True, allow_single_file = True),
        "_uv": attr.label(default = "@multitool//tools/uv", executable = True, cfg = "exec"),
        "_template": attr.label(default = "//uv/private:create_venv.sh", allow_single_file = True),
    },
    toolchains = [_PY_TOOLCHAIN],
    implementation = _venv_impl,
    executable = True,
)

def create_venv(name, requirements_txt = None, target_compatible_with = None):
    _venv(
        name = name,
        requirements_txt = requirements_txt or "//:requirements.txt",
        target_compatible_with = target_compatible_with,
    )
