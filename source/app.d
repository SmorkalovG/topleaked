import std.stdio;
import std.range;
import std.algorithm;
import std.getopt;
import std.bitmanip;
import std.datetime.stopwatch;
import core.stdc.stdint;
import std.conv;

enum Format {human, gdb}

enum MemberType {uint8, uint16, uint32, uint64}

string usage = "Usage:\n    topleaked <filename> [<options>...]";

void main(string[] args) {
    size_t size = 10;
    Format format = Format.human;
    bool time = false;
    size_t offset;
    size_t limit = size_t.max;
    string patternStr;
    uint64_t pattern;
    size_t memberOffset;
    MemberType memberType;
    try {
        auto opts = getopt(
            args,
            "size|n", "how many items from top should be printed", &size,
            "output|o", "use 'gdb' for passing output to gdb stdin, 'human' [default] for human readable output", &format, 
            "offset|s", "start from position s, use it to offset gcore", &offset,
            "limit|l", "max number of 8byte words to read", &limit,
            "time|t", "print processing time", &time,
            "find|f", "find pattern", &patternStr,
            "memberOffset", "offset of member starting from found valur passed by -f", &memberOffset,
            "memberType", "size of member starting from found valur passed by -f, may be uint8, uint16, uint32, uint64", &memberType,
        );
        if (opts.helpWanted) {
            defaultGetoptPrinter("Some information about the program.", opts.options);
            return;
        }
        if (!patternStr.empty) {
            if (patternStr.startsWith("0x")) {
                patternStr = patternStr[2..$];
            }
            pattern = parse!uint64_t(patternStr, 16);
        }
    } catch (Exception e) {
        stderr.writeln(e.msg);
        return;
    }
    
    if (args.length != 2) {
        stderr.writeln("No input file");
        stderr.writeln(usage);
        return;
    }
    
    string name = args[1];

    auto sw = StopWatch(AutoStart.no);
    sw.start();
    if (patternStr) {
        final switch(memberType) {
        case MemberType.uint8:  readFile(name, offset, limit).findMember!uint8_t(pattern, memberOffset).findMostFrequent(size).printResult(format);  break;
        case MemberType.uint16: readFile(name, offset, limit).findMember!uint16_t(pattern, memberOffset).findMostFrequent(size).printResult(format); break;
        case MemberType.uint32: readFile(name, offset, limit).findMember!uint32_t(pattern, memberOffset).findMostFrequent(size).printResult(format); break;
        case MemberType.uint64: readFile(name, offset, limit).findMember!uint64_t(pattern, memberOffset).findMostFrequent(size).printResult(format); break;
        }

    } else {
        readFile(name, offset, limit).findMostFrequent(size).printResult(format);
    }
    
    sw.stop();
    if (time) writeln("Done in ", sw.peek);
}

auto findMember(Result)(uint64_t[] range, uint64_t pattern, size_t offset) {
    Result[] result;
    foreach (i, v; range) {
        if (v == pattern) {
            byte* ptr = cast(byte*) &range[i];
            ptr += offset;
            if (ptr > cast(byte*) &range[$-1]) {
                break;
            }
            result ~= *cast(Result*)ptr;
        }
    }
    return result;
} 

auto readFile(string name, size_t offset, size_t limit) {
    auto f = File(name);
    f.seek(offset);
    ubyte[8] buf;
    return f.byChunk(buf[]).map!read64.take(limit).array;
}

void printResult(Range)(Range range, Format format) if (isInputRange!Range && is(ElementType!Range == ValCount)) {
    final switch(format) {
    case Format.gdb:
        foreach (vc; range) {
            writefln("p %d", vc.count);
            writefln("x 0x%016x", vc.val);
            writefln("info symbol 0x%016x", vc.val);
        }
        break;
    case Format.human:
        foreach (vc; range) {
            writefln("0x%016x : %d", vc.val, vc.count);
        }
        
    }

}

struct ValCount {
    uint64_t val;
    size_t count;
}

uint64_t read64(ubyte[] src) {
    if (src.length < 8) {
        return 0;
    }
    return std.bitmanip.read!(uint64_t, std.system.Endian.littleEndian)(src);
}

auto findMostFrequent(Range)(Range input, size_t maxSize = 10) if (isRandomAccessRange!Range) {
    auto all = input.sort;
    ValCount[] res = new ValCount[min(all.length, maxSize)];
    return all.group.map!((p) => ValCount(p[0],p[1])).topNCopy!"a.count>b.count"(res, Yes.sortOutput);
}


unittest {
    uint64_t[] empty;
    assert(empty.findMostFrequent == []);
    writeln([1UL,1UL,2UL].findMostFrequent);
    assert([1UL,1UL,2UL].findMostFrequent == [ValCount(1,2), ValCount(2,1)]);
    assert([1UL,1UL,2UL,2UL].findMostFrequent.sort!"a.val<b.val".array == [ValCount(1,2), ValCount(2,2)]);
}
