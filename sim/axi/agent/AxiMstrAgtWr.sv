class AxiMstrAgtWr extends uvm_agent;

    /* Factory Register this Class */
    `uvm_component_utils(AxiMstrAgtWr)

    /* Declare Normal Variables */

    /* Declare Object Handles */
    AxiMstrSqrAw axiMstrSqrAw = AxiMstrSqrAw::type_id::create("axiMstrSqrAw", this);
    AxiMstrChnAw axiMstrChnAw = AxiMstrChnAw::type_id::create("axiMstrChnAw", this);

    AxiMstrSqrW  axiMstrSqrW  = AxiMstrSqrW::type_id::create("axiMstrSqrW", this);
    AxiMstrChnW  axiMstrChnW  = AxiMstrChnW::type_id::create("axiMstrChnW", this);

    AxiMstrChnB  axiMstrChnB  = AxiMstrChnB::type_id::create("axiMstrChnB", this);

    function new(string name = "AxiMstrAgtWr", uvm_component parent);
        super.new(name, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        /* uvm_config_db#(<type>)::get(<uvm_component>, <"inst_name">, <"field_name">, <value>); */
        /* uvm_config_db#(<type>)::set(<uvm_component>, <"inst_name">, <"field_name">, <value>); */
    endfunction

    virtual function void connect_phase(uvm_phase phase);
        // [Chn] <--> [Sqr]
        axiMstrChnAw.seq_item_port.connect(axiMstrSqrAw.seq_item_export);
        axiMstrChnW.seq_item_port.connect(axiMstrSqrW.seq_item_export);
    endfunction

endclass
