# Alveare Compiler 

The ALVEARE compiler translates a RE into th target ALVEARE binary code. The front end is based on *FLEX* and *BISON* tools.

## Usage
1. ```make``` for compiling the binary of the REs compiler (called compiler by default)
2. ```./compiler``` for the interactive mode in which it is possible to type a regex and then press ```enter``` to see how it is compiled and which are the used intermediated representation structures), ```CTRL+D``` to terminate
3. EXAMPLE: ```./compiler -i <input file> -o <output file>``` inputting a file and result saved there. Remember that each new line is a new regex.
4. ```make clean``` to clean all the generated files from the compilation of the compiler. 

## Paramters
- -o <output_file>: sets the name of the output file for the output ALVEARE binary code. The default output file is stdout.
- -i <input_file>: sets the name of the input file for the RE. The default input file is stdin.
- -m <exponent>: sets the number of instructions required in the binary output. The number is 2^<exponent> and represents the size of the memory instruction. It is used to create
a ready-to-use executable binary code. The default <exponent>
is 6.
- -f: fills the remaining instructions upon reaching the specified number of instructions with *EOR* (End-of-RE) instructions. This operation indicates to the core that the RE reached the end. At least one *EOR* must be present at the end of the translated REs; otherwise, the processor behavior is undefined. **By default, this option is disabled.**
- -w <cluster_width>: sets the maximum number of *CHARs* in the reference for each single base operation. This value is the vectorization degree that sets how many characters can be
compared in a single clock cycle. The default value is 4.
- -l <number_of_bits>: sets the instruction reference
length. It also implies the length alignment for the opcode *.* The default value is 32.

## Files Specification
- *compiler.lex*: it contains the lexical analyzer based on *FLEX* which translate the input RE into a stream of *tokens*
- *compiler.y*: it implements grammar checking for the tokenized RE. It is based on *BISON*.
- *ast.c* and *ast.h*: it contains all the functions used to compile and optimize an RE into the target binary code from the *Abstract-Syntax tree* to generate the binary code.