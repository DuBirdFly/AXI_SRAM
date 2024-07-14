# -*- coding: utf-8 -*-

import os, subprocess, shutil

PWD      : str = os.path.abspath('../..').replace('\\', '/')

DIR_OUT      : str = f'out'
DIR_FLIST    : str = f'run_file'
DIR_SIM      : str = f'{PWD}/sim'

TB_TOP_PATH  : str = f'{DIR_SIM}/top/TB.sv'
TB_TOP_NAME  : str = f'Top'
TB_TEST_NAME : str = f'Test'

SV_SEED      : int = 0

MODELSIM     : bool = True
VIVADO       : bool = False
IVERILOG     : bool = False

if sum([MODELSIM, VIVADO, IVERILOG]) != 1:
    raise Exception(f'Only one of Compile Software can be True')

UVM_HOME : str = f'D:/Codes/Modelsim/Modelsim_10_7/verilog_src/uvm-1.1d'
UVM_LIB  : str = f'D:/Codes/Modelsim/Modelsim_10_7/uvm-1.1d/win64/uvm_dpi'          # 无需 .dll

if not os.path.exists(ph := DIR_OUT):           os.makedirs(ph)
if not os.path.exists(ph := DIR_FLIST):         os.makedirs(ph)
if not os.path.exists(ph := UVM_HOME):          raise Exception(f'Not found UVM_HOME: {ph}')
if not os.path.exists(ph := f'{UVM_LIB}.dll'):  raise Exception(f'Not found UVM_LIB: {ph}')

#################################################################
def list2file(file_path: str, lines: list[str]) -> None:
    with open(file_path, 'w') as f:
        for line in lines: f.write(f'{line}\n')
    return

#################################################################
####################### run.do ##################################
#################################################################
lines : list[str] = []

lines.append(f'vlib work')
lines.append(f'vmap work work')
lines.append(f'vlog -f "../{DIR_FLIST}/vlog.f"')
lines.append(f'vsim -f "../{DIR_FLIST}/vsim.f"')
lines.append(f'run -all')
lines.append(f'q')

list2file(f'{DIR_OUT}/run.do', lines)

#################################################################
####################### vlog.f ##################################
#################################################################
lines : list[str] = []

lines.append(f'-incr -mfcu -sv')
lines.append(f'')

lines.append(f'-work work')
lines.append(f'-L mtiAvm -L mtiOvm -L mtiUvm -L mtiUPF')
lines.append(f"+acc")
lines.append(f'')

lines.append(f'+define+DUMP_WLF')
if MODELSIM: lines.append(f'+define+MODELSIM')
if VIVADO:   lines.append(f'+define+VIVADO')
lines.append(f'')

lines.append(f'+incdir+{UVM_HOME}/src')
lines.append(f'{UVM_HOME}/src/uvm_pkg.sv')
lines.append(f'')

for root, dirs, files in os.walk(f'{DIR_SIM}'):
    for dir in dirs:
        root_tmp = root.replace('\\', '/')
        lines.append(f'+incdir+{root_tmp}/{dir}')
lines.append(f'')

lines.append(f'{TB_TOP_PATH}')                      #! tb_top 一定要放在最上面
lines.append(f'')

lines.append(f'{PWD}/dut/axi_ram.sv')               #! dut filelist
lines.append(f'')

list2file(f'{DIR_FLIST}/vlog.f', lines)
#################################################################
####################### vsim.f ##################################
#################################################################
lines : list[str] = []

lines.append(f'-voptargs="+acc"')
lines.append(f'')

lines.append(f'-L work')
lines.append(f'')

lines.append(f'-sv_seed {SV_SEED}')
lines.append(f'-sv_lib {UVM_LIB}')
lines.append(f'-lib work')
lines.append(f'+UVM_TESTNAME={TB_TEST_NAME}')
lines.append(f'work.{TB_TOP_NAME}')
lines.append(f'')

list2file(f'{DIR_FLIST}/vsim.f', lines)
#################################################################
subprocess.run(f'vsim -c -do run.do -l run.log', shell=True, cwd='out')
