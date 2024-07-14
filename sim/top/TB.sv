import uvm_pkg::*;
`include "uvm_macros.svh"

//! timescale 必须在 import 之后
`timescale 1ns/1ns

// defines
`include "zpf_defines.svh"

// axi
`include "axi_includes.svh"

// env
`include "Env.sv"

// test
`include "Test.sv"

// wrapper
`include "wrap_axi_ram.sv"

// top
`include "Top.sv"
