# Usage: gnuplot -c residuals.plot <path/to/logfile>
if (ARGC < 1) {
    print "Usage: gnuplot -c residuals.plot <path/to/logfile>"
    exit
}
logfile = ARG1

# Initial residual for field f, one value per iteration
res(f) = sprintf("< grep 'Solving for %s,' '%s' | sed 's/.*Initial residual = //; s/,.*//' | nl -v 0", f, logfile)

while (1) {
    clear

    # Top plot: Residuals
    set title "Residuals"
    set xlabel 'Iteration'
    set ylabel 'Residual'
    set logscale y
    plot for [f in "Ux Uy Uz p epsilon k"] res(f) title f with lines

    pause 1
}
