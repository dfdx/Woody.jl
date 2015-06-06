
abstract Memorizer

type RedisMemorizer <: Memorizer
    conn::RedisConnection
    buffers::Dict{String, Vector{String}}
    bufpos::Dict{String, Int}
    bufsize::Int
end

function Base.show(io::IO, mem::RedisMemorizer)
    print(io, "RedisMemorizer($(mem.conn.host):$(mem.conn.port)," *
          "$(length(mem.buffers)) keys)")
end

function RedisMemorizer(;redis_host::String="localhost", redis_port::Int=6379,
                        bufsize::Int=1000)
    conn = RedisConnection(host=redis_host, port=redis_port)
    return RedisMemorizer(conn, Dict(), Dict(), bufsize)
end


const DUMP_BUFFER_MESSAGE = "~~dump-buffer~~"


function dump!(mem::Memorizer, key::String)
    pos = mem.bufpos[key]
    data = join(mem.buffers[key][1:pos-1], "\n")
    if !isempty(data)
        Redis.lpush(mem.conn, key, data)
    end
end

function push!(mem::Memorizer, key::String, message::String)
    if !haskey(mem.buffers, key)
        # TODO: expire buffer for this key after some time too
        mem.buffers[key] = Array(String, mem.bufsize)
        mem.bufpos[key] = 1
    end
    if message == DUMP_BUFFER_MESSAGE
        # special message
        dump!(mem, key)
        mem.bufpos[key] = 1
    else
        pos = mem.bufpos[key]
        mem.buffers[key][pos] = message
        mem.bufpos[key] += 1
        if mem.bufpos[key] > mem.bufsize
            dump!(mem, key)
            mem.bufpos[key] = 1
        end
    end
end



function memorizer_test()
    mem = RedisMemorizer(bufsize=5)
    key = "qwe"
    push!(mem, key, "good morning")
    push!(mem, key, "bonjour")
    push!(mem, key, "labas rytas")
    push!(mem, key, DUMP_BUFFER_MESSAGE)
    push!(mem, key, "dobre rano")
    push!(mem, key, "hello")
    push!(mem, key, "bonjour")
    push!(mem, key, "laba diena")
    push!(mem, key, "dobry den")    
end


