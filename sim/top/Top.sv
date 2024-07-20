module Top;

    bit aclk;
    always #5 aclk = ~aclk;
    IfAxi ifAxi (aclk);

    // wrap_axi_s_vip_0 u_wrap_axi_s_vip_0 (ifAxi.SLAVE);
    wrap_axi_ram u_wrap_axi_ram (ifAxi.SLAVE);

    initial begin
        uvm_config_db#(virtual IfAxi)::set(null, "uvm_test_top", "vifAxi", ifAxi);
        uvm_config_db#(virtual IfAxi)::set(null, "uvm_test_top.env.axiMstrEnv.axiMstrAgtWr.axiMstrChnAw", "vifAxi", ifAxi);
        uvm_config_db#(virtual IfAxi)::set(null, "uvm_test_top.env.axiMstrEnv.axiMstrAgtWr.axiMstrChnW",  "vifAxi", ifAxi);
        uvm_config_db#(virtual IfAxi)::set(null, "uvm_test_top.env.axiMstrEnv.axiMstrAgtWr.axiMstrChnB",  "vifAxi", ifAxi);
        uvm_config_db#(virtual IfAxi)::set(null, "uvm_test_top.env.axiMstrEnv.axiMstrAgtRd.axiMstrChnAr", "vifAxi", ifAxi);
        uvm_config_db#(virtual IfAxi)::set(null, "uvm_test_top.env.axiMstrEnv.axiMstrAgtRd.axiMstrChnR",  "vifAxi", ifAxi);
        uvm_config_db#(virtual IfAxi)::set(null, "uvm_test_top.env.axiMstrEnv.axiMstrAgtRd.axiMstrMonR",  "vifAxi", ifAxi);
    end

    initial begin
        $timeformat(-9, 0, "ns", 12);
    end

    initial begin
        run_test("Test");
    end

    initial begin
        `ifdef MODELSIM
            $wlfdumpvars();
        `endif
    end

endmodule
