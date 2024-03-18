"uv based virtual env generation"

load("//uv/private:venv.bzl", _create_venv = "create_venv")

create_venv = _create_venv
