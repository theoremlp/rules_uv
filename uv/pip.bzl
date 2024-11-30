"uv based pip compile rules"

load("@bazel_skylib//lib:types.bzl", "types")
load("@bazel_skylib//rules:write_file.bzl", "write_file")
load("//uv/private:pip.bzl", "pip_compile_test", _pip_compile = "pip_compile")

def pip_compile(
        name,
        requirements_in = None,
        requirements_ins = [],
        requirements_txt = None,
        target_compatible_with = None,
        python_platform = None,
        args = None,
        data = None,
        tags = None,
        **kwargs):
    """
    Produce targets to compile a requirements.in or pyproject.toml file into a requirements.txt file.

    Args:
        name: name of the primary compilation target.
        requirements_in: (optional, default "//:requirements.in") a label for the requirements.in file.
            May also be provided as a list of strings which represent the requirements file lines.
        requirements_ins: (optional, default []) a list of labels for additional requirements.in files.
            These files will be concatenated together in the order they are provided.
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
        **kwargs: (optional) other fields passed through to all underlying rules

    Targets produced by this macro are:
      [name]: a runnable target that will use requirements_in to generate and overwrite requirements_txt
      [name].update: an alias for [name]
      [name]_test: a testable target that will check that requirements_txt is up to date with requirements_in
    """

    if requirements_ins:
        if requirements_in:
            fail("Cannot provide both requirements_in and requirements_ins")
        write_target = "_{}.write".format(name)
        native.genrule(
            name = write_target,
            srcs = requirements_ins,
            outs = ["_{}.in".format(name)],
            # use `awk 1` instead of `cat` ensures trailing newlines for each file
            cmd = "awk 1 {} > $(OUTS)".format(" ".join(["$(location {})".format(r) for r in requirements_ins])),
        )
        requirements_in = write_target

    requirements_in = requirements_in or "//:requirements.in"
    requirements_txt = requirements_txt or "//:requirements.txt"
    tags = tags or []
    if types.is_list(requirements_in):
        write_target = "_{}.write".format(name)
        write_file(
            name = write_target,
            out = "_{}.in".format(name),
            content = requirements_in,
        )
        requirements_in = write_target

    _pip_compile(
        name = name,
        requirements_in = requirements_in,
        requirements_txt = requirements_txt,
        python_platform = python_platform,
        target_compatible_with = target_compatible_with,
        data = data,
        uv_args = args,
        **kwargs
    )

    # Also allow 'bazel run' with a "custom verb" https://bazel.build/rules/verbs-tutorial
    # Provides compatibility with rules_python's compile_pip_requirements [name].update target.
    native.alias(
        name = name + ".update",
        actual = name,
    )

    pip_compile_test(
        name = name + "_test",
        generator_label = name,
        requirements_in = requirements_in,
        requirements_txt = requirements_txt,
        python_platform = python_platform or "",
        target_compatible_with = target_compatible_with,
        data = data,
        uv_args = args,
        tags = ["requires-network"] + tags,
        **kwargs
    )
