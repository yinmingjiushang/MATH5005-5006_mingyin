#!/usr/bin/env python3
from __future__ import annotations

import shutil
from pathlib import Path

import matplotlib.pyplot as plt
import numpy as np
from matplotlib.lines import Line2D


RHO = 1.0
POLES = np.array([0.1981, 1.5550, 2.5395, 3.2470, 4.7609, 6.6996], dtype=float)
VECTOR = np.array([0.3280, 0.7370, 0.9018, 0.5910, 0.4042, 0.1531], dtype=float)
ROOTS = np.array([0.2538, 1.7895, 2.9649, 4.0351, 5.2105, 6.7462], dtype=float)

X_MIN = -0.05
X_MAX = 7.05
Y_LIM = 6.0
POLE_GAP = 0.015
SAMPLES_PER_INTERVAL = 600


def secular_function(x: np.ndarray) -> np.ndarray:
    total = np.ones_like(x, dtype=float)
    for pole, value in zip(POLES, VECTOR):
        total -= RHO * value * value / (x - pole)
    return total


def interval_segments() -> list[tuple[float, float]]:
    segments: list[tuple[float, float]] = [(X_MIN, float(POLES[0] - POLE_GAP))]
    segments.extend(
        (float(POLES[i] + POLE_GAP), float(POLES[i + 1] - POLE_GAP))
        for i in range(len(POLES) - 1)
    )
    segments.append((float(POLES[-1] + POLE_GAP), X_MAX))
    return segments


def build_plot() -> plt.Figure:
    plt.rcParams.update(
        {
            "font.family": "serif",
            "mathtext.fontset": "stix",
            "font.size": 12,
        }
    )

    fig, ax = plt.subplots(figsize=(8.0, 4.8), dpi=180, constrained_layout=True)

    # Main curve, plotted interval by interval to avoid drawing across poles.
    for left, right in interval_segments():
        x = np.linspace(left, right, SAMPLES_PER_INTERVAL)
        y = secular_function(x)
        y = np.ma.masked_where(np.abs(y) > Y_LIM * 1.08, y)
        ax.plot(x, y, color="#1f5fe0", linewidth=1.35, zorder=3)

    # Poles and roots.
    for pole in POLES:
        ax.axvline(
            pole,
            color="#c94f5d",
            linestyle=(0, (4, 3)),
            linewidth=0.9,
            alpha=0.9,
            zorder=1,
        )

    ax.scatter(ROOTS, np.zeros_like(ROOTS), s=22, color="#1f5fe0", edgecolor="white", linewidth=0.6, zorder=4)

    # Axes, ticks, and grid.
    ax.axhline(0.0, color="#303030", linewidth=0.85, zorder=2)
    ax.set_xlim(X_MIN, X_MAX)
    ax.set_ylim(-Y_LIM, Y_LIM)
    ax.set_xlabel(r"$\lambda$", labelpad=4)
    ax.set_ylabel(r"$f(\lambda)$", labelpad=6)
    ax.set_xticks(np.arange(0, 8, 1))
    ax.set_yticks(np.arange(-6, 7, 2))
    ax.grid(True, which="major", color="#e8ecf3", linewidth=0.6)
    ax.set_axisbelow(True)

    # Clean frame.
    ax.spines["top"].set_visible(False)
    ax.spines["right"].set_visible(False)
    ax.spines["left"].set_linewidth(0.9)
    ax.spines["bottom"].set_linewidth(0.9)

    # Compact legend.
    legend_items = [
        Line2D([0], [0], color="#1f5fe0", lw=1.35, label=r"$f(\lambda)$"),
        Line2D([0], [0], color="#c94f5d", lw=0.9, linestyle=(0, (4, 3)), label=r"poles $\delta_i$"),
    ]
    ax.legend(
        handles=legend_items,
        loc="upper right",
        frameon=True,
        facecolor="white",
        edgecolor="#d9dde5",
        framealpha=1.0,
        borderpad=0.5,
        handlelength=2.0,
    )

    return fig


def main() -> None:
    script_dir = Path(__file__).resolve().parent
    repo_root = script_dir.parents[3]
    output_dir = script_dir / "output"
    latex_fig_dir = repo_root / "latex" / "figures" / "chapter2"
    output_dir.mkdir(parents=True, exist_ok=True)
    latex_fig_dir.mkdir(parents=True, exist_ok=True)

    fig = build_plot()

    output_png = output_dir / "secular_function_example.png"
    output_pdf = output_dir / "secular_function_example.pdf"
    latex_png = latex_fig_dir / "secular_function_example.png"
    latex_pdf = latex_fig_dir / "secular_function_example.pdf"

    fig.savefig(output_png, dpi=220, facecolor="white")
    fig.savefig(output_pdf, facecolor="white")
    plt.close(fig)

    shutil.copy2(output_png, latex_png)
    shutil.copy2(output_pdf, latex_pdf)

    print(f"Wrote {output_png}")
    print(f"Wrote {output_pdf}")
    print(f"Copied {latex_png}")
    print(f"Copied {latex_pdf}")


if __name__ == "__main__":
    main()
