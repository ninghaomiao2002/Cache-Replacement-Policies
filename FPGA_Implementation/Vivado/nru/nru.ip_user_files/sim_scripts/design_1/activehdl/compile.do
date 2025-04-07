transcript off
onbreak {quit -force}
onerror {quit -force}
transcript on

vlib work
vlib activehdl/xilinx_vip
vlib activehdl/xpm
vlib activehdl/generic_baseblocks_v2_1_1
vlib activehdl/axi_infrastructure_v1_1_0
vlib activehdl/axi_register_slice_v2_1_29
vlib activehdl/fifo_generator_v13_2_9
vlib activehdl/axi_data_fifo_v2_1_28
vlib activehdl/axi_crossbar_v2_1_30
vlib activehdl/xil_defaultlib
vlib activehdl/axi_vip_v1_1_15
vlib activehdl/zynq_ultra_ps_e_vip_v1_0_15
vlib activehdl/lib_cdc_v1_0_2
vlib activehdl/proc_sys_reset_v5_0_14
vlib activehdl/axi_protocol_converter_v2_1_29
vlib activehdl/axi_clock_converter_v2_1_28
vlib activehdl/blk_mem_gen_v8_4_7
vlib activehdl/axi_dwidth_converter_v2_1_29
vlib activehdl/axi_mmu_v2_1_27

vmap xilinx_vip activehdl/xilinx_vip
vmap xpm activehdl/xpm
vmap generic_baseblocks_v2_1_1 activehdl/generic_baseblocks_v2_1_1
vmap axi_infrastructure_v1_1_0 activehdl/axi_infrastructure_v1_1_0
vmap axi_register_slice_v2_1_29 activehdl/axi_register_slice_v2_1_29
vmap fifo_generator_v13_2_9 activehdl/fifo_generator_v13_2_9
vmap axi_data_fifo_v2_1_28 activehdl/axi_data_fifo_v2_1_28
vmap axi_crossbar_v2_1_30 activehdl/axi_crossbar_v2_1_30
vmap xil_defaultlib activehdl/xil_defaultlib
vmap axi_vip_v1_1_15 activehdl/axi_vip_v1_1_15
vmap zynq_ultra_ps_e_vip_v1_0_15 activehdl/zynq_ultra_ps_e_vip_v1_0_15
vmap lib_cdc_v1_0_2 activehdl/lib_cdc_v1_0_2
vmap proc_sys_reset_v5_0_14 activehdl/proc_sys_reset_v5_0_14
vmap axi_protocol_converter_v2_1_29 activehdl/axi_protocol_converter_v2_1_29
vmap axi_clock_converter_v2_1_28 activehdl/axi_clock_converter_v2_1_28
vmap blk_mem_gen_v8_4_7 activehdl/blk_mem_gen_v8_4_7
vmap axi_dwidth_converter_v2_1_29 activehdl/axi_dwidth_converter_v2_1_29
vmap axi_mmu_v2_1_27 activehdl/axi_mmu_v2_1_27

