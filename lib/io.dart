import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:tomasolu/devices.dart';

List<Instruction> parseInstruction(String instr) {
  List<Instruction> instructions = [];
  try {
    final instrTexts = instr.split('\n');
    for (var instrText in instrTexts) {
      instrText = instrText.trim();
      if (instrText.isEmpty) continue;
      final opcodePart = instrText.indexOf(' ');
      var opcode;
      switch (instrText.substring(0, opcodePart)) {
        case 'L.D':
          opcode = Opcode.LOAD;
          break;
        /*case 'S.D':
          opcode = Opcode.STORE;
          break;*/
        case 'MUL.D':
          opcode = Opcode.MUL;
          break;
        case 'DIV.D':
          opcode = Opcode.DIV;
          break;
        case 'ADD.D':
          opcode = Opcode.ADD;
          break;
        case 'SUB.D':
          opcode = Opcode.SUB;
          break;
        default:
          throw Exception(
              'Unknown opcode: ${instrText.substring(0, opcodePart)}');
      }
      final instrData = instrText.substring(opcodePart).trim().split(',');
      if (opcode == Opcode.LOAD) {
        // Load and store instructions are a bit different
        RegExp addrParser = RegExp(r'([0-9]+)\((R[0-9]+)\)');
        final addrMatch = addrParser.firstMatch(instrData[1])!;
        instructions.add(Instruction(
            opcode,
            InstructionData(InstructionDataType.REGISTER, instrData[0]),
            InstructionData(InstructionDataType.IMMEDIATE, addrMatch.group(1)),
            InstructionData(InstructionDataType.ADDRESS, addrMatch.group(2))));
      } else {
        instructions.add(Instruction(
            opcode,
            InstructionData(InstructionDataType.REGISTER, instrData[0]),
            InstructionData(InstructionDataType.REGISTER, instrData[1]),
            InstructionData(InstructionDataType.REGISTER, instrData[2])));
      }
    }
  } catch (e) {
    print(e);
    throw "Invalid Instruction Format";
  }
  return instructions;
}

Future<String?> loadFile() async {
  FilePickerResult? result = await FilePicker.platform.pickFiles();

  if (result != null) {
    File file = File(result.files.single.path!);
    return file.readAsStringSync();
  } else {
    // User canceled the picker
  }
}

String statusToString(CPU cpu) {
  String out = "Cycle: ${cpu.cycle}\n";

  out += 'Instructions\n';
  for (final instr in cpu.instructions) {
    out +=
        '${instr.op.code}\t\t${instr.data1.data}\t\t${instr.data2.data}\t\t${instr.data3.data}\t\t${instr.issueCycle ?? ""}\t\t${instr.data3.data}\t\t${instr.startCycle ?? ""}-${instr.finishCycle ?? ""}\t\t${instr.writeCycle ?? ""}\n\n';
  }
  for (final station in cpu.reservationStations) {
    out +=
        '${station.name}\t\t${station.busy ? "busy" : "idle"}\t\t${station.currentInstruction?.op.code ?? ""}\t\t${station.vj ?? ""}\t\t${station.vk ?? ""}\t\t${station.qj?.name ?? ""}\t\t${station.qk?.name ?? ""}\t\t${station.A ?? ""}\n\n';
  }
  out += cpu.registers
      .map((key, value) => MapEntry(key, value?.name ?? ''))
      .toString();

  return out;
}

void writeFile(String contents) async {
  String? outputFile = await FilePicker.platform.saveFile(
    dialogTitle: 'Please select output directory:',
    fileName: 'status.txt',
  );

  if (outputFile == null) {
    return;
  }

  File file = File(outputFile);
  file.writeAsString(contents);
}
