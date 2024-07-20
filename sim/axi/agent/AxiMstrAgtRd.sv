class AxiMstrAgtRd extends uvm_agent;

    /* Factory Register this Class */
    `uvm_component_utils(AxiMstrAgtRd)

    /* Declare Normal Variables */

    /* Declare Object Handles */
    AxiMstrSqrAr axiMstrSqrAr = AxiMstrSqrAr::type_id::create("axiMstrSqrAr", this);
    AxiMstrChnAr axiMstrChnAr = AxiMstrChnAr::type_id::create("axiMstrChnAr", this);

    AxiMstrChnR  axiMstrChnR  = AxiMstrChnR::type_id::create("axiMstrChnR", this);
    AxiMstrMonR  axiMstrMonR  = AxiMstrMonR::type_id::create("axiMstrMonR", this);

    function new(string name = "AxiMstrAgtRd", uvm_component parent);
        super.new(name, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        /* uvm_config_db#(<type>)::get(<uvm_component>, <"inst_name">, <"field_name">, <value>); */
        /* uvm_config_db#(<type>)::set(<uvm_component>, <"inst_name">, <"field_name">, <value>); */
    endfunction

    virtual function void connect_phase(uvm_phase phase);
        // [Chn] <--> [Sqr]
        axiMstrChnAr.seq_item_port.connect(axiMstrSqrAr.seq_item_export);
    endfunction

endclass
