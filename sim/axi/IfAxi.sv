interface IfAxi (
    input bit                       aclk
);

    logic                           aresetn;

    logic [`AXI_ID_WIDTH-1:0]       awid;
    logic [`AXI_ADDR_WIDTH-1:0]     awaddr;
    logic [`AXI_LEN_WIDTH-1:0]      awlen;
    logic [`AXI_SIZE_WIDTH-1:0]     awsize;
    logic [`AXI_BURST_WIDTH-1:0]    awburst;
    logic                           awvalid;
    logic                           awready;

    logic [`AXI_DATA_WIDTH-1:0]     wdata;
    logic [`AXI_WSTRB_WIDTH-1:0]    wstrb;
    logic                           wlast;
    logic                           wvalid;
    logic                           wready;

    logic [`AXI_ID_WIDTH-1:0]       bid;
    logic [`AXI_RESP_WIDTH-1:0]     bresp;
    logic                           bvalid;
    logic                           bready;

    logic [`AXI_ID_WIDTH-1:0]       arid;
    logic [`AXI_ADDR_WIDTH-1:0]     araddr;
    logic [`AXI_LEN_WIDTH-1:0]      arlen;
    logic [`AXI_SIZE_WIDTH-1:0]     arsize;
    logic [`AXI_BURST_WIDTH-1:0]    arburst;
    logic                           arvalid;
    logic                           arready;

    logic [`AXI_ID_WIDTH-1:0]       rid;
    logic [`AXI_RESP_WIDTH-1:0]     rresp;
    logic [`AXI_DATA_WIDTH-1:0]     rdata;
    logic                           rlast;
    logic                           rvalid;
    logic                           rready;

    clocking m_cb @(posedge aclk);
        default input #1 output #1;
        output aresetn;

        output awid, awaddr, awlen, awsize, awburst;
        output awvalid;
        input  awready;

        output wdata, wstrb, wlast;
        output wvalid;
        input  wready;

        input  bid, bresp;
        input  bvalid;
        output bready;

        output arid, araddr, arlen, arsize, arburst;
        output arvalid;
        input  arready;

        input  rid, rdata, rresp, rlast;
        input  rvalid;
        output rready;
    endclocking

    clocking mon_cb @(posedge aclk);
        default input #1 output #1;
        input  aresetn;

        input  awid, awaddr, awlen, awsize, awburst;
        input  awvalid;
        input  awready;

        input  wdata, wstrb, wlast;
        input  wvalid;
        input  wready;

        input  bid, bresp;
        input  bvalid;
        input  bready;

        input  arid, araddr, arlen, arsize, arburst;
        input  arvalid;
        input  arready;

        input  rid, rdata, rresp, rlast;
        input  rvalid;
        input  rready;
    endclocking

    modport SLAVE (
        input  aclk,
        input  aresetn,

        input  awid, awaddr, awlen, awsize, awburst,
        input  awvalid,
        output awready,

        input  wdata, wstrb, wlast,
        input  wvalid,
        output wready,

        output bid, bresp,
        output bvalid,
        input  bready,

        input  arid, araddr, arlen, arsize, arburst,
        input  arvalid,
        output arready,

        output rid, rdata, rresp, rlast,
        output rvalid,
        input  rready
    );

    function void peek_mem();
        $display("\n============================== PEEK DUT MEMORY ==============================");
        // foreach (Top.u_wrap_axi_ram.u_axi_ram.mem[i]) begin
        for (int i = 0; i < Top.u_wrap_axi_ram.u_axi_ram.mem.size(); i++) begin
            automatic logic [`AXI_DATA_WIDTH - 1:0] data = Top.u_wrap_axi_ram.u_axi_ram.mem[i];
            if (data != 0) $display("mem[0x%0h] axi[0x%0h] %h", i, i * `AXI_WSTRB_WIDTH, data);
        end
        $display("=============================================================================\n");
    endfunction

endinterface
