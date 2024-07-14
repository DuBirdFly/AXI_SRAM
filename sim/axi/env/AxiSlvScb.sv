`uvm_blocking_put_imp_decl(_ar)
`uvm_blocking_put_imp_decl(_r)

class AxiSlvScb extends uvm_scoreboard;

    /* Factory Register this Class */
    `uvm_component_utils(AxiSlvScb)

    /* Declare Normal Variables */

    /* Declare Object Handles */
    uvm_blocking_put_imp_ar #(TrAxi, AxiSlvScb) imp_ar = new("imp_ar", this);
    uvm_blocking_put_imp_r  #(TrAxi, AxiSlvScb) imp_r  = new("imp_r", this);

    uvm_blocking_transport_port #(TrAxi, TrAxi) transport_port = new("transport_port", this);

    TrAxi tr_q_ar[$];
    semaphore key = new(1);

    function new(string name = "AxiSlvScb", uvm_component parent);
        super.new(name, parent);
    endfunction

    virtual function void check_outstanding();
        if (tr_q_ar.size() > `AXI_OUTSTANDING) begin
            string str = $sformatf("Out of Outstanding(%0d) :\n", `AXI_OUTSTANDING);
            str = {str,  $sformatf("    AR Channel: %0d", tr_q_ar.size())};
            `uvm_fatal(get_type_name(), str);
        end
    endfunction

    virtual task put_ar(TrAxi tr_ar);
        key.get();
        `uvm_info(get_type_name(), "Chn AR Put", UVM_DEBUG)

        tr_q_ar.push_back(tr_ar);

        this.check_outstanding();
        key.put();
    endtask

    virtual task put_r(TrAxi tr_r);
        TrAxi tr_rd = TrAxi::type_id::create("tr_rd");
        int catch_queue_index = -1;

        key.get();

        `uvm_info(get_type_name(), "Chn R Put", UVM_DEBUG)

        if (tr_r.resp != 0) `uvm_fatal(get_type_name(), "R Resp Error")
        if (tr_q_ar.size() == 0) `uvm_fatal(get_type_name(), "Chn-AR-Queue is Empty when Chn-R Happen")

        foreach (tr_q_ar[i]) begin
            if (tr_q_ar[i].id == tr_r.id) begin
                catch_queue_index = i;
                break;
            end
        end

        // Chn R 必须在 Chn AR 之后
        if (catch_queue_index == -1) begin
            string str = $sformatf("R Channel Order Error\n tr_r.id = 0x%0h\n", tr_r.id);
            str = {str,  $sformatf("  There are %0d AR-Transaction(s) in the Queue:\n", tr_q_ar.size())};
            foreach (tr_q_ar[i]) str = {str, $sformatf("    %s\n", tr_q_ar[i].get_addr_info())};

            `uvm_warning("CRITICAL", str)
            #100ns;
            `uvm_fatal(get_type_name(), "Fatal Error")
        end

        // 与 Ref 交互并做比较
        tr_rd.clone_addr_from(tr_q_ar[catch_queue_index]);
        tr_rd.clone_data_from(tr_r);
        tr_q_ar.delete(catch_queue_index);

        check_data_queue_with_ref(tr_rd);

        // this.check_outstanding();         //! 不用 check_outstanding, 因为 Chn R 只会删队列而不会加队列
        key.put();
    endtask

    task check_data_queue_with_ref(TrAxi tr_scb);
        TrAxi tr_ref = TrAxi::type_id::create("tr_ref");
        int pass_flag = 1;

        tr_scb.align_calcu();

        `uvm_info(get_type_name(), "\n**** Scoreboard TrAxi from Chn AR+R: ****", UVM_MEDIUM)
        $write(tr_scb.get_info());

        transport_port.transport(tr_scb, tr_ref);

        if (tr_scb.data.size() != tr_ref.data.size()) begin
            `uvm_warning("CRITICAL", "Data Size Mismatch")
            pass_flag = 0;
        end
        else begin
            for (int i = 0; i < tr_scb.data.size(); i++) begin
                if (tr_scb.data[i] !== tr_ref.data[i]) begin
                    `uvm_warning("CRITICAL", $sformatf("Data Mismatch at Index %0d", i))
                    pass_flag = 0;
                    break;
                end
            end
        end

        if (pass_flag == 0) begin
            `uvm_warning("CRITICAL", "\n**** Check Data Queue with Ref Failed ****")
            $display(tr_ref.get_info());

            `uvm_fatal(get_type_name(), "Data Mismatch")
        end

        $display("**** Check Passed ****\n");

    endtask

endclass
