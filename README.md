# ALVEARE
ALVEARE: A Domain-Specific Framework for Regular Expressions

This repository contains the source code of the paper "ALVEARE: A Domain-Specific Framework for Regular Expressions," where we proposed an HW/SW framework for the efficient execution of Regular Expressions (REs). This work exploits the idea of using RE as a programming language using a domain-specific compiler to translate and optimize the REs into binary code. 
The binary code must respect the rules specified by the RE-tailored RISC Instruction Set Architecture. Finally, the binary code is executed into the RE-optimized domain-specific architecture. On top of its components, this framework can guarantee low latency and energy efficiency execution of REs while providing flexibility thanks to the compilation flow.

# Repository Overview
- [Compiler](https://github.com/necst/alveare/blob/main/src/sw/compiler/README.md)
- Architecture
- [Credits and Contributors](#credits)

# Supported Operators
| Operator | Description | 
|:----------:|:-------------:|
| [abc] | character class |
| [^abc] | negated character class |
| [a-z]  | character class range |
| \w, \d, \s, \h | short end character classes |
| . | DOT, any char. except \n |
| ?,{n},{n,m} | bounded quantifier |
| *,+,{n,} | unbounded quantifier |
| ??,{n,m}?,{n}? | bounded lazy quantifiers |
| *?, +?,{n,}? | unbounded lazy quantifiers |
| \ | escaping character |

# RISC RE-tailored Instruction Set Architecture
| Class | Operator | Opcode | Description |
|:----------:|:-------------:|:----------:|:-------------:|
| Control | EoR | 0000000  | End of RE|
| Base | AND | 0010--- | Char-based And|
| Base | OR | 0001--- | Char-based Or |
| Base | RANGE | 0011--- | Char-based Range |
| Base | NOT | 01----- | Match Inversion |
| Complex | ( | 1000000 | New Sub-RE |
| Complex | ) | 0---100 | End of Sub-RE |
| Complex | QUANT LAZY | 0---001 | ) + Lazy Quantifier |
| Complex | QUANT | 0---010 | ) + Greedy Quantifier |
| Complex | )| 0---011 | ) + OR of Sub-RE |



# Credits and Contributors <a name="credits"></a> 

Contributors: Filippo Carloni, Davide Conficconi, Marco Domenico Santambrogio

If you find this repository useful, please use the following citation(s):

```
@inproceedings{carloni2024alveare,
  title={ALVEARE: a Domain-Specific Framework for Regular Expressions},
  author={Carloni, Filippo and Conficconi, Davide and Santambrogio, Marco D},
  booktitle={Proceedings of the 61st ACM/IEEE Design Automation Conference},
  year={2024}
}

```
