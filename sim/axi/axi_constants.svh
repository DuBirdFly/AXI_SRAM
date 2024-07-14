// 可配置
`define AXI_ID_WIDTH    8
`define AXI_ADDR_WIDTH  16
`define AXI_DATA_WIDTH  256
// `define AXI_WSTRB_WIDTH (`AXI_DATA_WIDTH/8)
`define AXI_WSTRB_WIDTH 32
// `define AXI_SIZE_MAX    $clog2(`AXI_WSTRB_WIDTH)
`define AXI_SIZE_MAX    5

`define AXI_OUTSTANDING 8

// 不可配置
`define AXI_LEN_WIDTH   8
`define AXI_SIZE_WIDTH  3
`define AXI_BURST_WIDTH 2
`define AXI_LOCK_WIDTH  1
`define AXI_CACHE_WIDTH 4
`define AXI_PROT_WIDTH  3
`define AXI_RESP_WIDTH  2
`define AXI_BURST_BOUNDAEY  4096
