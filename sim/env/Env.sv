class Env extends uvm_env;

    /* Factory Register this Class */
    `uvm_component_utils(Env)

    /* Declare Normal Variables */

    /* Declare Object Handles */
    AxiMstrEnv axiMstrEnv = AxiMstrEnv::type_id::create("axiMstrEnv", this);

    function new(string name = "Env", uvm_component parent);
        super.new(name, parent);
    endfunction

endclass
