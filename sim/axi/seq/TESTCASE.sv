`ifdef TESTCASE_0
    `zpf_randomize_with(axiMstrSeqWr.tr, {
        addr[15] == 1'b1;
        addr[14:2] == '0;
        addr[1:0] == 2'b11;
        len == 3;
        size == 5;
        burst == 1;
    })
    for (int i = 0; i <= 3; i++) axiMstrSeqWr.tr.wstrb[i] = '1;
    axiMstrSeqWr.start(env.axiMstrEnv.axiMstrVirSqrWr);
`else
    `uvm_fatal("TESTCASE", "NOT TESTCASE DEFINED")
`endif