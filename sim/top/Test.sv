class Test extends uvm_test;

    /* Factory Register this Class */
    `uvm_component_utils(Test)

    /* Declare Normal Variables */

    /* Declare Object Handles */
    AxiMstrSeqWr axiMstrSeqWr = AxiMstrSeqWr::type_id::create("axiMstrSeqWr");
    AxiMstrSeqRd axiMstrSeqRd = AxiMstrSeqRd::type_id::create("axiMstrSeqRd");

    virtual IfAxi vifAxi;
    Env env = Env::type_id::create("env", this);

    function new(string name = "Test", uvm_component parent);
        super.new(name, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        uvm_top.set_timeout(50us, 0);

        /* Override */
        /* uvm_config_db#(<type>)::get(<uvm_component>, <"inst_name">, <"field_name">, <value>); */
        if (!uvm_config_db#(virtual IfAxi)::get(this, "", "vifAxi", vifAxi)) `uvm_fatal("NOVIF", "No IfAxi Interface Specified")
        /* uvm_config_db#(<type>)::set(<uvm_component>, <"inst_name">, <"field_name">, <value>); */
    endfunction

    virtual function void start_of_simulation_phase(uvm_phase phase);
        `uvm_info(get_type_name(), "start_of_simulation_phase: print_topology", UVM_MEDIUM)
        uvm_top.print_topology();
        `uvm_info(get_type_name(), "report_phase: print_factory", UVM_MEDIUM)
        factory.print();
    endfunction

    virtual task run_phase(uvm_phase phase);
        phase.raise_objection(this);

        this.run_testcase();
        this.read_all_stored_data();

        vifAxi.peek_mem();
        env.axiMstrEnv.axiSlvRef.peek_mem();

        phase.drop_objection(this);
    endtask

    extern virtual function TrAxi create_tr_cache_line_wr(bit [`AXI_ADDR_WIDTH-1:0] ADDR);
    extern virtual function TrAxi create_tr_cache_line_rd(bit [`AXI_ADDR_WIDTH-1:0] ADDR);
    extern virtual function TrAxi create_tr_noncache_wr(bit [`AXI_ADDR_WIDTH-1:0] ADDR, int NC_WIDTH);
    extern virtual function TrAxi create_tr_noncache_rd(bit [`AXI_ADDR_WIDTH-1:0] ADDR);

    extern virtual task run_testcase();
    extern virtual task read_all_stored_data();

endclass

