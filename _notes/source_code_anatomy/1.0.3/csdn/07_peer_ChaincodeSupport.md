<!-- https://blog.csdn.net/idsuf698987/article/details/76050728 -->

- FSM 将一个事物从状态 A 向状态 B 的转化看作一个事件，并可以设置在进入/离开某个状态时自动调用的时机函数。
	
    ```go
    // https://github.com/looplab/fsm
    // https://godoc.org/github.com/looplab/fsm#FSM
    fsm := NewFSM(
        "green",
        Events{
            {Name: "warn", Src: []string{"green"}, Dst: "yellow"},
            {Name: "panic", Src: []string{"yellow"}, Dst: "red"},
            {Name: "panic", Src: []string{"green"}, Dst: "red"},
            {Name: "calm", Src: []string{"red"}, Dst: "yellow"},
            {Name: "clear", Src: []string{"yellow"}, Dst: "green"},
        },
        Callbacks{
            "before_warn": func(e *Event) {
                fmt.Println("before_warn")
            },
            "before_event": func(e *Event) {
                fmt.Println("before_event")
            },
            "leave_green": func(e *Event) {
                fmt.Println("leave_green")
            },
            "leave_state": func(e *Event) {
                fmt.Println("leave_state")
            },
            "enter_yellow": func(e *Event) {
                fmt.Println("enter_yellow")
            },
            // 
            "enter_state": func(e *Event) {
                fmt.Println("enter_state")
            },
            "after_warn": func(e *Event) {
                fmt.Println("after_warn")
            },
            "after_event": func(e *Event) {
                fmt.Println("after_event")
            },
        },
    )
    fmt.Println(fsm.Current())
    err := fsm.Event("warn")
    if err != nil {
        fmt.Println(err)
    }
    fmt.Println(fsm.Current())
    // green
    // before_warn
    // before_event
    // leave_green
    // leave_state
    // enter_yellow
    // enter_state
    // after_warn
    // after_event
    // yellow
    ```

- Callbacks are added as a map specified as Callbacks where the key is parsed as the callback event as follows, and called in the same order:
    1. before_<EVENT> - called before event named <EVENT>
    2. before_event - called before all events
    3. leave_<OLD_STATE> - called before leaving <OLD_STATE>
    4. leave_state - called before leaving all states
    5. enter_<NEW_STATE> - called after entering <NEW_STATE>
    6. enter_state - called after entering all states
    7. after_<EVENT> - called after event named <EVENT>
    8. after_event - called after all events