class AxiMstrSeqRd extends uvm_sequence #(TrAxi);

    /* Factory Register this Class */
    `uvm_object_utils(AxiMstrSeqRd)

    /* Declare Normal Variables */

    /* Declare Object Handles */

    function new(string name = "AxiMstrSeqRd");
        super.new(name);
    endfunction

    virtual task body();
        if (starting_phase != null) starting_phase.raise_objection(this);
        case_0_run(16);
        if (starting_phase != null) starting_phase.drop_objection(this);
    endtask

    // 发送随机的 INCR 读
    virtual task case_0_run(int tr_num);
        TrAxi tr_ar;

        // 发送主体部分
        repeat (tr_num) begin
            TrAxi tr = TrAxi::type_id::create("tr");
            tr.wr_flag = 0;
            `zpf_randomize_with(tr, {addr < 2048; len < 4; burst == 1;})
            // `uvm_info(get_type_name(), {"Sending INCR Read:\n", tr_ar.get_info()}, UVM_MEDIUM)
            `zpf_do_on_clone(tr, tr_ar, m_sequencer)
        end

    endtask

endclass
