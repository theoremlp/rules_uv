"uv based export rules"

load("//uv/private:uv_export.bzl", "uv_export_test", _uv_export = "uv_export")

def uv_export(
        name,
        pyproject_toml = None,
        requirements_txt = None,
        target_compatible_with = None,
        args = None,
        extra_args = None,
        data = None,
        tags = None,
        size = None,
        env = None,
        **kwargs):
    """
    Produce targets to compile a pyproject.toml file into a requirements.txt file.

    Args:
        name: name of the primary compilation target.
        pyproject_toml: (optional, default "//:pyproject.toml") a label for the requirements.in file.
        requirements_txt: (optional, default "//:requirements.txt") a label for the requirements.txt file.
        python: (optional) a uv export compatible value for --python.
        target_compatible_with: (optional) specify that a particular target is compatible only with certain
          Bazel platforms.
        args: (optional) override the default arguments passed to uv export, default arguments are:
           --all-extras  (Include all optional dependencies)
           --no-emit-workspace (Do not emit any workspace members, including the root project)
        extra_args: (optional) appends to the default arguments passed to uv export. If both args and
            extra_args are provided, extra_args will be appended to args.
        data: (optional) a list of labels of additional files to include
        tags: (optional) tags to apply to the generated test target
        size: (optional) size of the test target, see https://bazel.build/reference/test-encyclopedia#role-test-runner
        env: (optional) a dictionary of environment variables to set for uv export and the test target
        **kwargs: (optional) other fields passed through to all underlying rules

    Targets produced by this macro are:
      [name]: a runnable target that will use pyproject_toml to generate and overwrite requirements_txt
      [name].update: an alias for [name]
      [name]_test: a testable target that will check that requirements_txt is up to date with pyproject_toml
    """
    pyproject_toml = pyproject_toml or "//:pyproject.toml"
    requirements_txt = requirements_txt or "//:requirements.txt"
    tags = tags or []
    size = size or "small"

    _uv_export(
        name = name,
        pyproject_toml = pyproject_toml,
        requirements_txt = requirements_txt,
        target_compatible_with = target_compatible_with,
        data = data,
        uv_args = args,
        extra_args = extra_args,
        env = env,
        **kwargs
    )

    # Also allow 'bazel run' with a "custom verb" https://bazel.build/rules/verbs-tutorial
    # Provides compatibility with rules_python's compile_pip_requirements [name].update target.
    native.alias(
        name = name + ".update",
        actual = name,
    )

    uv_export_test(
        name = name + "_test",
        generator_label = name,
        pyproject_toml = pyproject_toml,
        requirements_txt = requirements_txt,
        target_compatible_with = target_compatible_with,
        data = data,
        uv_args = args,
        extra_args = extra_args,
        tags = ["requires-network"] + tags,
        size = size,
        env = env,
        **kwargs
    )
