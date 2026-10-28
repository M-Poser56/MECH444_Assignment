while (1) {
    clear

    # Top plot: Residuals
    set title "Residuals"
    set xlabel 'Iteration'
    set ylabel 'Residual'
    set logscale y
    plot "< grep 'Solving for Ux' log.simple | cut -d' ' -f9 | tr -d ',' | nl -v 0" title 'Ux' with lines,\
         "< grep 'Solving for Uy' log.simple | cut -d' ' -f9 | tr -d ',' | nl -v 0" title 'Uy' with lines,\
         "< grep 'Solving for p'  log.simple | cut -d' ' -f9 | tr -d ',' | nl -v 0" title 'p' with lines

    pause 1
}
