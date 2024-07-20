class AxiMstrChnR extends uvm_driver #(TrAxi);

    /* Factory Register this Class */
    `uvm_component_utils(AxiMstrChnR)

    /* Declare Normal Variables */

    /* Declare Object Handles */
    virtual IfAxi vifAxi;
    // uvm_blocking_put_port #(TrAxi) put_port = new("put_port", this);

    function new(string name = "AxiMstrChnR", uvm_component parent);
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
        {vifAxi.rready} = '{default:0};
        phase.drop_objection(this);
    endtask

    virtual task run_phase(uvm_phase phase);
        wait(vifAxi.aresetn);
        repeat (10) @(vifAxi.m_cb);

        forever begin
            r_channel();
        end

    endtask

    // 使用组合逻辑, 实现 max performance
    virtual task r_channel(input int pre_delay = 0);
         // 因为允许乱序, 用 tr.len 不一定准确, 用 last 信号来控制通断
        forever begin
            int value;

            wait(vifAxi.rvalid == 1);

            // 不一定每一拍都能及时握手
            void'( std::randomize(value) with { value dist {0:/7, [1:3]:/1}; } );
            repeat (value) begin
                vifAxi.m_cb.wvalid <= 0;
                @(vifAxi.m_cb);
            end

            #1 vifAxi.rready = 1;

            if (vifAxi.rlast) begin
                @(vifAxi.aclk);
                #2;
                if (vifAxi.rvalid != 1) vifAxi.rready = 0;
                break;
            end
        end
    endtask

    /*
    virtual task r_channel(input int pre_delay = 0);
        TrAxi tr = TrAxi::type_id::create("tr");
        int break_flag = 0;

        repeat (pre_delay) @(vifAxi.m_cb);

        // 因为允许乱序, 用 tr.len 不一定准确, 用 last 信号来控制通断
        forever begin
            // int value;

            while (!vifAxi.m_cb.rvalid) @(vifAxi.m_cb);

            // 不一定每一拍都能及时握手
            // void'( std::randomize(value) with { value dist {0:/7, [1:3]:/1}; } );
            // repeat (value) begin
            //     vifAxi.m_cb.wvalid <= 0;
            //     @(vifAxi.m_cb);
            // end

            vifAxi.m_cb.rready <= 1;
            @(vifAxi.m_cb);
            vifAxi.m_cb.rready <= 0;

            tr.id   = vifAxi.m_cb.rid;
            tr.resp = vifAxi.m_cb.rresp;
            tr.data.push_back(vifAxi.m_cb.rdata);

            if (vifAxi.m_cb.rlast) begin
                put_port.put(tr);
                break_flag = 1;
                @(vifAxi.m_cb);
            end

            if (break_flag) break;
        end
    endtask
    */

endclass
