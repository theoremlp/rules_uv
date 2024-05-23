"uv based pip compile rules"

_PY_TOOLCHAIN = "@bazel_tools//tools/python:toolchain_type"

_common_attrs = {
    "requirements_in": attr.label(mandatory = True, allow_single_file = True),
    "requirements_txt": attr.label(mandatory = True, allow_single_file = True),
    "python_platform": attr.string(default = ""),
    "generate_hashes": attr.bool(default = True),
    "emit_index_url": attr.bool(default = True),
    "no_strip_extras": attr.bool(default = True),
    "custom_compile_command": attr.string(default = ""),
    "_uv": attr.label(default = "@multitool//tools/uv", executable = True, cfg = "exec"),
}

def _python_platform(maybe_python_platform):
    if maybe_python_platform == "":
        return ""
    return "--python-platform {python_platform}".format(python_platform = maybe_python_platform)

def _pip_compile_args(ctx):
    custom_compile_command = ctx.attr.custom_compile_command or "bazel run {label}".format(label = ctx.label)
    return " ".join(
        [
            "--generate-hashes" if ctx.attr.generate_hashes else "",
            "--emit-index-url" if ctx.attr.emit_index_url else "",
            "--no-strip-extras" if ctx.attr.no_strip_extras else "",
            "--custom-compile-command \"{custom_compile_command}\"".format(custom_compile_command = custom_compile_command),
        ],
    )

def _uv_pip_compile(ctx, template, executable, generator_label):
    py_toolchain = ctx.toolchains[_PY_TOOLCHAIN]
    ctx.actions.expand_template(
        template = template,
        output = executable,
        substitutions = {
            "{{uv}}": ctx.executable._uv.short_path,
            "{{requirements_in}}": ctx.file.requirements_in.short_path,
            "{{requirements_txt}}": ctx.file.requirements_txt.short_path,
            "{{resolved_python}}": py_toolchain.py3_runtime.interpreter.short_path,
            "{{python_platform}}": _python_platform(ctx.attr.python_platform),
            "{{pip_compile_args}}": _pip_compile_args(ctx),
            "{{label}}": str(generator_label),
        },
    )

def _runfiles(ctx):
    py_toolchain = ctx.toolchains[_PY_TOOLCHAIN]
    runfiles = ctx.runfiles(
        files = [ctx.file.requirements_in, ctx.file.requirements_txt],
        transitive_files = py_toolchain.py3_runtime.files,
    )
    runfiles = runfiles.merge(ctx.attr._uv.default_runfiles)
    return runfiles

def _pip_compile_impl(ctx):
    executable = ctx.actions.declare_file(ctx.attr.name)
    _uv_pip_compile(ctx, ctx.file._template, executable, ctx.label)
    return DefaultInfo(
        executable = executable,
        runfiles = _runfiles(ctx),
    )

_pip_compile = rule(
    attrs = _common_attrs | {
        "_template": attr.label(default = "//uv/private:pip_compile.sh", allow_single_file = True),
    },
    toolchains = [_PY_TOOLCHAIN],
    implementation = _pip_compile_impl,
    executable = True,
)

def _pip_compile_test_impl(ctx):
    executable = ctx.actions.declare_file(ctx.attr.name)
    _uv_pip_compile(ctx, ctx.file._template, executable, ctx.attr.generator_label.label)
    return DefaultInfo(
        executable = executable,
        runfiles = _runfiles(ctx),
    )

_pip_compile_test = rule(
    attrs = _common_attrs | {
        "generator_label": attr.label(mandatory = True),
        "_template": attr.label(default = "//uv/private:pip_compile_test.sh", allow_single_file = True),
    },
    toolchains = [_PY_TOOLCHAIN],
    implementation = _pip_compile_test_impl,
    test = True,
)

def pip_compile(
        name,
        requirements_in = None,
        requirements_txt = None,
        target_compatible_with = None,
        python_platform = None,
        tags = None,
        generate_hashes = True,
        emit_index_url = True,
        no_strip_extras = True,
        custom_compile_command = None
    ):
    tags = tags or []

    _pip_compile(
        name = name,
        requirements_in = requirements_in or "//:requirements.in",
        requirements_txt = requirements_txt or "//:requirements.txt",
        python_platform = python_platform or "",
        target_compatible_with = target_compatible_with,
        generate_hashes = generate_hashes,
        emit_index_url = emit_index_url,
        no_strip_extras = no_strip_extras,
        custom_compile_command = custom_compile_command,
    )

    _pip_compile_test(
        name = name + "_diff_test",
        generator_label = name,
        requirements_in = requirements_in or "//:requirements.in",
        requirements_txt = requirements_txt or "//:requirements.txt",
        python_platform = python_platform or "",
        target_compatible_with = target_compatible_with,
        generate_hashes = generate_hashes,
        emit_index_url = emit_index_url,
        no_strip_extras = no_strip_extras,
        custom_compile_command = custom_compile_command,
        tags = ["requires-network"] + tags,
    )
