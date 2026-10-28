set title "Cd and Cl vs Time"
set xlabel "Time"
set ylabel "Coefficient"
set grid
set key outside
set datafile separator whitespace
set yrange [-0.1:1]

while (1) {
    clear
    plot '< grep -v "^#" postProcessing/forceCoeffs/0/coefficient.dat' using 1:2 title 'Cd' with lines lt 1 lw 2, \
         '' using 1:5 title 'Cl' with lines lt 2 lw 2
    pause 1
}
