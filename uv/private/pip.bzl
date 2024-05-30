"uv based pip compile rules"

_PY_TOOLCHAIN = "@bazel_tools//tools/python:toolchain_type"

_COMMON_ATTRS = {
    "requirements_in": attr.label(mandatory = True, allow_single_file = True),
    "requirements_txt": attr.label(mandatory = True, allow_single_file = True),
    "python_platform": attr.string(),
    "_uv": attr.label(default = "@multitool//tools/uv", executable = True, cfg = "exec"),
}

_DEFAULT_ARGS = [
    "--generate-hashes",
    "--emit-index-url",
    "--no-strip-extras",
]

def _python_version(py_toolchain):
    return "{major}.{minor}".format(
        major = py_toolchain.py3_runtime.interpreter_version_info.major,
        minor = py_toolchain.py3_runtime.interpreter_version_info.minor,
    )

def _uv_pip_compile(
        ctx,
        template,
        executable,
        generator_label,
        args):
    py_toolchain = ctx.toolchains[_PY_TOOLCHAIN]
    compile_command = "bazel run {label}".format(label = str(generator_label))

    cmd_args = []
    cmd_args += args
    cmd_args.append("--custom-compile-command='{compile_command}'".format(compile_command = compile_command))
    cmd_args.append("--python-version={version}".format(version = _python_version(py_toolchain)))
    if ctx.attr.python_platform:
        cmd_args.append("--python-platform={platform}".format(platform = ctx.attr.python_platform))

    ctx.actions.expand_template(
        template = template,
        output = executable,
        substitutions = {
            "{{uv}}": ctx.executable._uv.short_path,
            "{{args}}": " \\\n    ".join(cmd_args),
            "{{requirements_in}}": ctx.file.requirements_in.short_path,
            "{{requirements_txt}}": ctx.file.requirements_txt.short_path,
            "{{compile_command}}": compile_command,
            "{{resolved_python}}": py_toolchain.py3_runtime.interpreter.short_path,
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
    _uv_pip_compile(
        ctx = ctx,
        template = ctx.file._template,
        executable = executable,
        generator_label = ctx.label,
        args = ctx.attr.args,
    )
    return DefaultInfo(
        executable = executable,
        runfiles = _runfiles(ctx),
    )

_pip_compile = rule(
    attrs = _COMMON_ATTRS | {
        "_template": attr.label(default = "//uv/private:pip_compile.sh", allow_single_file = True),
    },
    toolchains = [_PY_TOOLCHAIN],
    implementation = _pip_compile_impl,
    executable = True,
)

def _pip_compile_test_impl(ctx):
    executable = ctx.actions.declare_file(ctx.attr.name)
    _uv_pip_compile(
        ctx = ctx,
        template = ctx.file._template,
        executable = executable,
        generator_label = ctx.attr.generator_label.label,
        args = ctx.attr.args,
    )
    return DefaultInfo(
        executable = executable,
        runfiles = _runfiles(ctx),
    )

_pip_compile_test = rule(
    attrs = _COMMON_ATTRS | {
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
        args = None,
        tags = None):
    """
    Produce targets to compile a requirements.in or pyproject.toml file into a requirements.txt file.

    Args:
        name: name of the primary compilation target.
        requirements_in: (optional, default "//:requirements.in") a label for the requirements.in file.
        requirements_txt: (optional, default "//:requirements.txt") a label for the requirements.txt file.
        python_platform: (optional) a uv pip compile compatible value for --python-platform.
        target_compatible_with: (optional) specify that a particular target is compatible only with certain
          Bazel platforms.
        args: (optional) override the default arguments passed to uv pip compile, default arguments are:
           --generate-hashes  (Include distribution hashes in the output file)
           --emit-index-url   (Include `--index-url` and `--extra-index-url` entries in the generated output file)
           --no-strip-extras  (Include extras in the output file)
        tags: (optional) tags to apply to the generated test target

    Targets produced by this macro are:
      [name]: a runnable target that will use requirements_in to generate and overwrite requirements_txt
      [name]_diff_test: a testable target that will check that requirements_txt is up to date with requirements_in
    """
    tags = tags or []
    args = args or _DEFAULT_ARGS

    _pip_compile(
        name = name,
        requirements_in = requirements_in or "//:requirements.in",
        requirements_txt = requirements_txt or "//:requirements.txt",
        python_platform = python_platform,
        target_compatible_with = target_compatible_with,
        args = args,
    )

    _pip_compile_test(
        name = name + "_diff_test",
        generator_label = name,
        requirements_in = requirements_in or "//:requirements.in",
        requirements_txt = requirements_txt or "//:requirements.txt",
        python_platform = python_platform or "",
        target_compatible_with = target_compatible_with,
        args = args,
        tags = ["requires-network"] + tags,
    )