vlog -work xilinx_vip  -sv2k12 "+incdir+C:/Xilinx/Vivado/2023.2/data/xilinx_vip/include" -l xilinx_vip -l xpm -l generic_baseblocks_v2_1_1 -l axi_infrastructure_v1_1_0 -l axi_register_slice_v2_1_29 -l fifo_generator_v13_2_9 -l axi_data_fifo_v2_1_28 -l axi_crossbar_v2_1_30 -l xil_defaultlib -l axi_vip_v1_1_15 -l zynq_ultra_ps_e_vip_v1_0_15 -l lib_cdc_v1_0_2 -l proc_sys_reset_v5_0_14 -l axi_protocol_converter_v2_1_29 -l axi_clock_converter_v2_1_28 -l blk_mem_gen_v8_4_7 -l axi_dwidth_converter_v2_1_29 -l axi_mmu_v2_1_27 \
"C:/Xilinx/Vivado/2023.2/data/xilinx_vip/hdl/axi4stream_vip_axi4streampc.sv" \
"C:/Xilinx/Vivado/2023.2/data/xilinx_vip/hdl/axi_vip_axi4pc.sv" \
"C:/Xilinx/Vivado/2023.2/data/xilinx_vip/hdl/xil_common_vip_pkg.sv" \
"C:/Xilinx/Vivado/2023.2/data/xilinx_vip/hdl/axi4stream_vip_pkg.sv" \
"C:/Xilinx/Vivado/2023.2/data/xilinx_vip/hdl/axi_vip_pkg.sv" \
"C:/Xilinx/Vivado/2023.2/data/xilinx_vip/hdl/axi4stream_vip_if.sv" \
"C:/Xilinx/Vivado/2023.2/data/xilinx_vip/hdl/axi_vip_if.sv" \
"C:/Xilinx/Vivado/2023.2/data/xilinx_vip/hdl/clk_vip_if.sv" \
"C:/Xilinx/Vivado/2023.2/data/xilinx_vip/hdl/rst_vip_if.sv" \

vlog -work xpm  -sv2k12 "+incdir+../../../../nru.gen/sources_1/bd/design_1/ipshared/ec67/hdl" "+incdir+../../../../nru.gen/sources_1/bd/design_1/ipshared/2fcd/hdl" "+incdir+C:/Xilinx/Vivado/2023.2/data/xilinx_vip/include" -l xilinx_vip -l xpm -l generic_baseblocks_v2_1_1 -l axi_infrastructure_v1_1_0 -l axi_register_slice_v2_1_29 -l fifo_generator_v13_2_9 -l axi_data_fifo_v2_1_28 -l axi_crossbar_v2_1_30 -l xil_defaultlib -l axi_vip_v1_1_15 -l zynq_ultra_ps_e_vip_v1_0_15 -l lib_cdc_v1_0_2 -l proc_sys_reset_v5_0_14 -l axi_protocol_converter_v2_1_29 -l axi_clock_converter_v2_1_28 -l blk_mem_gen_v8_4_7 -l axi_dwidth_converter_v2_1_29 -l axi_mmu_v2_1_27 \
"C:/Xilinx/Vivado/2023.2/data/ip/xpm/xpm_cdc/hdl/xpm_cdc.sv" \
"C:/Xilinx/Vivado/2023.2/data/ip/xpm/xpm_memory/hdl/xpm_memory.sv" \

vcom -work xpm -93  \
"C:/Xilinx/Vivado/2023.2/data/ip/xpm/xpm_VCOMP.vhd" \

vlog -work generic_baseblocks_v2_1_1  -v2k5 "+incdir+../../../../nru.gen/sources_1/bd/design_1/ipshared/ec67/hdl" "+incdir+../../../../nru.gen/sources_1/bd/design_1/ipshared/2fcd/hdl" "+incdir+C:/Xilinx/Vivado/2023.2/data/xilinx_vip/include" -l xilinx_vip -l xpm -l generic_baseblocks_v2_1_1 -l axi_infrastructure_v1_1_0 -l axi_register_slice_v2_1_29 -l fifo_generator_v13_2_9 -l axi_data_fifo_v2_1_28 -l axi_crossbar_v2_1_30 -l xil_defaultlib -l axi_vip_v1_1_15 -l zynq_ultra_ps_e_vip_v1_0_15 -l lib_cdc_v1_0_2 -l proc_sys_reset_v5_0_14 -l axi_protocol_converter_v2_1_29 -l axi_clock_converter_v2_1_28 -l blk_mem_gen_v8_4_7 -l axi_dwidth_converter_v2_1_29 -l axi_mmu_v2_1_27 \
"../../../../nru.gen/sources_1/bd/design_1/ipshared/10ab/hdl/generic_baseblocks_v2_1_vl_rfs.v" \

