"""
Basic error-bar plot of two datasets against configurations 1-5.

Edit the DATA section below with your values, then run:
    python3 plot_errorbars.py
"""

import matplotlib.pyplot as plt

# ---------------------------------------------------------------------------
# DATA - replace these placeholder values with your own
# ---------------------------------------------------------------------------
x = [1, 2, 3, 4, 5]                          # configurations
x_labels = ["Very\nCoarse", "Coarse", "Intermediate", "Fine", "Very\nFine"]         # tick labels (rename if desired)

y1 = [0.73, 0.75, 0.76, 0.78, 0.79]         # dataset 1 values
y1_err = [0.04, 0.03, 0.025, 0.02, 0.005] # dataset 1 y-uncertainty (+/-)
label1 = "Coefficient of Drag (Cd)"

y2 = [0.1, 0.1, 0.1, 0.1, 0.11]         # dataset 2 values
y2_err = [0.015, 0.012, 0.011, 0.01, 0.01] # dataset 2 y-uncertainty (+/-)
label2 = "Coefficient of Downforce (Cl)"

# ---------------------------------------------------------------------------
# PLOT SETTINGS
# ---------------------------------------------------------------------------
title = "Mesh Sensitivity Analysis\n Cd & Cl vs. Mesh Configurations"
xlabel = "Configuration"
ylabel = "Quantity [units]"

color1 = "#2a78d6"   # blue
color2 = "#eb6834"   # orange

x_offset = 0.06       # horizontal nudge so overlapping error bars stay readable (0 to disable)

output_file = "MeshSensitivity_plot.png"
dpi = 300

# ---------------------------------------------------------------------------
# PLOTTING
# ---------------------------------------------------------------------------
fig, ax = plt.subplots(figsize=(8, 5), dpi=dpi)

ax.errorbar(
    [xi - x_offset for xi in x], y1, yerr=y1_err,
    color=color1, marker="o", markersize=7, linewidth=2,
    capsize=5, capthick=1.5, elinewidth=1.5,
    label=label1,
)
ax.errorbar(
    [xi + x_offset for xi in x], y2, yerr=y2_err,
    color=color2, marker="s", markersize=7, linewidth=2,
    capsize=5, capthick=1.5, elinewidth=1.5,
    label=label2,
)

ax.set_title(title, fontsize=14, fontweight="bold")
ax.set_xlabel(xlabel, fontsize=12)
ax.set_ylabel(ylabel, fontsize=12)

ax.set_xticks(x)
ax.set_xticklabels(x_labels)

# Gridlines: major solid, minor dotted, kept behind the data
ax.grid(True, which="major", linestyle="-", linewidth=0.6, alpha=0.5)
ax.minorticks_on()
ax.tick_params(axis="x", which="minor", bottom=False)  # no minor ticks between configs
ax.grid(True, which="minor", axis="y", linestyle=":", linewidth=0.5, alpha=0.4)
ax.set_axisbelow(True)

ax.legend(fontsize=11, framealpha=0.9)

fig.tight_layout()
fig.savefig(output_file, dpi=dpi, bbox_inches="tight")
print(f"Saved plot to {output_file}")
plt.show()
