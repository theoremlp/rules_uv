# rules_uv

Bazel rules to enable use of [uv](https://github.com/astral-sh/uv) to compile pip requirements and generate virtual envs.

## Usage

Installing with bzlmod, add to MODULE.bazel (adjust version as appropriate):

```starlark
bazel_dep(name = "rules_uv", version = "<version>")
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

Run the compilation step with `bazel run //:generate_requirements_txt`.

This will automatically register a diff test with name `[name]_diff_test`.

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
