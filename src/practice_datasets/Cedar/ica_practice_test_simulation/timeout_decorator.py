"""No-op stand-in for CodeSignal's ``timeout_decorator`` (local / offline runs)."""


def timeout(_seconds: float):
    def decorator(func):
        return func

    return decorator