vlog -work axi_infrastructure_v1_1_0  -v2k5 "+incdir+../../../../nru.gen/sources_1/bd/design_1/ipshared/ec67/hdl" "+incdir+../../../../nru.gen/sources_1/bd/design_1/ipshared/2fcd/hdl" "+incdir+C:/Xilinx/Vivado/2023.2/data/xilinx_vip/include" -l xilinx_vip -l xpm -l generic_baseblocks_v2_1_1 -l axi_infrastructure_v1_1_0 -l axi_register_slice_v2_1_29 -l fifo_generator_v13_2_9 -l axi_data_fifo_v2_1_28 -l axi_crossbar_v2_1_30 -l xil_defaultlib -l axi_vip_v1_1_15 -l zynq_ultra_ps_e_vip_v1_0_15 -l lib_cdc_v1_0_2 -l proc_sys_reset_v5_0_14 -l axi_protocol_converter_v2_1_29 -l axi_clock_converter_v2_1_28 -l blk_mem_gen_v8_4_7 -l axi_dwidth_converter_v2_1_29 -l axi_mmu_v2_1_27 \
"../../../../nru.gen/sources_1/bd/design_1/ipshared/ec67/hdl/axi_infrastructure_v1_1_vl_rfs.v" \

vlog -work axi_register_slice_v2_1_29  -v2k5 "+incdir+../../../../nru.gen/sources_1/bd/design_1/ipshared/ec67/hdl" "+incdir+../../../../nru.gen/sources_1/bd/design_1/ipshared/2fcd/hdl" "+incdir+C:/Xilinx/Vivado/2023.2/data/xilinx_vip/include" -l xilinx_vip -l xpm -l generic_baseblocks_v2_1_1 -l axi_infrastructure_v1_1_0 -l axi_register_slice_v2_1_29 -l fifo_generator_v13_2_9 -l axi_data_fifo_v2_1_28 -l axi_crossbar_v2_1_30 -l xil_defaultlib -l axi_vip_v1_1_15 -l zynq_ultra_ps_e_vip_v1_0_15 -l lib_cdc_v1_0_2 -l proc_sys_reset_v5_0_14 -l axi_protocol_converter_v2_1_29 -l axi_clock_converter_v2_1_28 -l blk_mem_gen_v8_4_7 -l axi_dwidth_converter_v2_1_29 -l axi_mmu_v2_1_27 \
"../../../../nru.gen/sources_1/bd/design_1/ipshared/ff9f/hdl/axi_register_slice_v2_1_vl_rfs.v" \

vlog -work fifo_generator_v13_2_9  -v2k5 "+incdir+../../../../nru.gen/sources_1/bd/design_1/ipshared/ec67/hdl" "+incdir+../../../../nru.gen/sources_1/bd/design_1/ipshared/2fcd/hdl" "+incdir+C:/Xilinx/Vivado/2023.2/data/xilinx_vip/include" -l xilinx_vip -l xpm -l generic_baseblocks_v2_1_1 -l axi_infrastructure_v1_1_0 -l axi_register_slice_v2_1_29 -l fifo_generator_v13_2_9 -l axi_data_fifo_v2_1_28 -l axi_crossbar_v2_1_30 -l xil_defaultlib -l axi_vip_v1_1_15 -l zynq_ultra_ps_e_vip_v1_0_15 -l lib_cdc_v1_0_2 -l proc_sys_reset_v5_0_14 -l axi_protocol_converter_v2_1_29 -l axi_clock_converter_v2_1_28 -l blk_mem_gen_v8_4_7 -l axi_dwidth_converter_v2_1_29 -l axi_mmu_v2_1_27 \
"../../../../nru.gen/sources_1/bd/design_1/ipshared/ac72/simulation/fifo_generator_vlog_beh.v" \

vcom -work fifo_generator_v13_2_9 -93  \
"../../../../nru.gen/sources_1/bd/design_1/ipshared/ac72/hdl/fifo_generator_v13_2_rfs.vhd" \

