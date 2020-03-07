vlib work

vlog -timescale 1s/1s snake.v

vsim snake_test_module

# Log all signals and add some signals to waveform window.
log {/*}
# add wave {/*} would add all items in top level simulation module.
add wave {/*}
add wave -divider control_top
#add wave {/c1/*}
add wave -divider datapath_top
#add wave {/d1/*}
add wave -divider square_coord
#add wave {/s1/*}

force {clk} 0 0, 1 10 -r 20

force {SW[9]} 1 0, 0 50ns

force {SW[9]} 1 100ns

force {KEY[0]} 1
force {KEY[1]} 1
force {KEY[2]} 1
force {KEY[3]} 1

run 500000ns