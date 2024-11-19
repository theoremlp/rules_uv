"uv based virtual env generation"

load("//uv/private:venv.bzl", _create_venv = "create_venv", _sync_venv = "sync_venv")

create_venv = _create_venv
sync_venv = _sync_venv