// 整行的 cache 进行写 (cache line size = 128 bits * 4)
// 其 addr 总是对齐且不会越界的 ('h40 的倍数); 如果 addr 不对齐, 则会报一个警告
// 其 wstrb 总是全 1
function TrAxi Test::create_tr_cache_line_wr(bit [`AXI_ADDR_WIDTH-1:0] ADDR);
    TrAxi tr = TrAxi::type_id::create("tr");
    bit [`AXI_ADDR_WIDTH-1:0] ADDR_ALIGN = ADDR / 'h40 * 'h40;

    if (ADDR != ADDR_ALIGN)
        `uvm_warning(get_type_name(), $sformatf("ADDR(0x%0h) -> ADDR_ALIGN(0x%0h)", ADDR, ADDR_ALIGN))

    tr.wr_flag = 1;
    `zpf_randomize_with(tr, {addr == ADDR_ALIGN; len == 3; size == 4; burst == 1;})
    for (int i = 0; i <= 3; i++) tr.wstrb[i] = '1;

    return tr;
endfunction

// 整行的 cache 进行读 (cache line size = 128 bits * 4)
// 其 addr 总是对齐且不会越界的 ('h40 的倍数); 如果 addr 不对齐, 则会报一个警告
// 没有 wstrb 的概念
function TrAxi Test::create_tr_cache_line_rd(bit [`AXI_ADDR_WIDTH-1:0] ADDR);
    TrAxi tr = TrAxi::type_id::create("tr");
    bit [`AXI_ADDR_WIDTH-1:0] ADDR_ALIGN = ADDR / 'h40 * 'h40;

    if (ADDR != ADDR_ALIGN)
        `uvm_warning(get_type_name(), $sformatf("ADDR(0x%0h) -> ADDR_ALIGN(0x%0h)", ADDR, ADDR_ALIGN))

    tr.wr_flag = 0;
    `zpf_randomize_with(tr, {addr == ADDR_ALIGN; len == 3; size == 4; burst == 1;})

    return tr;
endfunction

// 非 cache 地址进行写入, 区分 stb, sth, stw, stl 四种情况, 使用 wstrb 来区分
// 其 addr 总是对齐且不会越界的 ('h10 的倍数);
// NC_WIDTH 的取值: 1 -> stb, 2 -> sth, 4 -> stw, 8 -> stl (单位: byte)
function TrAxi Test::create_tr_noncache_wr(bit [`AXI_ADDR_WIDTH-1:0] ADDR, int NC_WIDTH);
    TrAxi tr = TrAxi::type_id::create("tr");
    bit [`AXI_ADDR_WIDTH-1:0] ADDR_ALIGN = ADDR / 'h10 * 'h10;
    bit [3:0] start_bit_offset = $urandom_range(0, 15) / NC_WIDTH * NC_WIDTH;

    if (ADDR != ADDR_ALIGN)
        `uvm_warning(get_type_name(), $sformatf("ADDR(0x%0h) -> ADDR_ALIGN(0x%0h)", ADDR, ADDR_ALIGN))

    if (NC_WIDTH != 1 && NC_WIDTH != 2 && NC_WIDTH != 4 && NC_WIDTH != 8)
        `uvm_fatal(get_type_name(), $sformatf("INVALID NC_WIDTH(0x%0h)", NC_WIDTH))

    tr.wr_flag = 1;
    `zpf_randomize_with(tr, {addr == ADDR_ALIGN; len == 0; size == 4; burst == 1;})
    tr.wstrb[0] = '0;
    for (int i = start_bit_offset; i <= start_bit_offset + NC_WIDTH - 1; i++)
        tr.wstrb[0][i] = 1'b1;

    return tr;
endfunction

// 非 cache 地址进行读取, 一次必定读出一个 transfer 的数据
// 其 addr 总是对齐且不会越界的 ('h10 的倍数); 如果 addr 不对齐, 则会报一个警告
// 没有 wstrb 的概念
function TrAxi Test::create_tr_noncache_rd(bit [`AXI_ADDR_WIDTH-1:0] ADDR);
    TrAxi tr = TrAxi::type_id::create("tr");
    bit [`AXI_ADDR_WIDTH-1:0] ADDR_ALIGN = ADDR / 'h10 * 'h10;

    if (ADDR != ADDR_ALIGN)
        `uvm_warning(get_type_name(), $sformatf("ADDR(0x%0h) -> ADDR_ALIGN(0x%0h)", ADDR, ADDR_ALIGN))
    
    tr.wr_flag = 0;
    `zpf_randomize_with(tr, {addr == ADDR_ALIGN; len == 0; size == 4; burst == 1;})

    return tr;
endfunction


task Test::run_testcase();
    @(vifAxi.m_cb);

    begin
    `ifdef TESTCASE_0
        bit [`AXI_ADDR_WIDTH-1:0] cache_addr_q [$];
        bit [`AXI_ADDR_WIDTH-1:0] noncache_addr_q [$];

        // 生成 N 个随机的 cache 地址池 (对齐的) (可重复)
        repeat (50) begin
            bit [`AXI_ADDR_WIDTH-1:0] addr_tmp;
            void'(std::randomize(addr_tmp) with { addr_tmp % 'h40 == 0; });
            cache_addr_q.push_back(addr_tmp);
        end

        // 根据 cache 地址生成 4*N 个随机的 noncache 地址池 (覆盖到 cache 地址的所有 transfer) (可重复)
        foreach (cache_addr_q[i]) begin
            noncache_addr_q.push_back(cache_addr_q[i] + 'h00);
            noncache_addr_q.push_back(cache_addr_q[i] + 'h10);
            noncache_addr_q.push_back(cache_addr_q[i] + 'h20);
            noncache_addr_q.push_back(cache_addr_q[i] + 'h30);
        end

        $display("FILL ALL CACHE ADDR POOL START");
        // 预先用 cache 淘汰把 cache 池子里的数据填满
        foreach (cache_addr_q[i]) begin
            repeat (10) @(vifAxi.m_cb);
            axiMstrSeqWr.tr.clone_from(create_tr_cache_line_wr(cache_addr_q[i]));
            axiMstrSeqWr.start(env.axiMstrEnv.axiMstrVirSqrWr);
        end
        #500ns @(vifAxi.m_cb);
        $display("FILL ALL CACHE ADDR POOL END");

        // 进行 N 次 cache 加载/淘汰, 每次的地址都随机地从 cache_addr_q[$] 中抽出
        repeat (200) begin
            case ($urandom_range(0, 3))
                0: begin
                    $display("写入 cache 地址");
                    axiMstrSeqWr.tr.clone_from(create_tr_cache_line_wr(cache_addr_q[$urandom_range(0, cache_addr_q.size()-1)]));
                    axiMstrSeqWr.start(env.axiMstrEnv.axiMstrVirSqrWr);
                end
                1: begin
                    $display("读取 cache 地址");
                    axiMstrSeqRd.tr.clone_from(create_tr_cache_line_rd(cache_addr_q[$urandom_range(0, cache_addr_q.size()-1)]));
                    axiMstrSeqRd.start(env.axiMstrEnv.axiMstrAgtRd.axiMstrSqrAr);
                end
                2: begin
                    int NC_WIDTH = 1 << $urandom_range(0, 3);
                    $display("noncache 写入");
                    axiMstrSeqWr.tr.clone_from(create_tr_noncache_wr(noncache_addr_q[$urandom_range(0, noncache_addr_q.size()-1)], NC_WIDTH));
                    axiMstrSeqWr.start(env.axiMstrEnv.axiMstrVirSqrWr);
                end
                3: begin
                    $display("noncache 读取");
                    axiMstrSeqRd.tr.clone_from(create_tr_noncache_rd(noncache_addr_q[$urandom_range(0, noncache_addr_q.size()-1)]));
                    axiMstrSeqRd.start(env.axiMstrEnv.axiMstrAgtRd.axiMstrSqrAr);
                end
                default: `uvm_fatal("TESTCASE", "INVALID RANDOM RANGE")
            endcase
            repeat (10) @(vifAxi.m_cb);        // 用一个 delay 保证跳过 outstanding 的情况
        end

    `elsif TESTCASE_1
    `else
        `uvm_fatal("TESTCASE", "NOT TESTCASE DEFINED")
    `endif
    end

    for (int i = 0; i <= 3; i++) #100ns $display("[%0d] @%0t run_testcase extra delay ...", i, $time());
endtask

task Test::read_all_stored_data();
    bit [`AXI_ADDR_WIDTH-1:0] axi_addr_q [$];

    @(vifAxi.m_cb);

    foreach (env.axiMstrEnv.axiSlvRef.mem[i]) begin
        axi_addr_q.push_back(i * (128 / 8));
    end

    foreach (axi_addr_q[i]) begin
        `zpf_randomize_with(axiMstrSeqRd.tr, {
            addr == axi_addr_q[i];
            len == 0;
            size == 4;
            burst == 1;
        })
        axiMstrSeqRd.start(env.axiMstrEnv.axiMstrAgtRd.axiMstrSqrAr);
    end

    for (int i = 0; i <= 3; i++) #100ns $display("[%0d] @%0t read_all_stored_data extra delay ...", i, $time());

endtask
