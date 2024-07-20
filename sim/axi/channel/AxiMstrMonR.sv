class AxiMstrMonR extends uvm_driver #(TrAxi);

    /* Factory Register this Class */
    `uvm_component_utils(AxiMstrMonR)

    /* Declare Normal Variables */

    /* Declare Object Handles */
    virtual IfAxi vifAxi;
    uvm_blocking_put_port #(TrAxi) put_port = new("put_port", this);

    function new(string name = "AxiMstrMonR", uvm_component parent);
        super.new(name, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        /* uvm_config_db#(<type>)::get(<uvm_component>, <"inst_name">, <"field_name">, <value>); */
        if (!uvm_config_db#(virtual IfAxi)::get(this, "", "vifAxi", vifAxi))
            `uvm_fatal("NOVIF", "No IfAxi Interface Specified")
        /* uvm_config_db#(<type>)::set(<uvm_component>, <"inst_name">, <"field_name">, <value>); */
    endfunction

    virtual task run_phase(uvm_phase phase);
        TrAxi tr_q[$];      // "读交织" 的暂存队列

        wait(vifAxi.awready);
        #100ns;
        @(vifAxi.mon_cb);

        forever begin
            if (vifAxi.mon_cb.rvalid && vifAxi.mon_cb.rready) begin
                int catch_queue_index = -1;

                if (vifAxi.mon_cb.rresp != 0) `zpf_fatal("RRESP NOT OK");

                foreach (tr_q[i]) begin
                    if (tr_q[i].id == vifAxi.mon_cb.rid) begin
                        catch_queue_index = i;
                        break;
                    end
                end

                if (catch_queue_index == -1) begin
                    TrAxi tr = TrAxi::type_id::create("tr");
                    tr.id = vifAxi.mon_cb.rid;
                    tr_q.push_back(tr);
                    catch_queue_index = tr_q.size() - 1;
                end

                tr_q[catch_queue_index].data.push_back(vifAxi.mon_cb.rdata);

                if (vifAxi.mon_cb.rlast) begin
                    put_port.put(tr_q[catch_queue_index]);
                    tr_q.delete(catch_queue_index);
                end
            end

            @(vifAxi.mon_cb);
        end
    endtask

endclass
