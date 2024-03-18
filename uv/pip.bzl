"uv based pip compile rules"

load("//uv/private:pip.bzl", _pip_compile = "pip_compile")

pip_compile = _pip_compile
