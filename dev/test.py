"""Manual development script for the Python abcpp frontend."""

import csv
import pathlib
import sys

import numpy


############################
# Development Package Setup
############################

# 这里优先使用本项目开发测试时安装的 Python 包路径.
# % pip install -e ./Python --config-settings=build-dir="build"

import abcpp


############################
# Shared Helper Functions
############################


def safe_mean(values):
    """Return zero for empty vectors, matching the R dev script."""
    # 这里把输入转成 float array, 方便统一处理布尔和整数向量.
    values = numpy.asarray(values, dtype=float)

    # 空子集没有可估计均值, 开发脚本中用 0 保持摘要长度稳定.
    if values.size == 0:
        return 0.0

    return float(numpy.mean(values))


def posterior_mean(result):
    """Return adjusted posterior mean when adjustment is available."""
    # regression 方法会返回 adj_values, rejection 则主要使用 unadj_values.
    adjusted = numpy.asarray(result["adj_values"], dtype=float)
    if adjusted.size > 0:
        return numpy.mean(adjusted, axis=0)

    return numpy.mean(numpy.asarray(result["unadj_values"], dtype=float),
                      axis=0)


def print_table(title, rows):
    """Print a small list-of-dicts table without adding pandas."""
    print(f"\n\n=== {title} ===")

    # 空表直接返回, 避免下面读取 keys 时出错.
    if not rows:
        print("(empty)")
        return

    columns = list(rows[0].keys())
    widths = {
        column: max(
            len(str(column)),
            max(len(str(row[column])) for row in rows),
        )
        for column in columns
    }

    header = "  ".join(str(column).ljust(widths[column])
                       for column in columns)
    print(header)
    print("  ".join("-" * widths[column] for column in columns))

    for row in rows:
        print("  ".join(str(row[column]).ljust(widths[column])
                        for column in columns))


def rounded_vector(values, digits=6):
    """Format a numeric vector for compact final reporting."""
    values = numpy.asarray(values, dtype=float)
    return "[" + ", ".join(f"{value:.{digits}f}" for value in values) + "]"


###############################################################################
# Section 1: Minimal ABC Sanity Check
###############################################################################

# 这里构造二维 toy ABC bank, 避免 loclinear 遇到共线设计矩阵.
toy_theta_1_grid = numpy.linspace(0.05, 0.95, 10)
toy_theta_2_grid = numpy.linspace(0.10, 0.90, 9)
toy_mesh_1, toy_mesh_2 = numpy.meshgrid(toy_theta_1_grid,
                                        toy_theta_2_grid)
toy_theta_1 = toy_mesh_1.ravel()
toy_theta_2 = toy_mesh_2.ravel()
toy_param = numpy.column_stack((toy_theta_1, toy_theta_2))

# 这里让 summary statistics 同时包含线性和非线性信息.
toy_sumstat = numpy.column_stack((
    toy_theta_1 + 0.25 * toy_theta_2,
    toy_theta_1 * toy_theta_1 - 0.10 * toy_theta_2,
    toy_theta_2 * toy_theta_2 + 0.10 * toy_theta_1,
    numpy.sin(numpy.pi * toy_theta_1) +
    numpy.cos(numpy.pi * toy_theta_2),
))
toy_target_param = numpy.asarray([0.45, 0.55], dtype=float)
toy_target = numpy.asarray(
    [
        toy_target_param[0] + 0.25 * toy_target_param[1],
        toy_target_param[0] * toy_target_param[0] -
        0.10 * toy_target_param[1],
        toy_target_param[1] * toy_target_param[1] +
        0.10 * toy_target_param[0],
        numpy.sin(numpy.pi * toy_target_param[0]) +
        numpy.cos(numpy.pi * toy_target_param[1]),
    ],
    dtype=float,
)

