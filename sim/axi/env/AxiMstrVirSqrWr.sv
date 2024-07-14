class AxiMstrVirSqrWr extends uvm_sequencer;

    /* Factory Register this Class */
    `uvm_component_utils(AxiMstrVirSqrWr)

    /* Declare Normal Variables */

    /* Declare Object Handles */
    AxiMstrSqrAw axiMstrSqrAw;
    AxiMstrSqrW  axiMstrSqrW;

    function new(string name = "AxiMstrVirSqrWr", uvm_component parent);
        super.new(name, parent);
    endfunction

endclass
