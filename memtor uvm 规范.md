# notebook

1. 在 package 里定义 class, 其它 package 需要的话, 采用 import 的方式导入类. 不要使用 include 的方式将同一个 class 放到多个 package 里
2. 除了 name 和 parent 之外, 不要在构造函数 `new()` 里添加额外的参数. 在最坏的情况下, 构造函数的额外参数将导致 UVM Factory 无法创建所请求的对象. 即使额外参数具有允许工厂运行的默认值, 额外参数也将始终是默认值, 因为 factory 仅传递 name 和 parent 参数
3. 使用 UVM Factory 注册并创建所有类. 使用 UVM Factory 注册所有类并创建所有对象可最大限度地提高 UVM 测试平台的灵活性. 向 UVM Factory 注册类不会带来运行时损失, 并且通过 UVM Factory 创建对象只会产生轻微的开销. UVM 定义的类在 factory 中注册, 并且从这些类创建的对象应使用 UVM factory 创建, 这包括 uvm_sequencer 等类
4. 使用 UVM Factory 创建对象, 并将对象的句柄名称与传递到 create() 调用中的字符串名称相匹配. UVM 构建一个对象层次结构, 用于许多不同的功能, 包括 UVM Factory 覆盖和配置. 此层次结构基于传递到每个构造函数的第一个参数的字符串名称. 保持句柄名称和字符串层次结构名称相同将极大地有助于调试
5. 使用 `uvm_object_utils()`、`uvm_object_param_utils()`、`uvm_component_utils()` 和 `uvm_component_param_utils()` 这些工厂注册宏. 顾名思义, 这些宏向 UVM 工厂注册 UVM object 或 component, 这是必要且关键的. 当这些宏展开时, 它们提供了 `type_id typedef` (这是工厂注册)、静态 `get_type()` 函数 (返回对象类型)、 `get_object_type()` 函数 (不是静态的, 也返回对象类型)和 `create()` 函数
6. 使用UVM消息宏 `uvm_info()`、`uvm_warning()`、`uvm_error()`和`uvm_fatal()`. UVM 消息宏在使用时可节省性能. 这些宏带来的作用是检查在执行昂贵的字符串处理之前是否会过滤消息. 它们还在输出消息时将文件和行号添加到消息中
7. 编写自己的 `do_clone()`、`do_copy()`、`do_print()`、`do_sprint`、`do_compare`、`do_record`、`do_pack()` 和 `do_unpack()` 函数. 不要使用 field automation 宏. 从表面上看, field automation 宏看起来像是一种处理类中数据成员的非常快速且简单的方法. 然而, field automation 宏有一个非常大的隐藏成本. 因此, Mentor不使用也不建议使用这些宏. 这些宏包括`uvm_field_int()`、`uvm_field_object()`、`uvm_field_array_int()`、`uvm_field_queue_string()`等. 当这些宏展开时, 会导致数百行代码. 生成的代码不是人类编写的代码, 因此即使扩展也很难调试
8. 尽量使用 `sequence.start(sequencer)` 来启动sequence. 由于 `start()` 是一个task, 它将阻塞直到 sequence 完成执行, 因此您可以通过将 `sequence.start(sequencer)` 命令串在一起来控制 TB 中发生的事情的顺序. 如果两个或多个 sequences 需要并行运行, 则可以使用 SystemVerilog 的 `fork/join(_any, _none)` 等. 在父 sequence 中启动子 sequence 时, 也可以使用 `sequence.start(sequencer)`
9. 使用 factory 创建 sequence_item, 且使用 `start_item()` 和 `finish_item()` 发送它们, 不要使用 UVM sequence宏 (`uvm_do` 等). 要在 sequence 中使用 sequence_item, Mentor 建议使用 factory 来创建 sequence_item, 使用 `start_item()` 任务与 sequencer 进行仲裁, 使用 `finish_item()` 任务将随机化/准备好的 sequence_item 发送到 sequencer 的 driver 上
10. 不要使用 sequence 中定义的 `pre_body()` 和 `post_body()` 任务. 根据 sequence 的调用方式, 这些 task 可能会也可能不会被调用. 相反, 将本应进入 `pre_body()` 任务的功能放入 `body()` 任务的开头或 `pre_start()`里. 同样, 将本来进入 `post_body()` 任务的功能放入 `body()` 任务的末尾或 `post_start()` 里
11. sequence 不应显式消耗时间语句, 比如 `#10ns`, 具有显式延迟会减少重用
12. uvm_driver 和 uvm_monitor 是测试平台执行者, 应该只实现 `run_phase()`, 它们不应该实施任何其他耗时的 phase. uvm_driver 处理从 sequence 发送给它的任何事务, 并且 uvm_monitor 捕获在任何时间上它在总线上观察到的事务
13. 使用 uvm_config_db API 传递配置信息. 不要使用 `set/get_config_object()`、`set/get_config_string()` 或 `set/get_config_int()`, 因为它们已被弃用. 也不要使用 uvm_resource_db API
14. 使用 uvm_config_db API 将虚拟interface句柄从顶层测试测试module传递到测试平台对应的组件
15. 创建配置类来保存配置值, 为了给 test/env/agent 提供配置信息, 应创建一个配置类, 其中包含所需的位、字符串、整数、枚举、虚拟接口句柄等. 每个组件都应该有自己的配置类, 其中包含组件任何部分使用的每条配置信息
16. 不要将配置空间 (config_db) 用于组件之间的频繁通信, 使用资源数据库进行组件之间的频繁通信很浪费时间. 不频繁的通信 (例如提供寄存器模型的句柄) 是可以接受的
17. 将 covergroup 放置在从 uvm_object 扩展的包装类中. Covergroup 不是对象或类. 它们不能被扩展, 也不能以编程方式自行创建和销毁. 但是, 如果 covergroup 包装在类中, 则测试平台可以在运行时决定是否构建 covergroup 的包装类
18. 仅在 uvm_test 中 raise 和 drop uvm_objection. 在大多数情况下, 仅应在 test 中耗时的阶段之一 raise 和 drop uvm_objection. 这是因为 test 是测试平台中将要发生的事情的主要控制器, 因此它知道所有激励何时被创建和处理. 如果 components 需要更多时间, 可以使用 phase_ready_to_end() 函数以留出更多时间. 因为raise和drop一个uvm_objection会产生开销, 所Mentor建议不要在 monitor 或 driver 的 run_phase 中 raise 和 drop uvm_objection, 因为这会由于所涉及的开销而导致仿真速度减慢 (*其他 uvm_component 似乎还是得每个 task 自己 raise 和 drop uvm_objection*)
19. 不要使用 callback. UVM 提供了一种为特定对象注册 callback 的机制. 不使 callback 机制是因为注册和启用 callback 需要许多复杂的步骤. 此外, 除了潜在的排序问题之外, callback 还具有不可忽略的内存和性能占用. 相反, 在需要 callback 功能的地方, 可以使用标准的面向对象编程 (OOP) 来替换. 方法一: 扩展要更改的类, 然后使用 UVM factory 的 override 覆盖创建的对象. 方法二: 在父对象中创建一个子对象, 该子对象将一些功能委托给它. 为了控制使用哪个功能, 可以使用配置设置或者可以使用 factory 覆盖
20. 不要在用户定义的 plusargs 前添加 "uvm_" 或 "UVM_" 前缀, 防止和 UVM 内置的参数重名