vlog -work fifo_generator_v13_2_9  -v2k5 "+incdir+../../../../nru.gen/sources_1/bd/design_1/ipshared/ec67/hdl" "+incdir+../../../../nru.gen/sources_1/bd/design_1/ipshared/2fcd/hdl" "+incdir+C:/Xilinx/Vivado/2023.2/data/xilinx_vip/include" -l xilinx_vip -l xpm -l generic_baseblocks_v2_1_1 -l axi_infrastructure_v1_1_0 -l axi_register_slice_v2_1_29 -l fifo_generator_v13_2_9 -l axi_data_fifo_v2_1_28 -l axi_crossbar_v2_1_30 -l xil_defaultlib -l axi_vip_v1_1_15 -l zynq_ultra_ps_e_vip_v1_0_15 -l lib_cdc_v1_0_2 -l proc_sys_reset_v5_0_14 -l axi_protocol_converter_v2_1_29 -l axi_clock_converter_v2_1_28 -l blk_mem_gen_v8_4_7 -l axi_dwidth_converter_v2_1_29 -l axi_mmu_v2_1_27 \
"../../../../nru.gen/sources_1/bd/design_1/ipshared/ac72/hdl/fifo_generator_v13_2_rfs.v" \

vlog -work axi_data_fifo_v2_1_28  -v2k5 "+incdir+../../../../nru.gen/sources_1/bd/design_1/ipshared/ec67/hdl" "+incdir+../../../../nru.gen/sources_1/bd/design_1/ipshared/2fcd/hdl" "+incdir+C:/Xilinx/Vivado/2023.2/data/xilinx_vip/include" -l xilinx_vip -l xpm -l generic_baseblocks_v2_1_1 -l axi_infrastructure_v1_1_0 -l axi_register_slice_v2_1_29 -l fifo_generator_v13_2_9 -l axi_data_fifo_v2_1_28 -l axi_crossbar_v2_1_30 -l xil_defaultlib -l axi_vip_v1_1_15 -l zynq_ultra_ps_e_vip_v1_0_15 -l lib_cdc_v1_0_2 -l proc_sys_reset_v5_0_14 -l axi_protocol_converter_v2_1_29 -l axi_clock_converter_v2_1_28 -l blk_mem_gen_v8_4_7 -l axi_dwidth_converter_v2_1_29 -l axi_mmu_v2_1_27 \
"../../../../nru.gen/sources_1/bd/design_1/ipshared/279e/hdl/axi_data_fifo_v2_1_vl_rfs.v" \

vlog -work axi_crossbar_v2_1_30  -v2k5 "+incdir+../../../../nru.gen/sources_1/bd/design_1/ipshared/ec67/hdl" "+incdir+../../../../nru.gen/sources_1/bd/design_1/ipshared/2fcd/hdl" "+incdir+C:/Xilinx/Vivado/2023.2/data/xilinx_vip/include" -l xilinx_vip -l xpm -l generic_baseblocks_v2_1_1 -l axi_infrastructure_v1_1_0 -l axi_register_slice_v2_1_29 -l fifo_generator_v13_2_9 -l axi_data_fifo_v2_1_28 -l axi_crossbar_v2_1_30 -l xil_defaultlib -l axi_vip_v1_1_15 -l zynq_ultra_ps_e_vip_v1_0_15 -l lib_cdc_v1_0_2 -l proc_sys_reset_v5_0_14 -l axi_protocol_converter_v2_1_29 -l axi_clock_converter_v2_1_28 -l blk_mem_gen_v8_4_7 -l axi_dwidth_converter_v2_1_29 -l axi_mmu_v2_1_27 \
"../../../../nru.gen/sources_1/bd/design_1/ipshared/fb47/hdl/axi_crossbar_v2_1_vl_rfs.v" \

