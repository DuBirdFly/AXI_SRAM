class AxiMstrChnW extends uvm_driver #(TrAxi);

    /* Factory Register this Class */
    `uvm_component_utils(AxiMstrChnW)

    /* Declare Normal Variables */

    /* Declare Object Handles */
    virtual IfAxi vifAxi;
    uvm_blocking_put_port #(TrAxi) put_port = new("put_port", this);

    function new(string name = "AxiMstrChnW", uvm_component parent);
        super.new(name, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        /* uvm_config_db#(<type>)::get(<uvm_component>, <"inst_name">, <"field_name">, <value>); */
        if (!uvm_config_db#(virtual IfAxi)::get(this, "", "vifAxi", vifAxi))
            `uvm_fatal("NOVIF", "No IfAxi Interface Specified")
        /* uvm_config_db#(<type>)::set(<uvm_component>, <"inst_name">, <"field_name">, <value>); */
    endfunction

    virtual task reset_phase(uvm_phase phase);
        phase.raise_objection(this);
        {vifAxi.wdata, vifAxi.wstrb, vifAxi.wlast, vifAxi.wvalid} = '{default:0};
        phase.drop_objection(this);
    endtask

    virtual task run_phase(uvm_phase phase);

        wait(vifAxi.aresetn);
        repeat (10) @(vifAxi.m_cb);

        forever begin
            seq_item_port.get_next_item(req);

            w_channel(req, 0);

            seq_item_port.item_done();
        end

    endtask

    //! 断言 VALID (AxVALID/xVALID) 信号时，它必须保持处于已断言状态直至从设备发出 AxREADY/xREADY 断言后出现上升时钟沿为止
    virtual task w_channel(TrAxi tr, int pre_delay = 0);
        repeat (pre_delay) @(vifAxi.m_cb);

        foreach (tr.data[i]) begin
            // int value;
            // void'( std::randomize(value) with { value dist {0:/7, [1:3]:/1}; } );
            // repeat (value) begin
            //     vifAxi.m_cb.wvalid <= 0;
            //     @(vifAxi.m_cb);
            // end

            vifAxi.m_cb.wvalid <= 1;
            vifAxi.m_cb.wdata  <= tr.data[i];
            vifAxi.m_cb.wstrb  <= tr.align_wstrb[i];        //! 本应该用 tr.wstrb[i] 的, 但是有些 axi_slv 不支持
            if (i == tr.data.size() - 1) vifAxi.m_cb.wlast  <= 1;

            @(vifAxi.m_cb);

            while (!vifAxi.m_cb.wready) @(vifAxi.m_cb);
        end

        vifAxi.m_cb.wlast  <= 0;
        vifAxi.m_cb.wvalid <= 0;

        put_port.put(tr);

    endtask

endclass
