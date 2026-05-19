"""Manual development script for the Python abcpp frontend."""

import csv
import pathlib
import sys

import numpy


############################
# Development Package Setup
############################

# 杩欓噷浼樺厛浣跨敤鏈」鐩紑鍙戞祴璇曟椂瀹夎鐨?Python 鍖呰矾寰?
# % pip install -e ./Python --config-settings=build-dir="build"

import abcpp


############################
# Shared Helper Functions
############################


def safe_mean(values):
    """Return zero for empty vectors, matching the R dev script."""
    # 杩欓噷鎶婅緭鍏ヨ浆鎴?float array, 鏂逛究缁熶竴澶勭悊甯冨皵鍜屾暣鏁板悜閲?
    values = numpy.asarray(values, dtype=float)

    # 绌哄瓙闆嗘病鏈夊彲浼拌鍧囧€? 寮€鍙戣剼鏈腑鐢?0 淇濇寔鎽樿闀垮害绋冲畾.
    if values.size == 0:
        return 0.0

    return float(numpy.mean(values))


def posterior_mean(result):
    """Return adjusted posterior mean when adjustment is available."""
    # regression 鏂规硶浼氳繑鍥?adj_values, rejection 鍒欎富瑕佷娇鐢?unadj_values.
    adjusted = numpy.asarray(result["adj_values"], dtype=float)
    if adjusted.size > 0:
        return numpy.mean(adjusted, axis=0)

    return numpy.mean(numpy.asarray(result["unadj_values"], dtype=float),
                      axis=0)


def print_table(title, rows):
    """Print a small list-of-dicts table without adding pandas."""
    print(f"\n\n=== {title} ===")

    # 绌鸿〃鐩存帴杩斿洖, 閬垮厤涓嬮潰璇诲彇 keys 鏃跺嚭閿?
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

# 杩欓噷鏋勯€犱簩缁?toy ABC bank, 閬垮厤 loclinear 閬囧埌鍏辩嚎璁捐鐭╅樀.
toy_theta_1_grid = numpy.linspace(0.05, 0.95, 10)
toy_theta_2_grid = numpy.linspace(0.10, 0.90, 9)
toy_mesh_1, toy_mesh_2 = numpy.meshgrid(toy_theta_1_grid,
                                        toy_theta_2_grid)
toy_theta_1 = toy_mesh_1.ravel()
toy_theta_2 = toy_mesh_2.ravel()
toy_param = numpy.column_stack((toy_theta_1, toy_theta_2))

# 杩欓噷璁?summary statistics 鍚屾椂鍖呭惈绾挎€у拰闈炵嚎鎬т俊鎭?
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
    params=toy_param,
    sumstats=toy_sumstat,
    control={
        "tol": 0.10,
        "method": "rejection",
        "transf": ["none", "none"],
        "reduction": "none",
    },
)
toy_loclinear = abcpp.abc(
    target=toy_target,
    params=toy_param,
    sumstats=toy_sumstat,
    control={
        "tol": 0.20,
        "method": "loclinear",
        "hcorr": False,
        "transf": ["none", "none"],
        "reduction": "none",
    },
)
toy_target_matrix = toy_target.reshape((2, 2))
toy_sumstat_matrices = {
    f"sim_{index}": row.reshape((2, 2))
    for index, row in enumerate(toy_sumstat)
}
toy_matrix_list = abcpp.abc(
    target=toy_target_matrix,
    params=toy_param,
    sumstats=toy_sumstat_matrices,
    control={
        "tol": 0.10,
        "method": "rejection",
        "transf": ["none", "none"],
        "reduction": "none",
    },
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

# 杩欓噷娓呯悊 toy 涓棿瀵硅薄, 鍙鎺у埗鍙颁繚鐣欐渶缁堟眹鎬?
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

    # 杩欓噷淇濈暀缃俊搴﹀垎甯? 浣嗙渷鐣ユ渶鍚庝竴妗ｄ互閬垮厤绾挎€у啑浣?
    for stim_level in (0, 1):
        stim_mask = stim == stim_level
        for conf_level in (1, 2, 3):
            out_names.append(f"p_s{stim_level}_conf{conf_level}")
            out_values.append(safe_mean(conf[stim_mask] == conf_level))

    return out_names, numpy.asarray(out_values, dtype=float)


def simulate_sdt(stim, d_value, criterion, rng):
    """Simulate a minimal equal-variance SDT model."""
    # signal trial 鐨?evidence 鍧囧€间负 d, noise trial 鐨勫潎鍊间负 0.
    evidence_mean = numpy.where(stim == 1, d_value, 0.0)
    evidence = rng.normal(loc=evidence_mean, scale=1.0, size=stim.size)
    resp = (evidence > criterion).astype(int)

    # confidence 鐢ㄧ criterion 鐨勮窛绂荤鏁ｅ寲, 褰㈡垚 1 鍒?4 妗?
    margin = numpy.abs(evidence - criterion)
    conf = numpy.digitize(margin, bins=numpy.asarray([0.35, 0.75, 1.25]))
    conf = conf + 1
    return resp, conf.astype(int)


def make_sdt_abc_bank(stim, n_sims, target_names, rng):
    """Generate parameter and summary statistic matrices for SDT."""
    param = numpy.empty((n_sims, 2), dtype=float)
    sumstat = numpy.empty((n_sims, len(target_names)), dtype=float)

    for index in range(n_sims):
        # 姣忔寰幆鎶戒竴缁勫弬鏁? 璁?bank 瑕嗙洊鍚堢悊鐨?SDT 鍙傛暟绌洪棿.
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
    params=param,
    sumstats=sumstat,
    control={
        "tol": 0.12,
        "method": "loclinear",
        "hcorr": False,
        "transf": ["none", "none"],
        "reduction": "none",
    },
)
fit_pca = abcpp.abc(
    target=target,
    params=param,
    sumstats=sumstat,
    control={
        "tol": 0.12,
        "method": "ridge",
        "hcorr": False,
        "transf": ["none", "none"],
        "reduction": "pca",
        "n_comp": 4,
    },
)
fit_pls = abcpp.abc(
    target=target,
    params=param,
    sumstats=sumstat,
    control={
        "tol": 0.12,
        "method": "ridge",
        "hcorr": False,
        "transf": ["none", "none"],
        "reduction": "pls",
        "n_comp": 2,
    },
)

sdt_rows = [
    {
        "reduction": "none",
        "method": fit_none["method"],
        "accepted": fit_none["unadj_values"].shape[0],
        "numstat": fit_none["numstat"],
        "posterior_mean": rounded_vector(posterior_mean(fit_none)),
    },
    {
        "reduction": "pca",
        "method": fit_pca["method"],
        "accepted": fit_pca["unadj_values"].shape[0],
        "numstat": fit_pca["numstat"],
        "posterior_mean": rounded_vector(posterior_mean(fit_pca)),
    },
    {
        "reduction": "pls",
        "method": fit_pls["method"],
        "accepted": fit_pls["unadj_values"].shape[0],
        "numstat": fit_pls["numstat"],
        "posterior_mean": rounded_vector(posterior_mean(fit_pls)),
    },
]
print_table("SDT Python Reduction Summary", sdt_rows)

# 杩欓噷娓呯悊 SDT 涓棿瀵硅薄, 璁╄剼鏈繍琛屽悗鍙暀涓嬫渶缁堣緭鍑?
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