vlog -work xil_defaultlib  -v2k5 "+incdir+../../../../nru.gen/sources_1/bd/design_1/ipshared/ec67/hdl" "+incdir+../../../../nru.gen/sources_1/bd/design_1/ipshared/2fcd/hdl" "+incdir+C:/Xilinx/Vivado/2023.2/data/xilinx_vip/include" -l xilinx_vip -l xpm -l generic_baseblocks_v2_1_1 -l axi_infrastructure_v1_1_0 -l axi_register_slice_v2_1_29 -l fifo_generator_v13_2_9 -l axi_data_fifo_v2_1_28 -l axi_crossbar_v2_1_30 -l xil_defaultlib -l axi_vip_v1_1_15 -l zynq_ultra_ps_e_vip_v1_0_15 -l lib_cdc_v1_0_2 -l proc_sys_reset_v5_0_14 -l axi_protocol_converter_v2_1_29 -l axi_clock_converter_v2_1_28 -l blk_mem_gen_v8_4_7 -l axi_dwidth_converter_v2_1_29 -l axi_mmu_v2_1_27 \
"../../../bd/design_1/ip/design_1_xbar_1/sim/design_1_xbar_1.v" \

vlog -work axi_vip_v1_1_15  -sv2k12 "+incdir+../../../../nru.gen/sources_1/bd/design_1/ipshared/ec67/hdl" "+incdir+../../../../nru.gen/sources_1/bd/design_1/ipshared/2fcd/hdl" "+incdir+C:/Xilinx/Vivado/2023.2/data/xilinx_vip/include" -l xilinx_vip -l xpm -l generic_baseblocks_v2_1_1 -l axi_infrastructure_v1_1_0 -l axi_register_slice_v2_1_29 -l fifo_generator_v13_2_9 -l axi_data_fifo_v2_1_28 -l axi_crossbar_v2_1_30 -l xil_defaultlib -l axi_vip_v1_1_15 -l zynq_ultra_ps_e_vip_v1_0_15 -l lib_cdc_v1_0_2 -l proc_sys_reset_v5_0_14 -l axi_protocol_converter_v2_1_29 -l axi_clock_converter_v2_1_28 -l blk_mem_gen_v8_4_7 -l axi_dwidth_converter_v2_1_29 -l axi_mmu_v2_1_27 \
"../../../../nru.gen/sources_1/bd/design_1/ipshared/5753/hdl/axi_vip_v1_1_vl_rfs.sv" \

vlog -work zynq_ultra_ps_e_vip_v1_0_15  -sv2k12 "+incdir+../../../../nru.gen/sources_1/bd/design_1/ipshared/ec67/hdl" "+incdir+../../../../nru.gen/sources_1/bd/design_1/ipshared/2fcd/hdl" "+incdir+C:/Xilinx/Vivado/2023.2/data/xilinx_vip/include" -l xilinx_vip -l xpm -l generic_baseblocks_v2_1_1 -l axi_infrastructure_v1_1_0 -l axi_register_slice_v2_1_29 -l fifo_generator_v13_2_9 -l axi_data_fifo_v2_1_28 -l axi_crossbar_v2_1_30 -l xil_defaultlib -l axi_vip_v1_1_15 -l zynq_ultra_ps_e_vip_v1_0_15 -l lib_cdc_v1_0_2 -l proc_sys_reset_v5_0_14 -l axi_protocol_converter_v2_1_29 -l axi_clock_converter_v2_1_28 -l blk_mem_gen_v8_4_7 -l axi_dwidth_converter_v2_1_29 -l axi_mmu_v2_1_27 \
"../../../../nru.gen/sources_1/bd/design_1/ipshared/2fcd/hdl/zynq_ultra_ps_e_vip_v1_0_vl_rfs.sv" \

