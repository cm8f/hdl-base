onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /tb_fifo_sc_mixed/inst_dut/g_wr_width
add wave -noupdate /tb_fifo_sc_mixed/inst_dut/g_rd_width
add wave -noupdate /tb_fifo_sc_mixed/inst_dut/g_wr_depth
add wave -noupdate /tb_fifo_sc_mixed/inst_dut/g_output_reg
add wave -noupdate /tb_fifo_sc_mixed/inst_dut/i_clock
add wave -noupdate /tb_fifo_sc_mixed/inst_dut/i_reset
add wave -noupdate /tb_fifo_sc_mixed/inst_dut/i_din
add wave -noupdate /tb_fifo_sc_mixed/inst_dut/i_wrreq
add wave -noupdate /tb_fifo_sc_mixed/inst_dut/i_rdreq
add wave -noupdate /tb_fifo_sc_mixed/inst_dut/o_dout
add wave -noupdate /tb_fifo_sc_mixed/inst_dut/o_empty
add wave -noupdate /tb_fifo_sc_mixed/inst_dut/o_full
add wave -noupdate /tb_fifo_sc_mixed/inst_dut/o_almost_empty
add wave -noupdate /tb_fifo_sc_mixed/inst_dut/o_almost_full
add wave -noupdate /tb_fifo_sc_mixed/inst_dut/r_wr_ptr_wr
add wave -noupdate /tb_fifo_sc_mixed/inst_dut/r_rd_ptr_wr
add wave -noupdate /tb_fifo_sc_mixed/inst_dut/r_wr_ptr_rd
add wave -noupdate /tb_fifo_sc_mixed/inst_dut/r_rd_ptr_rd
add wave -noupdate /tb_fifo_sc_mixed/inst_dut/s_full
add wave -noupdate /tb_fifo_sc_mixed/inst_dut/s_empty
add wave -noupdate /tb_fifo_sc_mixed/inst_dut/s_almost_empty
add wave -noupdate /tb_fifo_sc_mixed/inst_dut/s_almost_full
add wave -noupdate /tb_fifo_sc_mixed/inst_dut/r_usedw_wr
add wave -noupdate /tb_fifo_sc_mixed/inst_dut/r_usedw_rd
add wave -noupdate /tb_fifo_sc_mixed/inst_dut/c_rd_depth
add wave -noupdate /tb_fifo_sc_mixed/inst_dut/c_factor
add wave -noupdate /tb_fifo_sc_mixed/inst_dut/c_factor_log
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {0 ps} 0}
quietly wave cursor active 0
configure wave -namecolwidth 150
configure wave -valuecolwidth 100
configure wave -justifyvalue left
configure wave -signalnamewidth 1
configure wave -snapdistance 10
configure wave -datasetprefix 0
configure wave -rowmargin 4
configure wave -childrowmargin 2
configure wave -gridoffset 0
configure wave -gridperiod 1
configure wave -griddelta 40
configure wave -timeline 0
configure wave -timelineunits ns
update
WaveRestoreZoom {0 ps} {3356 ps}
