# Alveare-compiler

Support: POSIX Extended syntax + the lazy operator (currently only counters) from PCRE

usage:
1. ```make``` for compiling the binary of the compiler (automatically called compiler)
2. ```./compiler``` for the interactive mode (i.e., you can type a regex than press enter to see if it compiles or not), ```CTRL+D``` to terminate
3. ```./compiler -i <input file> -o <output file>``` inputting a file and result saved there. Remember that each new line is a new regex
