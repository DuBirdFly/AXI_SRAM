# README

## 编译 uvm-1.2

gcc 下载: <https://download.csdn.net/download/weixin_39565666/10290013>
下载完成后, 在终端中输入 `g++ --version` 查看是否安装成功

```sh
g++.exe (GCC) 4.5.0
Copyright (C) 2010 Free Software Foundation, Inc.
This is free software; see the source for copying conditions.  There is NO
warranty; not even for MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
```

在 **modelsim** 中执行以下指令以生成 dll 文件
*注意，要先新建 OUTPUT_DIR 文件夹*

```sh
set MODELSIM_DIR    D:/Codes/Modelsim/Modelsim_10_7
set OUTPUT_DIR      C:/Users/Administrator/Desktop/dll

D:/Env/MinGW/modelsim-gcc-4.5.0-mingw64/bin/g++.exe -DQUESTA -W -shared -Bsymbolic -I $MODELSIM_DIR/include $MODELSIM_DIR/verilog_src/uvm-1.2/src/dpi/uvm_dpi.cc -o $OUTPUT_DIR/uvm_dpi.dll $MODELSIM_DIR/win64/mtipli.dll -lregex
```

...没搞成功, 报错如下:

```sh
C:\Users\ADMINI~1\AppData\Local\Temp\ccnQXeIY.o:uvm_dpi.cc:(.text+0x63): undefined reference to `m__uvm_report_dpi'
collect2: ld returned 1 exit status
```

## Modelsim 常用指令

```sh
python run.py

vsim -c -do run.do
vsim -view vsim.wlf -do ../signal/wave.do
vsim -view vsim.wlf

do ../wave.do
do dataset reload -f
```

## sv 的系统函数

对于随机对象，可以采用object.randomize()的方式进行随机化，但有的时候可以通过更简单的方式，不必定义类和例化对象，甚至变量都不是随机类型，也可以对其进行随机化，这就是系统随机化函数 `std::randomize`。

```SystemVerilog
initial begin
    int value;  
    std::randomize(value) with {value>=0 && value<=10;};
end
```

## UVM 总结

1. Driver 的 run_phase 不能用 phase.drop/raise_objection(phase), 否则会导致 run_phase 无法结束!!
2. timescale 必须在 import 之后
3. task 的 forever 内必须有时序控制，否则会导致死循环