vlog -work xil_defaultlib  -v2k5 "+incdir+../../../../nru.gen/sources_1/bd/design_1/ipshared/ec67/hdl" "+incdir+../../../../nru.gen/sources_1/bd/design_1/ipshared/2fcd/hdl" "+incdir+C:/Xilinx/Vivado/2023.2/data/xilinx_vip/include" -l xilinx_vip -l xpm -l generic_baseblocks_v2_1_1 -l axi_infrastructure_v1_1_0 -l axi_register_slice_v2_1_29 -l fifo_generator_v13_2_9 -l axi_data_fifo_v2_1_28 -l axi_crossbar_v2_1_30 -l xil_defaultlib -l axi_vip_v1_1_15 -l zynq_ultra_ps_e_vip_v1_0_15 -l lib_cdc_v1_0_2 -l proc_sys_reset_v5_0_14 -l axi_protocol_converter_v2_1_29 -l axi_clock_converter_v2_1_28 -l blk_mem_gen_v8_4_7 -l axi_dwidth_converter_v2_1_29 -l axi_mmu_v2_1_27 \
"../../../bd/design_1/ip/design_1_zynq_ultra_ps_e_0_0/sim/design_1_zynq_ultra_ps_e_0_0_vip_wrapper.v" \

vcom -work lib_cdc_v1_0_2 -93  \
"../../../../nru.gen/sources_1/bd/design_1/ipshared/ef1e/hdl/lib_cdc_v1_0_rfs.vhd" \

vcom -work proc_sys_reset_v5_0_14 -93  \
"../../../../nru.gen/sources_1/bd/design_1/ipshared/408c/hdl/proc_sys_reset_v5_0_vh_rfs.vhd" \

vcom -work xil_defaultlib -93  \
"../../../bd/design_1/ip/design_1_proc_sys_reset_0_0/sim/design_1_proc_sys_reset_0_0.vhd" \

vlog -work xil_defaultlib  -v2k5 "+incdir+../../../../nru.gen/sources_1/bd/design_1/ipshared/ec67/hdl" "+incdir+../../../../nru.gen/sources_1/bd/design_1/ipshared/2fcd/hdl" "+incdir+C:/Xilinx/Vivado/2023.2/data/xilinx_vip/include" -l xilinx_vip -l xpm -l generic_baseblocks_v2_1_1 -l axi_infrastructure_v1_1_0 -l axi_register_slice_v2_1_29 -l fifo_generator_v13_2_9 -l axi_data_fifo_v2_1_28 -l axi_crossbar_v2_1_30 -l xil_defaultlib -l axi_vip_v1_1_15 -l zynq_ultra_ps_e_vip_v1_0_15 -l lib_cdc_v1_0_2 -l proc_sys_reset_v5_0_14 -l axi_protocol_converter_v2_1_29 -l axi_clock_converter_v2_1_28 -l blk_mem_gen_v8_4_7 -l axi_dwidth_converter_v2_1_29 -l axi_mmu_v2_1_27 \
"../../../bd/design_1/ip/design_1_SAXI_ip_0_0/sim/design_1_SAXI_ip_0_0.v" \
"../../../bd/design_1/ip/design_1_MAXI_ip_0_0/sim/design_1_MAXI_ip_0_0.v" \

vlog -work axi_protocol_converter_v2_1_29  -v2k5 "+incdir+../../../../nru.gen/sources_1/bd/design_1/ipshared/ec67/hdl" "+incdir+../../../../nru.gen/sources_1/bd/design_1/ipshared/2fcd/hdl" "+incdir+C:/Xilinx/Vivado/2023.2/data/xilinx_vip/include" -l xilinx_vip -l xpm -l generic_baseblocks_v2_1_1 -l axi_infrastructure_v1_1_0 -l axi_register_slice_v2_1_29 -l fifo_generator_v13_2_9 -l axi_data_fifo_v2_1_28 -l axi_crossbar_v2_1_30 -l xil_defaultlib -l axi_vip_v1_1_15 -l zynq_ultra_ps_e_vip_v1_0_15 -l lib_cdc_v1_0_2 -l proc_sys_reset_v5_0_14 -l axi_protocol_converter_v2_1_29 -l axi_clock_converter_v2_1_28 -l blk_mem_gen_v8_4_7 -l axi_dwidth_converter_v2_1_29 -l axi_mmu_v2_1_27 \
"../../../../nru.gen/sources_1/bd/design_1/ipshared/a63f/hdl/axi_protocol_converter_v2_1_vl_rfs.v" \

