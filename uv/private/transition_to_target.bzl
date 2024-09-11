"Helper rule to ensure that uv is resolved for the target architecture"

def _transition_to_target_impl(settings, _attr):
    return {
        # String conversion is needed to prevent a crash with Bazel 6.x.
        "//command_line_option:extra_execution_platforms": [
            str(platform)
            for platform in settings["//command_line_option:platforms"]
        ],
    }

transition_to_target = transition(
    implementation = _transition_to_target_impl,
    inputs = ["//command_line_option:platforms"],
    outputs = ["//command_line_option:extra_execution_platforms"],
)
