# rules_uv

Bazel rules to enable use of [uv](https://github.com/astral-sh/uv) to compile pip requirements and generate virtual envs.

## Usage

Installing with bzlmod, add to MODULE.bazel (adjust version as appropriate):

```starlark
bazel_dep(name = "rules_uv", version = "<version>")
```

**Note**: rules_uv requires a Python toolchain to be available. One can be obtained by having [rules_python](https://github.com/bazelbuild/rules_python) installed using:

```starlark
bazel_dep(name = "rules_python", version = "<rules_python version>")
```

### pip_compile

Create a requirements.in or pyproject.toml -> requirements.txt compilation target and diff test:

```starlark
load("@rules_uv//uv:pip.bzl", "pip_compile")

pip_compile(
    name = "generate_requirements_txt",
    requirements_in = "//:requirements.in", # default
    requirements_txt = "//:requirements.txt", # default
)
```

Ensure both requirements.in and requirements.txt exist (the latter must exist but may be empty).

Run the compilation step with `bazel run //:generate_requirements_txt`.

This will automatically register a diff test with name `[name]_test`.

Additionally, you can specify the following optional args:

- `python_platform`: the `uv pip compile` compatible `--python-platform` value to pass to uv
- `args`: override the default arguments passed to uv (`--generate-hashes`, `--emit-index-url` and `--no-strip-extras`)
- `data`: pass additional files to be present when generating and testing requirements txt files (see also [examples/multiple-inputs](examples/multiple-inputs/))
- `tags`: tags to apply to the test target
- `target_compatible_with`: restrict targets to running on the specified Bazel platform
- `requirements_overrides`: a label for the file that is used to override dependencies (passed to uv via `--overrides`)

### create_venv

Create a virtual environment creation target:

```starlark
load("@rules_uv//uv:venv.bzl", "create_venv")

create_venv(
    name = "create_venv",
    requirements_txt = "//:requirements.txt", # default
)
```

Create a virtual environment with default path `venv` by running `bazel run //:create_venv`. The generated script accepts a single, optional argument to define the virtual environment path.

The created venv will use the default Python 3 runtime defined in rules_python.

## Multi-platform setup

`uv` supports generating platform-specific requirements files, and `rules_uv` exposes this configuration, and a multi-platform setup might look like this:

```starlark
load("@rules_multirun//:defs.bzl", "multirun")
load("@rules_uv//uv:pip.bzl", "pip_compile")
load("@rules_uv//uv:venv.bzl", "create_venv")

pip_compile(
    name = "generate_requirements_linux_txt",
    python_platform = "x86_64-unknown-linux-gnu",
    requirements_txt = "requirements_linux.txt",
)

pip_compile(
    name = "generate_requirements_macos_txt",
    python_platform = "aarch64-apple-darwin",
    requirements_txt = "requirements_macos.txt",
)

multirun(
    name = "generate_requirements_lock",
    commands = [
        ":generate_requirements_linux_txt",
        ":generate_requirements_macos_txt",
    ],
    # Running in a single threaded mode allows consecutive `uv` invocations to benefit
    # from the `uv` cache from the first run.
    jobs = 1,
)

create_venv(
    name = "create_venv",
    requirements_txt = select({
        "@platforms//os:linux": ":requirements_linux.txt",
        "@platforms//os:osx": ":requirements_macos.txt",
    }),
)
```

This makes use of the excellent [rules_multirun](https://github.com/keith/rules_multirun).

To match up with `rules_python`, a bzlmod config will look something like:

```starlark
pip.parse(
    hub_name = "pip",
    python_version = "3.11",
    requirements_darwin = "//:requirements_macos.txt",
    requirements_linux = "//:requirements_linux.txt",
)
```
