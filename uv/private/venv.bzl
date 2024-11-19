"uv based venv generation"

load(":transition_to_target.bzl", "transition_to_target")

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
            "{{destination_folder}}": ctx.attr.destination_folder,
            "{{site_packages_extra_files}}": " ".join(["'" + file.short_path + "'" for file in ctx.files.site_packages_extra_files]),
            "{{args}}": " \\\n    ".join(ctx.attr.uv_args),
        },
    )

def _runfiles(ctx):
    py_toolchain = ctx.toolchains[_PY_TOOLCHAIN]
    runfiles = ctx.runfiles(
        files = [ctx.file.requirements_txt] + ctx.files.site_packages_extra_files,
        transitive_files = py_toolchain.py3_runtime.files,
    )
    runfiles = runfiles.merge(ctx.attr._uv[0].default_runfiles)
    return runfiles

def _venv_impl(ctx):
    executable = ctx.actions.declare_file(ctx.attr.name)
    _uv_template(ctx, ctx.file.template, executable)
    return DefaultInfo(
        executable = executable,
        runfiles = _runfiles(ctx),
    )

_venv = rule(
    attrs = {
        "destination_folder": attr.string(default = "venv"),
        "site_packages_extra_files": attr.label_list(default = [], doc = "Files to add to the site-packages folder inside the virtual environment. Useful for adding `sitecustomize.py` or `.pth` files", allow_files = True),
        "requirements_txt": attr.label(mandatory = True, allow_single_file = True),
        "_uv": attr.label(default = "@multitool//tools/uv", executable = True, cfg = transition_to_target),
        "template": attr.label(allow_single_file = True),
        "uv_args": attr.string_list(default = []),
    },
    toolchains = [_PY_TOOLCHAIN],
    implementation = _venv_impl,
    executable = True,
)

def create_venv(name, requirements_txt = None, target_compatible_with = None, destination_folder = None, site_packages_extra_files = [], uv_args = []):
    _venv(
        name = name,
        destination_folder = destination_folder,
        site_packages_extra_files = site_packages_extra_files,
        requirements_txt = requirements_txt or "//:requirements.txt",
        target_compatible_with = target_compatible_with,
        uv_args = uv_args,
        template = "@rules_uv//uv/private:create_venv.sh",
    )

def sync_venv(name, requirements_txt = None, target_compatible_with = None, destination_folder = None, site_packages_extra_files = [], uv_args = []):
    _venv(
        name = name,
        destination_folder = destination_folder,
        site_packages_extra_files = site_packages_extra_files,
        requirements_txt = requirements_txt or "//:requirements.txt",
        target_compatible_with = target_compatible_with,
        uv_args = uv_args,
        template = "@rules_uv//uv/private:sync_venv.sh",
    )
