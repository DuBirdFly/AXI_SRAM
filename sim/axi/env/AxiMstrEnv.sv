class AxiMstrEnv extends uvm_env;

    /* Factory Register this Class */
    `uvm_component_utils(AxiMstrEnv)

    /* Declare Normal Variables */

    /* Declare Object Handles */
    AxiMstrVirSqrWr axiMstrVirSqrWr = AxiMstrVirSqrWr::type_id::create("axiMstrVirSqrWr", this);

    AxiMstrAgtWr    axiMstrAgtWr    = AxiMstrAgtWr::type_id::create("axiMstrAgtWr", this);
    AxiMstrAgtRd    axiMstrAgtRd    = AxiMstrAgtRd::type_id::create("axiMstrAgtRd", this);

    AxiSlvRef       axiSlvRef       = AxiSlvRef::type_id::create("axiSlvRef", this);
    AxiSlvScb       axiSlvScb       = AxiSlvScb::type_id::create("axiSlvScb", this);

    function new(string name = "AxiMstrEnv", uvm_component parent);
        super.new(name, parent);
    endfunction

    virtual function void connect_phase(uvm_phase phase);
        // [VirSqr] <--> [Sqr]
        axiMstrVirSqrWr.axiMstrSqrAw = axiMstrAgtWr.axiMstrSqrAw;
        axiMstrVirSqrWr.axiMstrSqrW  = axiMstrAgtWr.axiMstrSqrW;

        // [Chn]    ---> [Ref]
        axiMstrAgtWr.axiMstrChnAw.put_port.connect(axiSlvRef.imp_aw);
        axiMstrAgtWr.axiMstrChnW.put_port.connect(axiSlvRef.imp_w);
        axiMstrAgtWr.axiMstrChnB.put_port.connect(axiSlvRef.imp_b);

        // [Chn]    ---> [Scb]
        axiMstrAgtRd.axiMstrChnAr.put_port.connect(axiSlvScb.imp_ar);
        // axiMstrAgtRd.axiMstrChnR.put_port.connect(axiSlvScb.imp_r);
        axiMstrAgtRd.axiMstrMonR.put_port.connect(axiSlvScb.imp_r);

        // [Scb]    <--> [Ref]
        axiSlvScb.transport_port.connect(axiSlvRef.transport_imp);
    endfunction

endclass