vlog -work axi_clock_converter_v2_1_28  -v2k5 "+incdir+../../../../nru.gen/sources_1/bd/design_1/ipshared/ec67/hdl" "+incdir+../../../../nru.gen/sources_1/bd/design_1/ipshared/2fcd/hdl" "+incdir+C:/Xilinx/Vivado/2023.2/data/xilinx_vip/include" -l xilinx_vip -l xpm -l generic_baseblocks_v2_1_1 -l axi_infrastructure_v1_1_0 -l axi_register_slice_v2_1_29 -l fifo_generator_v13_2_9 -l axi_data_fifo_v2_1_28 -l axi_crossbar_v2_1_30 -l xil_defaultlib -l axi_vip_v1_1_15 -l zynq_ultra_ps_e_vip_v1_0_15 -l lib_cdc_v1_0_2 -l proc_sys_reset_v5_0_14 -l axi_protocol_converter_v2_1_29 -l axi_clock_converter_v2_1_28 -l blk_mem_gen_v8_4_7 -l axi_dwidth_converter_v2_1_29 -l axi_mmu_v2_1_27 \
"../../../../nru.gen/sources_1/bd/design_1/ipshared/769c/hdl/axi_clock_converter_v2_1_vl_rfs.v" \

vlog -work blk_mem_gen_v8_4_7  -v2k5 "+incdir+../../../../nru.gen/sources_1/bd/design_1/ipshared/ec67/hdl" "+incdir+../../../../nru.gen/sources_1/bd/design_1/ipshared/2fcd/hdl" "+incdir+C:/Xilinx/Vivado/2023.2/data/xilinx_vip/include" -l xilinx_vip -l xpm -l generic_baseblocks_v2_1_1 -l axi_infrastructure_v1_1_0 -l axi_register_slice_v2_1_29 -l fifo_generator_v13_2_9 -l axi_data_fifo_v2_1_28 -l axi_crossbar_v2_1_30 -l xil_defaultlib -l axi_vip_v1_1_15 -l zynq_ultra_ps_e_vip_v1_0_15 -l lib_cdc_v1_0_2 -l proc_sys_reset_v5_0_14 -l axi_protocol_converter_v2_1_29 -l axi_clock_converter_v2_1_28 -l blk_mem_gen_v8_4_7 -l axi_dwidth_converter_v2_1_29 -l axi_mmu_v2_1_27 \
"../../../../nru.gen/sources_1/bd/design_1/ipshared/3c0c/simulation/blk_mem_gen_v8_4.v" \

vlog -work axi_dwidth_converter_v2_1_29  -v2k5 "+incdir+../../../../nru.gen/sources_1/bd/design_1/ipshared/ec67/hdl" "+incdir+../../../../nru.gen/sources_1/bd/design_1/ipshared/2fcd/hdl" "+incdir+C:/Xilinx/Vivado/2023.2/data/xilinx_vip/include" -l xilinx_vip -l xpm -l generic_baseblocks_v2_1_1 -l axi_infrastructure_v1_1_0 -l axi_register_slice_v2_1_29 -l fifo_generator_v13_2_9 -l axi_data_fifo_v2_1_28 -l axi_crossbar_v2_1_30 -l xil_defaultlib -l axi_vip_v1_1_15 -l zynq_ultra_ps_e_vip_v1_0_15 -l lib_cdc_v1_0_2 -l proc_sys_reset_v5_0_14 -l axi_protocol_converter_v2_1_29 -l axi_clock_converter_v2_1_28 -l blk_mem_gen_v8_4_7 -l axi_dwidth_converter_v2_1_29 -l axi_mmu_v2_1_27 \
"../../../../nru.gen/sources_1/bd/design_1/ipshared/670d/hdl/axi_dwidth_converter_v2_1_vl_rfs.v" \

