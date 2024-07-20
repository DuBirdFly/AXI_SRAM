class TrAxi extends uvm_sequence_item;

    /* Declare Normal Variables */
    bit                             wr_flag = 0;
    bit     [`AXI_WSTRB_WIDTH-1:0]  align_mask[$];
    bit     [`AXI_WSTRB_WIDTH-1:0]  align_wstrb[$];
    bit     [`AXI_ADDR_WIDTH-1:0]   axi_addr[$];
    int                             mem_addr[$];

    /* Declare AXI Variables */
    rand bit   [`AXI_ID_WIDTH-1:0]    id;
    rand bit   [`AXI_ADDR_WIDTH-1:0]  addr;
    rand bit   [`AXI_LEN_WIDTH-1:0]   len;
    rand bit   [`AXI_SIZE_WIDTH-1:0]  size;
    rand bit   [`AXI_BURST_WIDTH-1:0] burst;
    rand logic [`AXI_DATA_WIDTH-1:0]  data[$];
    rand bit   [`AXI_WSTRB_WIDTH-1:0] wstrb[$];
         bit   [`AXI_RESP_WIDTH-1:0]  resp;

    /* Factory/Object Registration */
    `uvm_object_utils_begin(TrAxi)
        `uvm_field_int(wr_flag, UVM_ALL_ON | UVM_BIN)
        `uvm_field_queue_int(align_mask, UVM_ALL_ON | UVM_BIN)
        `uvm_field_queue_int(align_wstrb, UVM_ALL_ON | UVM_BIN)
        `uvm_field_queue_int(axi_addr, UVM_ALL_ON)
        `uvm_field_queue_int(mem_addr, UVM_ALL_ON)
        `uvm_field_int(id, UVM_ALL_ON)
        `uvm_field_int(addr, UVM_ALL_ON)
        `uvm_field_int(len, UVM_ALL_ON)
        `uvm_field_int(size, UVM_ALL_ON)
        `uvm_field_int(burst, UVM_ALL_ON)
        `uvm_field_queue_int(data, UVM_ALL_ON)
        `uvm_field_queue_int(wstrb, UVM_ALL_ON | UVM_BIN)
        `uvm_field_int(resp, UVM_ALL_ON)
    `uvm_object_utils_end

    /* Declare Object Handles */

    /* Constrains */

    constraint c_addr {
        // 不能越 axi 最大地址
        addr <= 2 ** `AXI_ADDR_WIDTH - `AXI_WSTRB_WIDTH * (len + 1);
        solve burst, len, size before addr;
    }

    constraint c_fixed_addr {
        // 不能越上界
        (burst == 0) -> (addr / `AXI_BURST_BOUNDAEY + 1) * `AXI_BURST_BOUNDAEY >= addr + (2 ** size);
        solve burst, len, size before addr;
    }

    constraint c_incr_addr {
        // 不能越上界
        (burst == 1) -> (addr / `AXI_BURST_BOUNDAEY + 1) * `AXI_BURST_BOUNDAEY >= addr + (len + 1) * (2 ** size);
        solve burst, len, size before addr;
    }

    constraint c_wrap_addr {
        // wrap 突发必须对齐
        (burst == 2) -> addr % (2 ** size) == 0;
        // 不能越上界+下界, align_calcu() 会处理非对齐情况 (用的偏心环回)
        solve size before addr;
    }

    constraint c_len {
        burst == 0 -> len < 16;
        burst == 1 -> len < 256;
        burst == 2 -> len inside {1, 3, 7, 15};
        solve burst before len;
    }

    constraint c_size {
        size inside {[0: `AXI_SIZE_MAX]};
    }

    constraint c_burst {
        burst inside {[0:2]};
    }

    constraint c_data {
        wr_flag == 0 -> data.size() == 0;
        wr_flag == 1 -> data.size() == len + 1;
        solve len before data;
    }

    constraint c_strb {
        wr_flag == 0 -> wstrb.size() == 0;
        wr_flag == 1 -> wstrb.size() == len + 1;
        solve len before wstrb;
    }

    function new(string name = "TrAxi");
        super.new(name);
    endfunction

    virtual function void clone_addr_from(TrAxi rhs);
        this.id      = rhs.id;
        this.addr    = rhs.addr;
        this.len     = rhs.len;
        this.size    = rhs.size;
        this.burst   = rhs.burst;
    endfunction

    virtual function void clone_data_from(TrAxi rhs);
        this.align_mask  = rhs.align_mask;
        this.align_wstrb = rhs.align_wstrb;
        this.axi_addr    = rhs.axi_addr;
        this.mem_addr    = rhs.mem_addr;
        this.data        = rhs.data;
        this.wstrb       = rhs.wstrb;
    endfunction

    virtual function void clone_from(TrAxi rhs);
        wr_flag = rhs.wr_flag;
        resp    = rhs.resp;
        clone_addr_from(rhs);
        clone_data_from(rhs);
    endfunction

    //! 只取决于这些 addr 等参数: 根据 burst, addr, len, size 生成 align_mask[$], align_wstrb[$], mem_addr[s]
    virtual function void align_calcu();
        //初始化队列
        align_mask.delete();
        align_wstrb.delete();
        axi_addr.delete();
        mem_addr.delete();

        repeat(len+1) align_wstrb.push_back('0);
        repeat(len+1) align_mask.push_back('0);
        repeat(len+1) mem_addr.push_back('0);
        repeat(len+1) axi_addr.push_back('0);

        // FIXED突发只用处理第一个数据的情况, 其他的复制即可
        if (burst == 0) begin
            bit [`AXI_ADDR_WIDTH-1:0]  align_start_addr = addr / (2 ** size) * (2 ** size);
            bit [`AXI_WSTRB_WIDTH-1:0] align_mask_1st;
            int                        mem_addr_1st;

            for (int j = 0; j < 2 ** size; j++) begin
                bit [`AXI_WSTRB_WIDTH-1:0] tmp = align_start_addr % `AXI_WSTRB_WIDTH + j;
                align_mask_1st[tmp]= 1'b1;
            end

            //修改align_mask为可能的非对齐情况
            for (int j = 0; j < addr % `AXI_WSTRB_WIDTH; j++)
                align_mask_1st[j] = 1'b0;

            mem_addr_1st = align_start_addr / `AXI_WSTRB_WIDTH;

            for (int i = 0; i <= len; i++) axi_addr[i] = align_start_addr;
            for (int i = 0; i <= len; i++) align_mask[i] = align_mask_1st;
            for (int i = 0; i <= len; i++) align_wstrb[i] = wstrb[i] & align_mask[i];
            for (int i = 0; i <= len; i++) mem_addr[i] = mem_addr_1st;
        end

        // INCR 突发
        if (burst == 1) begin
            bit [`AXI_ADDR_WIDTH - 1:0] align_start_addr = addr / (2 ** size) * (2 ** size);

            for (int i = 0; i <= len; i++) axi_addr[i] = align_start_addr + i * (2 ** size);

            for (int i = 0;i <= len; i++) begin
                for (int j = 0; j < 2 ** size; j++) begin
                    bit [`AXI_WSTRB_WIDTH-1:0] tmp = axi_addr[i] % `AXI_WSTRB_WIDTH + j;
                    align_mask[i][tmp]= 1'b1;
                end
            end

            // 修改第一个align_mask为可能的非对齐情况
            for (int j = 0; j < addr % `AXI_WSTRB_WIDTH; j++) align_mask[0][j] = 1'b0;
            for (int i = 0; i <= len; i++) align_wstrb[i] = wstrb[i] & align_mask[i];
            for (int i = 0; i <= len; i++) mem_addr[i] = axi_addr[i] / `AXI_WSTRB_WIDTH;

        end

        // 起始地址不是 wrap 中心的回环突发形式
        if (burst == 2) begin
            bit [`AXI_ADDR_WIDTH-1:0] addr_tmp = addr;
            bit [`AXI_ADDR_WIDTH-1:0] wrap_addr_space = (2 ** size) * (len + 1);
            bit [`AXI_ADDR_WIDTH-1:0] wrap_addr_start = addr / wrap_addr_space * wrap_addr_space;
            bit [`AXI_ADDR_WIDTH-1:0] wrap_addr_end   = wrap_addr_start + (2 ** size) * len;

            if (addr % (2 ** size) != 0) `zpf_fatal("WRAP Burst must be aligned");
            if (len != 1 && len != 3 && len != 7 && len != 15) `zpf_fatal("WRAP Burst len must be 1, 3, 7, 15");

            for (int i = 0; i <= len; i++) begin
                axi_addr[i] = addr_tmp;
                if (addr_tmp == wrap_addr_end) addr_tmp = wrap_addr_start;
                else addr_tmp += (2 ** size);
            end

            for (int i = 0;i <= len; i++) begin
                for (int j = 0; j < 2 ** size; j++) begin
                    bit [`AXI_WSTRB_WIDTH-1:0] tmp = axi_addr[i] % `AXI_WSTRB_WIDTH + j;
                    align_mask[i][tmp] =1'b1;
                end
            end

            for (int i = 0; i <= len; i++) align_wstrb[i] = wstrb[i] & align_mask[i];
            for (int i = 0; i <= len; i++) mem_addr[i] = axi_addr[i] / `AXI_WSTRB_WIDTH;
        end

        // 起始地址为 wrap 中心的回环突发形式
        // WRAP突发有两个起始地址，一个是突发起始地址 align_start_addr（假设是对齐的），一个是突发回环地址 warp_addr
        // len={1,3,7,15} -> wrap_index ={1,2,4,8}
        // if (burst == 2) begin
        //     int wrap_index = (len + 1) / 2;
        //     bit [`AXI_ADDR_WIDTH-1:0] align_start_addr = addr / (2 ** size) * (2 ** size);
        //     bit [`AXI_ADDR_WIDTH-1:0] wrap_addr = addr - wrap_index * (2 ** size);

        //     for (int i = 0; i < wrap_index; i++) begin
        //         axi_addr[i] = align_start_addr + i * (2 ** size);
        //         axi_addr[wrap_index + i] = wrap_addr + i * (2 ** size);
        //     end

        //     for (int i = 0;i <= len; i++) begin
        //         for (int j = 0; j < 2 ** size; j++) begin
        //             bit [`AXI_WSTRB_WIDTH-1:0] tmp = axi_addr[i] % `AXI_WSTRB_WIDTH + j;
        //             align_mask[i][tmp] =1'b1;
        //         end
        //     end

        //     for (int i = 0; i <= len; i++) align_wstrb[i] = wstrb[i] & align_mask[i];
        //     for (int i = 0; i <= len; i++) mem_addr[i] = axi_addr[i] / `AXI_WSTRB_WIDTH;
        // end
    endfunction

    //! 不自带尾行回车
    virtual function string get_addr_info();
        string str = $sformatf(
            "id = %0d(0x%0h), addr = %0d(0x%0h), len = %0d(+1), size = %0d(%0d byte/tansfer), burst = %d (wr_flag == %0d)",
            id, id, addr, addr, len, size, 2**size, burst, wr_flag
        );
        return str;
    endfunction

    //! 自带尾行回车
    virtual function string get_data_info();
        string str;

        // Write Channel
        if (wr_flag == 1) begin
            foreach (data[i]) begin
                str = {str, $sformatf(
                    "[%0d] mem[0x%0h] axi[0x%0h] %h, %b & %b = %b\n",
                    i, mem_addr[i], mem_addr[i] * `AXI_WSTRB_WIDTH, data[i], wstrb[i], align_mask[i], align_wstrb[i]
                )};
            end
        end
        if (wr_flag == 1) begin
            if (data.size() == 0) `uvm_warning("CRITICAL", "Wr Channel but no data[$] inside");
            if (wstrb.size() == 0) `uvm_warning("CRITICAL", "Wr Channel but no wstrb[$] inside");
        end
        // Read Channel
        if (wr_flag == 0) begin
            foreach (data[i]) begin
                str = {str, $sformatf(
                    "[%0d] mem[0x%0h] axi[0x%0h] %h, %b\n",
                    i, mem_addr[i], mem_addr[i] * `AXI_WSTRB_WIDTH, data[i], align_mask[i]
                )};
            end
        end
        return str;
    endfunction

    //! 自带尾行回车
    virtual function string get_info();
        string str;
        str = {str, get_addr_info(), "\n"};
        str = {str, get_data_info()};
        return str;
    endfunction

endclass
