verdiSetActWin -win $_nWave1
wvSetPosition -win $_nWave1 {("G1" 0)}
wvOpenFile -win $_nWave1 \
           {/home/raid7_2/userb09/b09118/all_dclab/lab1/sim/Lab1_test.fsdb}
wvGetSignalOpen -win $_nWave1
wvGetSignalSetScope -win $_nWave1 "/Top_test"
wvGetSignalSetScope -win $_nWave1 "/Top_test/top0/random_number_generation"
wvSetPosition -win $_nWave1 {("G1" 9)}
wvSetPosition -win $_nWave1 {("G1" 9)}
wvAddSignal -win $_nWave1 -clear
wvAddSignal -win $_nWave1 -group {"G1" \
{/Top_test/top0/random_number_generation/count\[3:0\]} \
{/Top_test/top0/random_number_generation/done\[3:0\]} \
{/Top_test/top0/random_number_generation/feedback} \
{/Top_test/top0/random_number_generation/fin} \
{/Top_test/top0/random_number_generation/limit\[3:0\]} \
{/Top_test/top0/random_number_generation/out\[15:0\]} \
{/Top_test/top0/random_number_generation/seed\[3:0\]} \
{/Top_test/top0/random_number_generation/signal} \
{/Top_test/top0/random_number_generation/slow} \
}
wvAddSignal -win $_nWave1 -group {"G2" \
}
wvSelectSignal -win $_nWave1 {( "G1" 1 2 3 4 5 6 7 8 9 )} 
wvSetPosition -win $_nWave1 {("G1" 9)}
wvGetSignalSetScope -win $_nWave1 "/Top_test"
wvSetPosition -win $_nWave1 {("G1" 13)}
wvSetPosition -win $_nWave1 {("G1" 13)}
wvAddSignal -win $_nWave1 -clear
wvAddSignal -win $_nWave1 -group {"G1" \
{/Top_test/top0/random_number_generation/count\[3:0\]} \
{/Top_test/top0/random_number_generation/done\[3:0\]} \
{/Top_test/top0/random_number_generation/feedback} \
{/Top_test/top0/random_number_generation/fin} \
{/Top_test/top0/random_number_generation/limit\[3:0\]} \
{/Top_test/top0/random_number_generation/out\[15:0\]} \
{/Top_test/top0/random_number_generation/seed\[3:0\]} \
{/Top_test/top0/random_number_generation/signal} \
{/Top_test/top0/random_number_generation/slow} \
{/Top_test/i_clk} \
{/Top_test/i_rst_n} \
{/Top_test/i_start} \
{/Top_test/o_random_out\[3:0\]} \
}
wvAddSignal -win $_nWave1 -group {"G2" \
}
wvSelectSignal -win $_nWave1 {( "G1" 10 11 12 13 )} 
wvSetPosition -win $_nWave1 {("G1" 13)}
wvSetPosition -win $_nWave1 {("G1" 13)}
wvSetPosition -win $_nWave1 {("G1" 13)}
wvAddSignal -win $_nWave1 -clear
wvAddSignal -win $_nWave1 -group {"G1" \
{/Top_test/top0/random_number_generation/count\[3:0\]} \
{/Top_test/top0/random_number_generation/done\[3:0\]} \
{/Top_test/top0/random_number_generation/feedback} \
{/Top_test/top0/random_number_generation/fin} \
{/Top_test/top0/random_number_generation/limit\[3:0\]} \
{/Top_test/top0/random_number_generation/out\[15:0\]} \
{/Top_test/top0/random_number_generation/seed\[3:0\]} \
{/Top_test/top0/random_number_generation/signal} \
{/Top_test/top0/random_number_generation/slow} \
{/Top_test/i_clk} \
{/Top_test/i_rst_n} \
{/Top_test/i_start} \
{/Top_test/o_random_out\[3:0\]} \
}
wvAddSignal -win $_nWave1 -group {"G2" \
}
wvSelectSignal -win $_nWave1 {( "G1" 10 11 12 13 )} 
wvSetPosition -win $_nWave1 {("G1" 13)}
wvGetSignalClose -win $_nWave1
wvZoomIn -win $_nWave1
wvZoomIn -win $_nWave1
wvZoomIn -win $_nWave1
wvZoomIn -win $_nWave1
wvZoomIn -win $_nWave1
wvZoomIn -win $_nWave1
wvZoomIn -win $_nWave1
wvZoomIn -win $_nWave1
wvZoomIn -win $_nWave1
wvZoomIn -win $_nWave1
wvZoomIn -win $_nWave1
wvZoomIn -win $_nWave1
wvZoomIn -win $_nWave1
wvZoomIn -win $_nWave1
wvSetCursor -win $_nWave1 869.953956 -snap {("G1" 12)}
wvSetCursor -win $_nWave1 987.611664 -snap {("G1" 12)}
wvSetCursor -win $_nWave1 1643.642516 -snap {("G1" 13)}
wvSelectSignal -win $_nWave1 {( "G1" 13 )} 
wvSelectSignal -win $_nWave1 {( "G1" 4 )} 
wvSelectSignal -win $_nWave1 {( "G1" 5 )} 
wvSelectSignal -win $_nWave1 {( "G1" 13 )} 
wvSetCursor -win $_nWave1 2092.881034 -snap {("G1" 13)}
wvSetCursor -win $_nWave1 1618.684821 -snap {("G1" 13)}
wvSetCursor -win $_nWave1 2039.400258 -snap {("G1" 13)}
wvSetCursor -win $_nWave1 2517.161857 -snap {("G1" 13)}
wvSetCursor -win $_nWave1 3155.365785 -snap {("G1" 13)}
wvSetCursor -win $_nWave1 3775.742786 -snap {("G1" 13)}
wvZoomOut -win $_nWave1
wvZoomOut -win $_nWave1
wvSetCursor -win $_nWave1 18240.510004 -snap {("G1" 13)}
wvSetCursor -win $_nWave1 10610.585960 -snap {("G1" 13)}
wvSetCursor -win $_nWave1 9098.862692 -snap {("G1" 13)}
wvSetCursor -win $_nWave1 7487.308641 -snap {("G1" 13)}
wvSetCursor -win $_nWave1 6489.000822 -snap {("G1" 13)}
wvSetCursor -win $_nWave1 5547.739165 -snap {("G1" 13)}
wvSetCursor -win $_nWave1 14004.832544 -snap {("G1" 13)}
wvZoom -win $_nWave1 4392.554403 4506.646725
wvZoomOut -win $_nWave1
wvZoomOut -win $_nWave1
wvZoomOut -win $_nWave1
wvZoomOut -win $_nWave1
wvZoomOut -win $_nWave1
wvZoomOut -win $_nWave1
wvZoomOut -win $_nWave1
wvZoomOut -win $_nWave1
