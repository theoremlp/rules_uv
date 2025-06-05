"Helper to handle local vs hermetic Python toolchains"

def python_interpreter_path(py3_runtime):
    if py3_runtime.interpreter:
        return py3_runtime.interpreter.short_path
    return py3_runtime.interpreter_path