toy_rejection = abcpp.abc(
    target=toy_target,
    param=toy_param,
    sumstat=toy_sumstat,
    tol=0.10,
    method="rejection",
    transf=["none", "none"],
    reduce="none",
)
toy_loclinear = abcpp.abc(
    target=toy_target,
    param=toy_param,
    sumstat=toy_sumstat,
    tol=0.20,
    method="loclinear",
    hcorr=False,
    transf=["none", "none"],
    reduce="none",
)
toy_target_matrix = toy_target.reshape((2, 2))
toy_sumstat_matrices = {
    f"sim_{index}": row.reshape((2, 2))
    for index, row in enumerate(toy_sumstat)
}
toy_matrix_list = abcpp.abc(
    target=toy_target_matrix,
    param=toy_param,
    sumstat=toy_sumstat_matrices,
    tol=0.10,
    method="rejection",
    transf=["none", "none"],
    reduce="none",
)

toy_region = numpy.asarray(toy_rejection["region"], dtype=bool)
toy_matrix_region = numpy.asarray(toy_matrix_list["region"], dtype=bool)
toy_expected_accept = int(numpy.ceil(toy_param.shape[0] * 0.10))
toy_unadjusted_diff = numpy.max(numpy.abs(
    numpy.asarray(toy_rejection["unadj_values"], dtype=float) -
    toy_param[toy_region, :],
))
toy_matrix_list_diff = numpy.max(numpy.abs(
    numpy.asarray(toy_matrix_list["unadj_values"], dtype=float) -
    toy_param[toy_matrix_region, :],
))
toy_rows = [
    {
        "check": "rejection_accepted_count",
        "value": int(numpy.sum(toy_region)),
        "expected": toy_expected_accept,
    },
    {
        "check": "rejection_posterior_max_abs_diff",
        "value": f"{toy_unadjusted_diff:.6g}",
        "expected": "0",
    },
    {
        "check": "loclinear_posterior_mean",
        "value": rounded_vector(posterior_mean(toy_loclinear)),
        "expected": "finite",
    },
    {
        "check": "matrix_list_numstat",
        "value": toy_matrix_list["numstat"],
        "expected": 4,
    },
    {
        "check": "matrix_list_posterior_max_abs_diff",
        "value": f"{toy_matrix_list_diff:.6g}",
        "expected": "0",
    },
]
print_table("Minimal Python ABC Sanity Check", toy_rows)

# 这里清理 toy 中间对象, 只让控制台保留最终汇总.
del toy_theta_1_grid
del toy_theta_2_grid
del toy_mesh_1
del toy_mesh_2
del toy_theta_1
del toy_theta_2
del toy_param
del toy_sumstat
del toy_target_param
del toy_target
del toy_rejection
del toy_loclinear
del toy_target_matrix
del toy_sumstat_matrices
del toy_matrix_list
del toy_region
del toy_matrix_region
del toy_expected_accept
del toy_unadjusted_diff
del toy_matrix_list_diff
del toy_rows


###############################################################################
# Section 2: Simple Signal Detection Theory Validation
###############################################################################


def sdt_summary(stim, resp, conf):
    """Convert trial-level SDT data into matrix-like summary statistics."""
    signal = stim == 1
    noise = stim == 0
    correct = stim == resp

    out_names = [
        "hit",
        "false_alarm",
        "mean_conf",
        "high_conf",
        "correct_high_conf",
        "error_high_conf",
    ]
    out_values = [
        safe_mean(resp[signal] == 1),
        safe_mean(resp[noise] == 1),
        safe_mean(conf),
        safe_mean(conf >= 3),
        safe_mean(conf[correct] >= 3),
        safe_mean(conf[~correct] >= 3),
    ]

    # 这里保留置信度分布, 但省略最后一档以避免线性冗余.
    for stim_level in (0, 1):
        stim_mask = stim == stim_level
        for conf_level in (1, 2, 3):
            out_names.append(f"p_s{stim_level}_conf{conf_level}")
            out_values.append(safe_mean(conf[stim_mask] == conf_level))

    return out_names, numpy.asarray(out_values, dtype=float)


def simulate_sdt(stim, d_value, criterion, rng):
    """Simulate a minimal equal-variance SDT model."""
    # signal trial 的 evidence 均值为 d, noise trial 的均值为 0.
    evidence_mean = numpy.where(stim == 1, d_value, 0.0)
    evidence = rng.normal(loc=evidence_mean, scale=1.0, size=stim.size)
    resp = (evidence > criterion).astype(int)

    # confidence 用离 criterion 的距离离散化, 形成 1 到 4 档.
    margin = numpy.abs(evidence - criterion)
    conf = numpy.digitize(margin, bins=numpy.asarray([0.35, 0.75, 1.25]))
    conf = conf + 1
    return resp, conf.astype(int)


