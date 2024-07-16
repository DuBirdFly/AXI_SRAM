`uvm_blocking_put_imp_decl(_aw)
`uvm_blocking_put_imp_decl(_w)
`uvm_blocking_put_imp_decl(_b)

class AxiSlvRef extends uvm_component;

    /* Factory Register this Class */
    `uvm_component_utils(AxiSlvRef)

    /* Declare Normal Variables */
    localparam MEM_ADDR_WIDTH = `AXI_ADDR_WIDTH - $clog2(`AXI_WSTRB_WIDTH);
    logic [`AXI_DATA_WIDTH - 1:0] mem [bit[MEM_ADDR_WIDTH - 1:0]];

    /* Declare Object Handles */
    uvm_blocking_put_imp_aw #(TrAxi, AxiSlvRef) imp_aw = new("imp_aw", this);
    uvm_blocking_put_imp_w  #(TrAxi, AxiSlvRef) imp_w  = new("imp_w", this);
    uvm_blocking_put_imp_b  #(TrAxi, AxiSlvRef) imp_b  = new("imp_b", this);

    uvm_blocking_transport_imp #(TrAxi, TrAxi, AxiSlvRef) transport_imp = new("transport_imp", this);

    TrAxi tr_q_aw[$], tr_q_w[$], tr_q_wr[$];
    semaphore key = new(1);

    function new(string name = "AxiSlvRef", uvm_component parent);
        super.new(name, parent);
    endfunction

    virtual function void check_outstanding();
        if (tr_q_aw.size() + tr_q_wr.size() > `AXI_OUTSTANDING ||
            tr_q_w.size()  + tr_q_wr.size() > `AXI_OUTSTANDING
        ) begin
            string str = $sformatf("Out of Outstanding(%0d) :\n", `AXI_OUTSTANDING);
            str = {str,  $sformatf("    AW Channel: %0d\n", tr_q_aw.size())};
            str = {str,  $sformatf("    W  Channel: %0d\n", tr_q_w.size())};
            str = {str,  $sformatf("    WR   Agent: %0d", tr_q_wr.size())};
            `uvm_fatal(get_type_name(), str);
        end
    endfunction

    virtual task put_aw(TrAxi tr_aw);
        key.get();
        `uvm_info(get_type_name(), "Chn AW Put", UVM_DEBUG)

        case (tr_q_w.size())
            0: tr_q_aw.push_back(tr_aw);
            default: begin
                // if (tr_aw.len + 1 != tr_q_w(0).data.size())
                //     `uvm_fatal(get_type_name(), "AW LEN Size Error")

                tr_aw.clone_data_from(tr_q_w.pop_front());
                tr_q_wr.push_back(tr_aw);
            end
        endcase

        this.check_outstanding();
        key.put();
    endtask

    virtual task put_w(TrAxi tr_w);
        key.get();
        `uvm_info(get_type_name(), "Chn W Put", UVM_DEBUG)

        case (tr_q_aw.size())
            0: tr_q_w.push_back(tr_w);
            default: begin
                TrAxi tr_q_aw_1st = tr_q_aw.pop_front();
                if (tr_w.data.size() != tr_q_aw_1st.len + 1)
                    `uvm_fatal(get_type_name(), "W Data[$].Size Error")

                tr_w.clone_data_from(tr_q_aw_1st);
                tr_q_wr.push_back(tr_w);
            end
        endcase

        this.check_outstanding();
        key.put();
    endtask

    virtual task put_b(TrAxi tr_b);
        int check_chn_order = 0;        // Chn B 必须在 Chn AW+W 之后

        key.get();
        `uvm_info(get_type_name(), "Chn B Put", UVM_DEBUG)

        if (tr_b.resp != 0) `uvm_fatal(get_type_name(), "B Resp Error")

        foreach (tr_q_wr[i]) begin
            if (tr_q_wr[i].id == tr_b.id) begin
                `uvm_info(get_type_name(), "\n**** Reference Model TrAxi from Chn AW+W+B: ****", UVM_MEDIUM)
                $display(tr_q_wr[i].get_info());

                write_mem(tr_q_wr[i]);
                tr_q_wr.delete(i);
                check_chn_order = 1;

                break;
            end
        end

        // Chn B 必须在 Chn AW+W 之后
        if (check_chn_order == 0) begin
            string str = $sformatf("B Channel Order Error: tr_b.id = 0x%0h\n", tr_b.id);
            str = {str, "  There are %0d WR-Transaction(s) in the Queue:\n", tr_q_wr.size()};
            foreach (tr_q_wr[i]) str = {str, "    ", tr_q_wr[i].get_addr_info(), "\n"};
            `uvm_fatal(get_type_name(), str);
        end

        this.check_outstanding();
        key.put();
    endtask

    virtual function void write_mem(TrAxi tr);
        foreach (tr.data[i]) begin
            bit [`AXI_DATA_WIDTH - 1:0]  data_tmp  = tr.data[i];
            bit [`AXI_WSTRB_WIDTH - 1:0] wstrb_tmp = tr.align_wstrb[i];
            for (int j = 0; j < `AXI_WSTRB_WIDTH; j++)
                if (wstrb_tmp[j]) mem[tr.mem_addr[i]][j * 8 +: 8] = data_tmp[j * 8 +: 8];
        end
    endfunction

    task transport(input TrAxi req_scb, output TrAxi rsp);
        rsp = TrAxi::type_id::create("rsp");
        rsp.clone_addr_from(req_scb);
        rsp.align_calcu();

        for (int i = 0; i < rsp.mem_addr.size(); i++) begin
            if (mem.exists(rsp.mem_addr[i]))
                rsp.data.push_back(mem[rsp.mem_addr[i]]);
            else
                rsp.data.push_back('bx);
        end

    endtask

    function void peek_mem();
        $display("\n============================= PEEK SLV REF MEM =============================");
        foreach (mem[i]) $display("mem[0x%0h] axi[0x%0h] %h", i, i * `AXI_WSTRB_WIDTH, mem[i]);
        $display("==========================================================================\n");
    endfunction

endclass
