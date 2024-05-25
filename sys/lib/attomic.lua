local attomic = {}
function attomic.sync()
    local master = coroutine.running()
    local hold = 1
    return function(i)
        local t = coroutine.running()
        if master == t then
            hold = i
            coroutine.yield()
        else
            while hold <= i do
                coroutine.yield()
            end
        end
    end
end

function attomic.Msync()
    local master = coroutine.running()
    local hold = 1
    local sync = {}
    function sync.sync(i)
        local t = coroutine.running()
        if master == t then
            hold = i
            coroutine.yield()
        else
            while hold <= i do
                coroutine.yield()
            end
        end
    end
    function sync.take()
        master = coroutine.running()
    end
    return sync
end

function attomic.semaphore()
    local owner = coroutine.running()
    local lock = false
    local sem = {}
    function sem.lock()
        local t = coroutine.running()
        while lock and (owner ~= t) do
            coroutine.yield()
        end
        owner = t
        lock = true
    end

    function sem.holds()
        local t = coroutine.running()
        return lock and (owner == t)
    end

    function sem.wait()
        local t = coroutine.running()
        while lock and (owner ~= t) do
            coroutine.yield()
        end
    end

    function sem.unlock()
        local t = coroutine.running()
        if (owner == t) then
            lock = false
        end
    end

    return sem
end

function attomic.attom(v)
    local val = v
    local I = 1
    local sem = attomic.semaphore()
    local sync = attomic.Msync()
    local attom = {}
    local coVals = {}

    function attom.take()
        sem.lock()
        sync.take()
        local t = coroutine.running()
        coVals[t] = I
    end

    function attom.set(v)
        if sem.holds() then
            local t = coroutine.running()
            I = I + 1
            coVals[t] = I
            val = v
            sync.sync(I)
            
        end
    end

    function attom.get()
        local t = coroutine.running()
        sync.sync(coVals[t] or 1)
        coVals[t] = I+1
        return val
    end
    function attom.release()
        sem.unlock()
    end
    return attom
end

return attomic
