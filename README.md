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
dub -brelease-nobounds run topleaked -- <arguments>
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
-n   --size how many items from top should be printed
-o --output use 'gdb' for passing output to gdb stdin, 'human' [default] for human readable output
-s --offset start from position s, use it to offset gcore
-l  --limit max number of 8byte words to read
-t   --time print processing time
-f   --find find pattern
-a --around szie of context of find
-h   --help This help information.
```

To process hex from output into classes or functions from your code pass output to gdb
```
topleaked myapp.core -o gdb | gdb myapp myapp.core
```

# Known issues
Do not use 'gcore' for getting core dump on Linux. There are some format or alignment issues and results can not be interpreted as valid symbols. Try --offset 4 or some other to solve this problem. Or use SIGABRT (kill -SIGABRT <pid>) for dumping memory.

# To Do
* 32-bit systems support
* other endians support
