# Tomasolu Simulator
 A customizable Tomasolu simulator built with Flutter
 
 Visit https://singularity-s0.github.io/tomasolu-simulator/ for a live version of this simulator.
 
  Currently supported instructions:
 - Load:    L.D
 - Add      ADD.D
 - Subtract SUB.D
 - Multiply MUL.D
 - Divide   DIV.D

Instruction File Format:

instructions.txt
```assembly
L.D F6,34(R2)
L.D F2,45(R3)
MUL.D F0,F2,F4
SUB.D F8,F2,F6
DIV.D F10,F0,F6
ADD.D F6,F8,F2
```