vlog -work xil_defaultlib  -v2k5 "+incdir+../../../../nru.gen/sources_1/bd/design_1/ipshared/ec67/hdl" "+incdir+../../../../nru.gen/sources_1/bd/design_1/ipshared/2fcd/hdl" "+incdir+C:/Xilinx/Vivado/2023.2/data/xilinx_vip/include" -l xilinx_vip -l xpm -l generic_baseblocks_v2_1_1 -l axi_infrastructure_v1_1_0 -l axi_register_slice_v2_1_29 -l fifo_generator_v13_2_9 -l axi_data_fifo_v2_1_28 -l axi_crossbar_v2_1_30 -l xil_defaultlib -l axi_vip_v1_1_15 -l zynq_ultra_ps_e_vip_v1_0_15 -l lib_cdc_v1_0_2 -l proc_sys_reset_v5_0_14 -l axi_protocol_converter_v2_1_29 -l axi_clock_converter_v2_1_28 -l blk_mem_gen_v8_4_7 -l axi_dwidth_converter_v2_1_29 -l axi_mmu_v2_1_27 \
"../../../bd/design_1/ip/design_1_auto_us_0/sim/design_1_auto_us_0.v" \
"../../../bd/design_1/ip/design_1_auto_ds_0/sim/design_1_auto_ds_0.v" \

vlog -work axi_mmu_v2_1_27  -v2k5 "+incdir+../../../../nru.gen/sources_1/bd/design_1/ipshared/ec67/hdl" "+incdir+../../../../nru.gen/sources_1/bd/design_1/ipshared/2fcd/hdl" "+incdir+C:/Xilinx/Vivado/2023.2/data/xilinx_vip/include" -l xilinx_vip -l xpm -l generic_baseblocks_v2_1_1 -l axi_infrastructure_v1_1_0 -l axi_register_slice_v2_1_29 -l fifo_generator_v13_2_9 -l axi_data_fifo_v2_1_28 -l axi_crossbar_v2_1_30 -l xil_defaultlib -l axi_vip_v1_1_15 -l zynq_ultra_ps_e_vip_v1_0_15 -l lib_cdc_v1_0_2 -l proc_sys_reset_v5_0_14 -l axi_protocol_converter_v2_1_29 -l axi_clock_converter_v2_1_28 -l blk_mem_gen_v8_4_7 -l axi_dwidth_converter_v2_1_29 -l axi_mmu_v2_1_27 \
"../../../../nru.gen/sources_1/bd/design_1/ipshared/38ff/hdl/axi_mmu_v2_1_vl_rfs.v" \

vlog -work xil_defaultlib  -v2k5 "+incdir+../../../../nru.gen/sources_1/bd/design_1/ipshared/ec67/hdl" "+incdir+../../../../nru.gen/sources_1/bd/design_1/ipshared/2fcd/hdl" "+incdir+C:/Xilinx/Vivado/2023.2/data/xilinx_vip/include" -l xilinx_vip -l xpm -l generic_baseblocks_v2_1_1 -l axi_infrastructure_v1_1_0 -l axi_register_slice_v2_1_29 -l fifo_generator_v13_2_9 -l axi_data_fifo_v2_1_28 -l axi_crossbar_v2_1_30 -l xil_defaultlib -l axi_vip_v1_1_15 -l zynq_ultra_ps_e_vip_v1_0_15 -l lib_cdc_v1_0_2 -l proc_sys_reset_v5_0_14 -l axi_protocol_converter_v2_1_29 -l axi_clock_converter_v2_1_28 -l blk_mem_gen_v8_4_7 -l axi_dwidth_converter_v2_1_29 -l axi_mmu_v2_1_27 \
"../../../bd/design_1/ip/design_1_s00_mmu_0/sim/design_1_s00_mmu_0.v" \
"../../../bd/design_1/ip/design_1_s01_mmu_0/sim/design_1_s01_mmu_0.v" \
"../../../bd/design_1/sim/design_1.v" \

vlog -work xil_defaultlib \
"glbl.v"