def make_sdt_abc_bank(stim, n_sims, target_names, rng):
    """Generate parameter and summary statistic matrices for SDT."""
    param = numpy.empty((n_sims, 2), dtype=float)
    sumstat = numpy.empty((n_sims, len(target_names)), dtype=float)

    for index in range(n_sims):
        # 每次循环抽一组参数, 让 bank 覆盖合理的 SDT 参数空间.
        d_value = rng.uniform(0.2, 3.5)
        criterion = rng.uniform(-1.5, 2.5)
        param[index, :] = [d_value, criterion]

        sim_resp, sim_conf = simulate_sdt(
            stim=stim,
            d_value=d_value,
            criterion=criterion,
            rng=rng,
        )
        _, sim_summary = sdt_summary(stim=stim,
                                     resp=sim_resp,
                                     conf=sim_conf)
        sumstat[index, :] = sim_summary

    return param, sumstat


def read_sdt_subject(path, subject_id):
    """Read one subject from data/exp1.csv."""
    with open(path, newline="", encoding="utf-8") as handle:
        reader = csv.DictReader(handle)
        rows = [
            row for row in reader
            if int(row["subj_id"]) == int(subject_id)
        ]

    stim = numpy.asarray([int(row["stim"]) for row in rows], dtype=int)
    resp = numpy.asarray([int(row["resp"]) for row in rows], dtype=int)
    conf = numpy.asarray([int(row["conf"]) for row in rows], dtype=int)
    return stim, resp, conf


rng = numpy.random.default_rng(1004)
data_path = pathlib.Path("data/exp1.csv")
if not data_path.exists():
    raise FileNotFoundError("This script expects data/exp1.csv.")

stim, resp, conf = read_sdt_subject(path=data_path, subject_id=1)
target_names, target = sdt_summary(stim=stim, resp=resp, conf=conf)
param, sumstat = make_sdt_abc_bank(
    stim=stim,
    n_sims=1200,
    target_names=target_names,
    rng=rng,
)

fit_none = abcpp.abc(
    target=target,
    param=param,
    sumstat=sumstat,
    tol=0.12,
    method="loclinear",
    hcorr=False,
    transf=["none", "none"],
    reduce="none",
)
fit_pca = abcpp.abc(
    target=target,
    param=param,
    sumstat=sumstat,
    tol=0.12,
    method="ridge",
    hcorr=False,
    transf=["none", "none"],
    reduce="pca",
    ncomp=4,
)
fit_pls = abcpp.abc(
    target=target,
    param=param,
    sumstat=sumstat,
    tol=0.12,
    method="ridge",
    hcorr=False,
    transf=["none", "none"],
    reduce="pls",
    ncomp=2,
)

sdt_rows = [
    {
        "reduce": "none",
        "method": fit_none["method"],
        "accepted": fit_none["unadj_values"].shape[0],
        "numstat": fit_none["numstat"],
        "posterior_mean": rounded_vector(posterior_mean(fit_none)),
    },
    {
        "reduce": "pca",
        "method": fit_pca["method"],
        "accepted": fit_pca["unadj_values"].shape[0],
        "numstat": fit_pca["numstat"],
        "posterior_mean": rounded_vector(posterior_mean(fit_pca)),
    },
    {
        "reduce": "pls",
        "method": fit_pls["method"],
        "accepted": fit_pls["unadj_values"].shape[0],
        "numstat": fit_pls["numstat"],
        "posterior_mean": rounded_vector(posterior_mean(fit_pls)),
    },
]
print_table("SDT Python Reduction Summary", sdt_rows)

# 这里清理 SDT 中间对象, 让脚本运行后只留下最终输出.
del sdt_summary
del simulate_sdt
del make_sdt_abc_bank
del read_sdt_subject
del rng
del data_path
del stim
del resp
del conf
del target_names
del target
del param
del sumstat
del fit_none
del fit_pca
del fit_pls
del sdt_rows
