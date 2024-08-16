"uv based pip compile rules"

_PY_TOOLCHAIN = "@bazel_tools//tools/python:toolchain_type"

_DEFAULT_ARGS = [
    "--generate-hashes",
    "--emit-index-url",
    "--no-strip-extras",
]

_COMMON_ATTRS = {
    "requirements_in": attr.label(mandatory = True, allow_single_file = True),
    "requirements_txt": attr.label(mandatory = True, allow_single_file = True),
    "python_platform": attr.string(),
    "data": attr.label_list(allow_files = True),
    "uv_args": attr.string_list(default = _DEFAULT_ARGS),
    "on_windows": attr.bool(default = False),
    "_uv": attr.label(default = "@multitool//tools/uv", executable = True, cfg = "exec"),
}

def _python_version(py_toolchain):
    # micro is useful when there are some packages that exclude .0 versions due
    # to a bug, such as !=3.11.0
    return "{major}.{minor}.{micro}".format(
        major = py_toolchain.py3_runtime.interpreter_version_info.major,
        minor = py_toolchain.py3_runtime.interpreter_version_info.minor,
        micro = py_toolchain.py3_runtime.interpreter_version_info.micro,
    )

def _uv_pip_compile(
        ctx,
        template,
        executable,
        generator_label,
        uv_args):
    py_toolchain = ctx.toolchains[_PY_TOOLCHAIN]
    compile_command = "bazel run {label}".format(label = str(generator_label))

    args = []
    args += uv_args

    args.append("--python={python}".format(python = py_toolchain.py3_runtime.interpreter.short_path))
    args.append("--python-version={version}".format(version = _python_version(py_toolchain)))
    if ctx.attr.python_platform:
        args.append("--python-platform={platform}".format(platform = ctx.attr.python_platform))
    if ctx.attr.on_windows:
        uv = ctx.executable._uv.short_path.replace("/", "\\")
        requirements_in = ctx.file.requirements_in.short_path.replace("/", "\\")
        requirements_txt = ctx.file.requirements_txt.short_path.replace("/", "\\")
        args = [arg.replace("/", "\\") for arg in args]
        args.append('--custom-compile-command="{compile_command}"'.format(compile_command = compile_command))
        args = " ^\n    ".join(args)
    else:
        args.append("--custom-compile-command='{compile_command}'".format(compile_command = compile_command))
        uv = ctx.executable._uv.short_path
        requirements_in = ctx.file.requirements_in.short_path
        requirements_txt = ctx.file.requirements_txt.short_path
        args = " \\\n    ".join(args)
    ctx.actions.expand_template(
        template = template,
        output = executable,
        substitutions = {
            "{{uv}}": uv,
            "{{args}}": args,
            "{{requirements_in}}": requirements_in,
            "{{requirements_txt}}": requirements_txt,
            "{{compile_command}}": compile_command,
        },
    )

def _runfiles(ctx):
    py_toolchain = ctx.toolchains[_PY_TOOLCHAIN]
    runfiles = ctx.runfiles(
        files = [ctx.file.requirements_in, ctx.file.requirements_txt] + ctx.files.data,
        transitive_files = py_toolchain.py3_runtime.files,
    )
    runfiles = runfiles.merge(ctx.attr._uv.default_runfiles)
    return runfiles

def _pip_compile_impl(ctx):
    executable = ctx.actions.declare_file(ctx.attr.name)
    _uv_pip_compile(
        ctx = ctx,
        template = ctx.file._template_win if ctx.attr.on_windows else ctx.file._template,
        executable = executable,
        generator_label = ctx.label,
        uv_args = ctx.attr.uv_args,
    )
    return DefaultInfo(
        executable = executable,
        runfiles = _runfiles(ctx),
    )

_pip_compile = rule(
    attrs = _COMMON_ATTRS | {
        "_template": attr.label(default = "//uv/private:pip_compile.sh", allow_single_file = True),
        "_template_win": attr.label(default = "//uv/private:pip_compile.bat", allow_single_file = True),
    },
    toolchains = [_PY_TOOLCHAIN],
    implementation = _pip_compile_impl,
    executable = True,
)

def _pip_compile_test_impl(ctx):
    executable = ctx.actions.declare_file(ctx.attr.name)
    _uv_pip_compile(
        ctx = ctx,
        template = ctx.file._template_win if ctx.attr.on_windows else ctx.file._template,
        executable = executable,
        generator_label = ctx.attr.generator_label.label,
        uv_args = ctx.attr.uv_args,
    )
    return [
        DefaultInfo(
            executable = executable,
            runfiles = _runfiles(ctx),
        ),
        RunEnvironmentInfo(
            # Ensures that .netrc can be detected by uv
            # See https://github.com/theoremlp/rules_uv/issues/103
            inherited_environment = ["HOME"],
        ),
    ]

_pip_compile_test = rule(
    attrs = _COMMON_ATTRS | {
        "generator_label": attr.label(mandatory = True),
        "_template": attr.label(default = "//uv/private:pip_compile_test.sh", allow_single_file = True),
        "_template_win": attr.label(default = "//uv/private:pip_compile_test.bat", allow_single_file = True),
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
        data = None,
        tags = None,
        test_name = None,
        **kwargs):
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
        data: (optional) a list of labels of additional files to include
        tags: (optional) tags to apply to the generated test target
        test_name: (optional) name of the test target, defaults to name + "_test".
        **kwargs: (optional) other fields passed through to all underlying rules

    Targets produced by this macro are:
      [name]: a runnable target that will use requirements_in to generate and overwrite requirements_txt
      [name].update: an alias for [name]
      [name]_test: a testable target that will check that requirements_txt is up to date with requirements_in
    """
    tags = tags or []

    _pip_compile(
        name = name,
        requirements_in = requirements_in or "//:requirements.in",
        requirements_txt = requirements_txt or "//:requirements.txt",
        python_platform = python_platform,
        target_compatible_with = target_compatible_with,
        data = data,
        uv_args = args,
        on_windows = select(
            {
                "@platforms//os:windows": True,
                "//conditions:default": False,
            },
        ),
        **kwargs
    )

    # Also allow 'bazel run' with a "custom verb" https://bazel.build/rules/verbs-tutorial
    # Provides compatibility with rules_python's compile_pip_requirements [name].update target.
    native.alias(
        name = name + ".update",
        actual = name,
    )

    _pip_compile_test(
        name = name + "_test" if (test_name == None) else test_name,
        generator_label = name,
        requirements_in = requirements_in or "//:requirements.in",
        requirements_txt = requirements_txt or "//:requirements.txt",
        python_platform = python_platform or "",
        target_compatible_with = target_compatible_with,
        data = data,
        uv_args = args,
        on_windows = select(
            {
                "@platforms//os:windows": True,
                "//conditions:default": False,
            },
        ),
        tags = ["requires-network"] + tags,
        **kwargs
    )
