

function parse_command(cmd::String)
    particles = split(cmd)
    op = particles[1]
    args::Array{String} = particles[2:end]
    op, args
end

function process_command(c::Collector, cmd::String)
    op, args = parse_command(cmd)
    if op == "status"
        
    end
end

function process_message(c::Collector, msg)    
    println(msg)
end


function init_collector(port)
    ctx = Context()
    sock = Socket(ctx, PULL)
    bind(sock, "tcp://*:$port")
    try
        while true
            msg = bytestring(recv(sock))
            process_message(c, msg)
        end
    finally
        close(ctx)
    end
end



function start_collector(port1, port2)
    colltask = @async run_collector_loop(port2)
    run_control_loop(colltask, port1)
end


# 2 separate sockets: one for pulling messages,
#  another (REQ-REP) for interactive commands?

# commands:
#   status
#   dump <token>
