"uv based venv generation"

_PY_TOOLCHAIN = "@bazel_tools//tools/python:toolchain_type"

def _uv_template(ctx, template, executable):
    py_toolchain = ctx.toolchains[_PY_TOOLCHAIN]
    if ctx.attr.on_windows:
        site_packages_extra_files = " ".join(['"' + file.short_path.replace("/", "\\") + '"' for file in ctx.files.site_packages_extra_files])
    else:
        site_packages_extra_files = " ".join(["'" + file.short_path + "'" for file in ctx.files.site_packages_extra_files])
    ctx.actions.expand_template(
        template = template,
        output = executable,
        substitutions = {
            "{{uv}}": ctx.executable._uv.short_path.replace("/", "\\"),
            "{{requirements_txt}}": ctx.file.requirements_txt.short_path,
            "{{resolved_python}}": py_toolchain.py3_runtime.interpreter.short_path,
            "{{destination_folder}}": ctx.attr.destination_folder,
            "{{site_packages_extra_files}}": site_packages_extra_files,
        },
    )

def _runfiles(ctx):
    py_toolchain = ctx.toolchains[_PY_TOOLCHAIN]
    runfiles = ctx.runfiles(
        files = [ctx.file.requirements_txt] + ctx.files.site_packages_extra_files,
        transitive_files = py_toolchain.py3_runtime.files,
    )
    runfiles = runfiles.merge(ctx.attr._uv.default_runfiles)
    return runfiles

def _venv_impl(ctx):
    executable = ctx.actions.declare_file(ctx.attr.name)
    if ctx.attr.on_windows:
        _uv_template(ctx, ctx.file._win_template, executable)
    else:
        _uv_template(ctx, ctx.file._template, executable)
    return DefaultInfo(
        executable = executable,
        runfiles = _runfiles(ctx),
    )

_venv = rule(
    attrs = {
        "destination_folder": attr.string(default = "venv"),
        "site_packages_extra_files": attr.label_list(default = [], doc = "Files to add to the site-packages folder inside the virtual environment. Useful for adding `sitecustomize.py` or `.pth` files", allow_files = True),
        "requirements_txt": attr.label(mandatory = True, allow_single_file = True),
        "_uv": attr.label(default = "@multitool//tools/uv", executable = True, cfg = "exec"),
        "_template": attr.label(default = "//uv/private:create_venv.sh", allow_single_file = True),
        "_win_template": attr.label(default = "//uv/private:create_venv.bat", allow_single_file = True),
        "on_windows": attr.bool(default = False),
    },
    toolchains = [_PY_TOOLCHAIN],
    implementation = _venv_impl,
    executable = True,
)

def create_venv(name, requirements_txt = None, target_compatible_with = None, destination_folder = None, site_packages_extra_files = []):
    _venv(
        name = name,
        destination_folder = destination_folder,
        site_packages_extra_files = site_packages_extra_files,
        requirements_txt = requirements_txt or "//:requirements.txt",
        target_compatible_with = target_compatible_with,
        on_windows = select(
            {
                "@platforms//os:windows": True,
                "//conditions:default": False,
            },
        ),
    )
