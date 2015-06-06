
type Collector
    ctx::Context
    sock::Socket
    mem::Memorizer
    coll_port::Int
    redis_port::Int
end


function Collector(coll_port, redis_port)
    ctx = Context()
    sock = Socket(ctx, PULL)
    bind(sock, "tcp://*:$coll_port")
    mem = RedisMemorizer(redis_port=redis_port)
    return Collector(ctx, sock, mem, coll_port, redis_port)
end


function process_message(c, msg)
    # TODO
end

function run_collector_loop(c)
    try
        while true
            msg = bytestring(recv(c.sock))
            process_message(c, msg)
        end
    finally
        close(ctx)
    end
end


function start_collector()
    coll_port = Base.get(ENV, "COLLECTOR_PORT", 5588)
    redis_port = Base.get(ENV, "REDIS_PORT", 6379)
    c = Collector(coll_port, redis_port)
    colltask = @async run_collector_loop(c)
    return colltask

end
