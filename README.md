# topleaked
This is a tool for searching memory leaks in core dumps. If you have a memory dump of a process that used too much memory you will want to use topleaked. It lookes for most frequent 8 bytes words in dump and write top N of them. Usually top contains pointers to vtbl of leaked objects in case of C++ or pointers to functions in case of C. Inspired by [this question](https://stackoverflow.com/questions/27598986/how-to-analyze-memory-leak-from-coredump) and answers to it.

# It is
* A simple tool that looks for most frequent things
* 64-bit Little-Endian (e.g. x86_64) dumps compatible (other platforms support is in progress)

# It is NOT
* Yet another valgrind. It does not work with process itself, it is only for dump analisys. If you can reproduce your memory leak use a memory sanitizer.
* Language or platform specific. It does not parse dump (e.g. using libelf). It just read a file byte by byte and build a frequency top.

# Installation
First you need a D compiler. topleaked is written in D language and you can get compiler from [official site](https://dlang.org). LDC is recommended as it is best in optimization.
There are two options: install from dub registry or clone from github and build.

## Get using dub
```
dub fetch topleaked
```
This command will download sources to local dub registry. To use it run
```
dub run -brelease-nobounds topleaked -- <arguments>
```
This command will compile sources if needed and run. Arguments to topleaked shoul be passed after --

## Clonning from github
Just clone this repository and switch to it in terminal and run
```
dub build -brelease-nobounds
```
It will compile and put executable in same directory. You can copy this executable to any folder or add to PATH. It does not have any dependencies and can be moved.

# Usage
If you installed package from dub then your command to execute is
```
dub run topleaked -brelease-nobounds -- <filename> [<options>...]
```
In other cases you have the executable file and can do the same with
```
topleaked <filename> [<options>...]
```

Options are
```
-n         --size how many items from top should be printed
-o       --output use 'gdb' for passing output to gdb stdin, 'human' [default] for human readable output
-s       --offset start from position s, use it to offset gcore
-l        --limit max number of 8byte words to read
-t         --time print processing time
-f         --find find pattern
   --memberOffset offset of member starting from found valur passed by -f
     --memberType size of member starting from found valur passed by -f, may be uint8, uint16, uint32, uint64
-h         --help This help information.```

To process hex from output into classes or functions from your code pass output to gdb
```
topleaked myapp.core -o gdb | gdb myapp myapp.core
```

## Looking for most recent values of most recent types
After usual launch of topleaked you have information about types of leaked objects (usually because of vtbl ptr). If it is not enough you can look for most frequent values of member of found classes. To do so pass ptr from top to -f, offset of member (relative to found ptr, ussually it is vtbl so you can pass just offsetof) to --memberOffset and type (actually size) of member tp --memberSize.
For example:
```
struct Base {
    virtual void foo() = 0;
};

struct Der : Base {
    size_t a = 15;
    void foo() override {

    }
};
int main()
{
    for (size_t i = 0; i < 10000; ++i) {
        new Der;
    }
    auto d = new Der;
    cout << offsetof(Der, a) << endl;
    abort();
    return 0;
}
```
This program prints offset of Det::a which is 8. Make core and analize it with topleaked:
```
topleaked  my_core.core
0x0000000000000000 : 50124
0x000000000000000f : 10005
0x0000000000000021 : 10004
0x000055697c45cd78 : 10002
0x0000000000000002 : 195
0x0000000000000001 : 182
0x00007fe9cbd6c000 : 167
0x0000000000000008 : 161
0x00007fe9cbd5e438 : 154
0x0000000000001000 : 112

```
0x000055697c45cd78 is vtbl ptr of Der. No we can find values of Der::a with
```
topleaked my_.core -f0x55697c45cd78 --memberOffset=8 --memberType=uint64
```
Result:
```
0x000000000000000f : 10001
0x000055697ccaa080 : 1
```


# Known issues
Do not use 'gcore' for getting core dump on Linux. There are some format or alignment issues and results can not be interpreted as valid symbols. Try --offset 4 or some other to solve this problem. Or use SIGABRT (kill -SIGABRT <pid>) for dumping memory.

# To Do
* 32-bit systems support
* other endians support
