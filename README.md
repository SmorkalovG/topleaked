# topleaked
This is a tool for searching memory leaks in core dumps. If you have a memory dump of a process that used too much memory you will want to use topleaked. It lookes for most frequent 8 bytes words in dump and write top N of them. Ussually top contains pointers to vtbl of leaked objects in case of C++ or pointers to functions in case of C. Inspired by [this question](https://stackoverflow.com/questions/27598986/how-to-analyze-memory-leak-from-coredump) and answers to it.

# It is
* A simple tool that looks for most frequent things
* 64-bit Little-Endian (x86_64 e.g) dumps compatible (other platforms support is in progress)

# It is NOT
* Yet another valgrind. It does not work with process it self, it is only for dump analisys. If you can reproduce your memoty leak use a memory sanitizer.
* Language or platform specific. It does not parse dump (using libelf e.g). It just read a file byte by byte and build a frequency top.

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
If you installed package from dub then your commands to execute is
```
dub -brelease-nobounds run topleaked -- <filename> [<options>...]
```
In other cases you have the file and do the same with
```
topleaked <filename> [<options>...]
```

Options are
```
-n   --size how many items from top should be printed
-o --output use 'gdb' for passing output to gdb, 'human' [default] for human readable output
-t   --time print processing time
```

To process hex from output into classes or functions from your code pass output to gdb
```
topleaked myapp.core -o gdb | gdb myapp myapp.core
```


# To Do
* 32-bit systems support
* other endians support