vlib work
vmap work work


#编译testbench文件
vlog ../sim/tb.v

#编译 	设计文件


#添加库文件
vlog ../src/spi_master.v
vlog ../src/flash_read.v
vlog ../src/flash_write.v
vlog ../src/control.v
vlog ../src/param.v

#指定仿真顶层
vsim -novopt work.tb
#添加信号到波形窗 	
add wave -position insertpoint sim:/tb//*