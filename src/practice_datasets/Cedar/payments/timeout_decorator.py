"""No-op stand-in for CodeSignal's ``timeout_decorator`` (local runs)."""


def timeout(_seconds: float):
    def decorator(func):
        return func

    return decorator
