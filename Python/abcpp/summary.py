from . import _core


def summary(result, unadj=False, intvl=0.95):
    """Summarize posterior draws returned by :func:`abcpp.abc`."""
    return _core.summary(result, unadj=bool(unadj), intvl=float(intvl))
