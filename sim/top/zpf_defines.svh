// 随机化 sequence 或是 sequence_item (tranaction)
`define zpf_randomize_with(SEQ_OR_ITEM, CONSTRAINTS) \
    if(!SEQ_OR_ITEM.randomize() with CONSTRAINTS) `uvm_fatal("ZPF_RANDOMIZE", "RANDOMIZE FAILED")

// 1. full copy from: uvm-1.1d/src/macros/uvm_sequence_defines.svh -- "`uvm_do_on_pri_with"
// 2. 这与`uvm_do_pri_with相同, 只是它还将父序列设置为调用宏的序列, 并将顺序器设置为指定的~SEQR~参数
//    也就是指定了 `uvm_create_on 宏, 注意, `uvm_create_on 会导致原先 SEQ_OR_ITEM 指向的对象空间被释放
`define zpf_do_on_pri_with(SEQ_OR_ITEM, SEQR, PRIORITY, CONSTRAINTS) \
    begin \
        uvm_sequence_base __seq; \
        `uvm_create_on(SEQ_OR_ITEM, SEQR) \
        if (!$cast(__seq,SEQ_OR_ITEM)) start_item(SEQ_OR_ITEM, PRIORITY); \
        if ((__seq == null || !__seq.do_not_randomize) && !SEQ_OR_ITEM.randomize() with CONSTRAINTS ) begin \
            `uvm_warning("RNDFLD", "Randomization failed in uvm_do_with action") \
        end \
        if (!$cast(__seq,SEQ_OR_ITEM)) finish_item(SEQ_OR_ITEM, PRIORITY); \
        else __seq.start(SEQR, this, PRIORITY, 0); \
    end

// 1. 将 uvm_do_on_pri_with 宏拆分成上半部分和下半部分, 并删除了中间部分的 randomize
// 2. 此举是为了手动实现(或不实现) randomize 功能, 或是希望能在随机化后手动控制 SEQ_OR_ITEM 的行为
`define zpf_do_on_pri_begin(SEQ_OR_ITEM, SEQR, PRIORITY) \
    begin \
        uvm_sequence_base __seq; \
        `uvm_create_on(SEQ_OR_ITEM, SEQR) \
        if (!$cast(__seq,SEQ_OR_ITEM)) start_item(SEQ_OR_ITEM, PRIORITY);

`define zpf_do_on_pri_end(SEQ_OR_ITEM, SEQR, PRIORITY) \
        if (!$cast(__seq,SEQ_OR_ITEM)) finish_item(SEQ_OR_ITEM, PRIORITY); \
            else __seq.start(SEQR, this, PRIORITY, 0); \
    end

// 1. 因为 *_do_on_pri_with 宏有以下两个缺陷
//    1.1. 执行的第一步会调用 `uvm_create_on 宏, 这会导致原先 SEQ_OR_ITEM 指向的对象空间被释放
//    1.2. SEQ_OR_ITEM 必被 randomize, 无法手动控制
// 2. 所以需要手动控制 SEQ_OR_ITEM 的行为
//    2.1. 使用自定义的 SEQ_OR_ITEM.clone_from(Obj, **) 方法修改对象空间的内容
//    2.2. 上一条为什么不用 "= obj.clone" ? 因为这样会导致 SEQ_OR_ITEM 指向新的对象空间, 从而挂载到 sqr 失败
`define zpf_do_on_pri_clone(SRC_SEQ_OR_ITEM, DST_SEQ_OR_ITEM, SEQR, PRIORITY) \
    `zpf_do_on_pri_begin(DST_SEQ_OR_ITEM, SEQR, PRIORITY) \
        DST_SEQ_OR_ITEM.clone_from(SRC_SEQ_OR_ITEM); \
    `zpf_do_on_pri_end(DST_SEQ_OR_ITEM, SEQR, PRIORITY)

`define zpf_do_on_clone(SRC_SEQ_OR_ITEM, DST_SEQ_OR_ITEM, SEQR) \
    `zpf_do_on_pri_clone(SRC_SEQ_OR_ITEM, DST_SEQ_OR_ITEM, SEQR, -1)

// 添加了 zpf_info/warning/error/fatal 的私有宏
`define zpf_info_pri(MSG, PRI) `uvm_info(get_type_name(), MSG, PRI)
`define zpf_info(MSG)          `zpf_info_pri(MSG, UVM_MEDIUM)

`define zpf_warning_pri(MSG, PRI) `uvm_warning(get_type_name(), MSG, PRI)
`define zpf_warning(MSG)          `zpf_warning_pri(MSG, UVM_MEDIUM)

`define zpf_error_pri(MSG, PRI) `uvm_error(get_type_name(), MSG, PRI)
`define zpf_error(MSG)          `zpf_error_pri(MSG, UVM_MEDIUM)

`define zpf_fatal_pri(MSG, PRI) `uvm_fatal(get_type_name(), MSG, PRI)
`define zpf_fatal(MSG)          `zpf_fatal_pri(MSG, UVM_MEDIUM)