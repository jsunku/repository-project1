#ghdl compile --std=08 tb_c-band.vhd c-band.vhd -r tb_c_band --stop-time=100us --wave=t1.ghw
#gtkwave t1.ghw t1.gtkw

#ghdl compile --std=08 tb_c-band1.vhd c-band1.vhd -r tb_c_band1 --stop-time=100us --wave=t2.ghw
#gtkwave t2.ghw t2.gtkw

ghdl -c --std=08 global_package.vhd g1g_pstc_packet_handling.vhd  stc_pkt_handler_package.vhd\
g1g_pstc_packet_handlinge.vhd g1g_stc_mem_interfacer.vhd  \
#tb_sband_g1g_top.vhd
#ghdl -m --std=08 tb_sband_g1g_top
#ghdl -r --std=08 tb_sband_g1g_top --wave=tb_sband_g1g_top.ghw --stop-time=1ms
#gtkwave tb_sband_g1g_top.ghw tb_sband_g1g_top.gtkw
#tb_input_prio.vhd -e tb_input_prio.vhd
#ghdl -r --std=08 tb_input_prio --stop-time=1400us --wave=input_prio.ghw
#gtkwave input_prio.ghw input_prio.gtkw
#ghdl compile --std=08 tb_c-band.vhd c-band.vhd -r tb_c_band --stop-time=100us --wave=t1.ghw
#gtkwave t1.ghw t1.gtkw

#ghdl compile --std=08 tb_c-band1.vhd c-band1.vhd -r tb_c_band1 --stop-time=100us --wave=t2.ghw
#gtkwave t2.ghw t2.gtkw


#common_package.vhd global_package.vhd crc16_package.vhd \
    #common_components_package.vhd \
   # G2G_SBAND_TC_input_prio_package.vhd G2G_SBAND_TC_input_prio.vhd \
   # G2G_SBAND_TC_RND_package.vhd G2G_SBAND_TC_RND.vhd  G2G_SBAND_TC_frame_check_package.vhd G2G_SBAND_TC_frame_check.vhd \
   # G2G_SBAND_TC_top_package.vhd G2G_SBAND_TC_top.vhd tb_G2G_SBAND_TC_top.vhd
#ghdl -m --std=08 tb_g2g_sband_tc_top
#ghdl -r --std=08 tb_g2g_sband_tc_top --stop-time=4400us --wave=tb_g2g_sband_tc_top.ghw
#gtkwave tb_g2g_sband_tc_top.ghw tb_g2g_sband_tc_top.gtkw
