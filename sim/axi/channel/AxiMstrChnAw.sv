class AxiMstrChnAw extends uvm_driver #(TrAxi);

    /* Factory Register this Class */
    `uvm_component_utils(AxiMstrChnAw)

    /* Declare Normal Variables */

    /* Declare Object Handles */
    virtual IfAxi vifAxi;
    uvm_blocking_put_port #(TrAxi) put_port = new("put_port", this);

    function new(string name = "AxiMstrChnAw", uvm_component parent);
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

        {vifAxi.awid, vifAxi.awaddr, vifAxi.awlen, vifAxi.awsize, vifAxi.awburst, vifAxi.awvalid} = '{default:0};

        vifAxi.aresetn = 0;
        repeat (20) @(vifAxi.m_cb);
        vifAxi.aresetn = 1;

        phase.drop_objection(this);
    endtask

    virtual task run_phase(uvm_phase phase);
        wait(vifAxi.aresetn);
        repeat (10) @(vifAxi.m_cb);

        forever begin
            seq_item_port.get_next_item(req);
            aw_channel(req, 0);
            seq_item_port.item_done();
        end
    endtask

    virtual task aw_channel(TrAxi tr, int pre_delay = 0);
        repeat (pre_delay) @(vifAxi.m_cb);

        vifAxi.m_cb.awid    <= tr.id;
        vifAxi.m_cb.awaddr  <= tr.addr;
        vifAxi.m_cb.awlen   <= tr.len;
        vifAxi.m_cb.awsize  <= tr.size;
        vifAxi.m_cb.awburst <= tr.burst;
        vifAxi.m_cb.awvalid <= 1;
        @(vifAxi.m_cb);

        while (!vifAxi.m_cb.awready) @(vifAxi.m_cb);

        vifAxi.m_cb.awvalid <= 0;

        put_port.put(tr);

    endtask


endclass
