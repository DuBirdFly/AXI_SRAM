class AxiMstrChnB extends uvm_driver #(TrAxi);

    /* Factory Register this Class */
    `uvm_component_utils(AxiMstrChnB)

    /* Declare Normal Variables */

    /* Declare Object Handles */
    virtual IfAxi vifAxi;
    uvm_blocking_put_port #(TrAxi) put_port = new("put_port", this);

    function new(string name = "AxiMstrChnB", uvm_component parent);
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
        {vifAxi.bready} = '{default:0};
        phase.drop_objection(this);
    endtask

    virtual task run_phase(uvm_phase phase);
        wait(vifAxi.aresetn);
        repeat (10) @(vifAxi.m_cb);
        forever begin
            b_channel(0);
        end
    endtask

    virtual task b_channel(input int pre_delay = 0);
        TrAxi tr = TrAxi::type_id::create("tr");

        repeat (pre_delay) @(vifAxi.m_cb);

        while (!vifAxi.m_cb.bvalid) @(vifAxi.m_cb);

        vifAxi.m_cb.bready <= 1;

        tr.id = vifAxi.m_cb.bid;
        tr.resp = vifAxi.m_cb.bresp;

        @(vifAxi.m_cb);
        vifAxi.m_cb.bready <= 0;
        @(vifAxi.m_cb);

        put_port.put(tr);

    endtask

endclass
