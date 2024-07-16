class AxiMstrChnAr extends uvm_driver #(TrAxi);

    /* Factory Register this Class */
    `uvm_component_utils(AxiMstrChnAr)

    /* Declare Normal Variables */

    /* Declare Object Handles */
    virtual IfAxi vifAxi;
    uvm_blocking_put_port #(TrAxi) put_port = new("put_port", this);

    function new(string name = "AxiMstrChnAr", uvm_component parent);
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
        {vifAxi.arid, vifAxi.araddr, vifAxi.arlen, vifAxi.arsize, vifAxi.arburst, vifAxi.arvalid} = '{default:0};
        phase.drop_objection(this);
    endtask

    virtual task run_phase(uvm_phase phase);

        wait(vifAxi.aresetn);
        repeat (10) @(vifAxi.m_cb);

        forever begin
            seq_item_port.get_next_item(req);
            ar_channel(req, 0);
            seq_item_port.item_done();
        end

    endtask

    virtual task ar_channel(TrAxi req, int pre_delay = 0);
        repeat (pre_delay) @(vifAxi.m_cb);

        vifAxi.m_cb.arid    <= req.id;
        vifAxi.m_cb.araddr  <= req.addr;
        vifAxi.m_cb.arlen   <= req.len;
        vifAxi.m_cb.arsize  <= req.size;
        vifAxi.m_cb.arburst <= req.burst;
        vifAxi.m_cb.arvalid <= 1;
        @(vifAxi.m_cb);

        while (!vifAxi.m_cb.arready) @(vifAxi.m_cb);

        vifAxi.m_cb.arvalid <= 0;

        put_port.put(req);

    endtask

endclass
