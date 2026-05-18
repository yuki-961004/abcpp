import math

import numpy
import pytest


@pytest.fixture
def toy_data():
    n = 240
    theta_1 = numpy.linspace(0.05, 0.95, n)
    theta_2 = numpy.linspace(0.90, 0.10, n)

    param = numpy.column_stack((theta_1, theta_2))
    sumstat = numpy.column_stack((
        theta_1,
        theta_2,
        theta_1 * theta_2,
        numpy.sin(theta_1 * math.pi),
    ))
    target = numpy.asarray([
        0.45,
        0.55,
        0.45 * 0.55,
        math.sin(0.45 * math.pi),
    ])

    return {
        "param": param,
        "sumstat": sumstat,
        "target": target,
    }
