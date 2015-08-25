
using Requests
using URIParser
using Gadfly

geturl(line) = strip(split(line, ",")[4], '\"')

function getallurls(filename)
    lines = split(readall(filename), "\n")[2:end-1]
    urls = Array(String, length(lines))
    for i=1:length(lines)
        urls[i] = "http://" * geturl(lines[i])
    end
    return urls
end


function resolvehost(url)
    h = URI(url).host
    ip = string(Base.getaddrinfo(h))
    replace(url, h, ip)
end

function resolvehosts(urls)
    result = String[]
    @sync for url in urls
        @async try
            resolved = resolvehost(strip(url))
            push!(result, resolved)
        catch
            println("Can't resolve $url")
        end
    end
    return result
end

function get_stream(url::String)
    Requests.open_stream(URI(url), Dict(), "", "GET")
end


function fetch_urls(urls; timeout=Inf)
    statuses = -ones(length(urls))
    times = -ones(length(urls))
    @sync for i=1:length(urls)
        @async begin
            try
                t = @elapsed resp = get(urls[i]; timeout=timeout)
                statuses[i] = resp.status
                times[i] = t
                println("OK")
            catch
                println("Error")
            end
        end
    end
    return (statuses, times)
end


function main()

    # @time urls = resolvehosts(open(readlines, expanduser("../domains.txt"))[1:5000])
    @time urls = [strip(l) for l in open(readlines, expanduser("../ips.txt"))]

    @time (statuses, times) = fetch_urls(urls[1:100])

    plot(x=[i for i=1:length(times)], y=times)
    
end
