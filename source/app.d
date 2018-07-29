import std.stdio;
import std.range;
import std.algorithm;
import std.getopt;
import std.bitmanip;
import std.datetime.stopwatch;
import core.stdc.stdint;

enum Format {human, gdb}

string usage = "Usage:\n    topleaked <filename> [<options>...]";

void main(string[] args) {
    size_t size = 10;
    Format format = Format.human;
    bool time = false;
    try {
        auto opts = getopt(
            args,
            "size|n", "how many items from top should be printed", &size,
            "output|o", "use 'gdb' for passing output to gdb stdin, 'human' [default] for human readable output", &format, 
            "time|t", "print processing time", &time,
        );
		if (opts.helpWanted) {
			defaultGetoptPrinter("Some information about the program.", opts.options);
			return;
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
    
    readFile(name).findMostFrequent(size).printResult(format);
    
    sw.stop();
    if (time) writeln("Done in ", sw.peek);
}

auto readFile(string name) {
    auto f = File(name);
    ubyte[8] buf;
    return f.byChunk(buf[]).map!read64.array;
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

auto findMostFrequent(Range)(Range input, size_t maxSize = 10) if (isRandomAccessRange!Range && is(ElementType!Range == uint64_t)) {
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
