// ignore_for_file: constant_identifier_names

const ISSUE_LATENCY = 1;
const WRITE_LATENCY = 1;
const BIG_NUMBER = 999999;

abstract class ReservationStation {
  final String name;
  Instruction? currentInstruction;
  int? opStartCycle, opEndCycle, opWriteCycle;
  dynamic vj, vk, A;
  ReservationStation? qj, qk;

  bool get busy => currentInstruction != null;

  /// Instructions supported by this reservation station
  /// Must be overriden by subclasses.
  List<Opcode> getSupportedOps();

  void reset() {
    currentInstruction =
        opStartCycle = opEndCycle = opWriteCycle = vj = vk = A = qj = qk = null;
  }

  /// When this reversation station receives a relevant broadcast from CDB,
  /// it should update values from Qj, Qk to Vj, Vk.
  void onReceiveCDBBroadcast(
      ReservationStation origin, int cycle, dynamic data) {
    if (origin == qj) {
      qj = null;
      vj = data;
    } else if (origin == qk) {
      qk = null;
      vk = data;
    }
  }

  /// Called on every CPU cycle update
  void onCycleUpdate(int cycle) {
    if (busy) {
      if (cycle >= opStartCycle! &&
          qj == null &&
          qk == null &&
          opEndCycle == null) {
        opStartCycle = cycle;
        currentInstruction?.startCycle = cycle;
        opEndCycle = opStartCycle! + currentInstruction!.op.latency;
      } else if (cycle == opEndCycle) {
        currentInstruction?.finishCycle = cycle;
        opWriteCycle = opEndCycle! + WRITE_LATENCY;
      } else if (cycle == opWriteCycle) {
        currentInstruction?.writeCycle = cycle;
      }
    }
  }

  /// Called when a new instruction is issued to this station.
  void issueInstruction(
      int cycle, Instruction instruction, Registers registers) {
    currentInstruction = instruction;
    opStartCycle = cycle + ISSUE_LATENCY;
    instruction.issueCycle = cycle;

    // Rename registers
    if (instruction.data2.type == InstructionDataType.REGISTER &&
        instruction.data3.type == InstructionDataType.REGISTER) {
      if (registers[instruction.data2.data] == null) {
        // Register is ready, copy data to vj
        vj = "Regs[${instruction.data2.data}]";
      } else {
        qj = registers[instruction.data2.data];
      }
      if (registers[instruction.data3.data] == null) {
        // Register is ready, copy data to vj
        vk = "Regs[${instruction.data3.data}]";
      } else {
        qk = registers[instruction.data3.data];
      }
    } else {
      final d2 = instruction.data2.type == InstructionDataType.IMMEDIATE
          ? instruction.data2.data
          : 'Regs[${instruction.data2.data}]';
      final d3 = instruction.data3.type == InstructionDataType.IMMEDIATE
          ? instruction.data3.data
          : 'Regs[${instruction.data3.data}]';
      A = '$d2 + $d3';
    }

    // Set register table
    if (instruction.data1.type == InstructionDataType.REGISTER) {
      registers[instruction.data1.data] = this;
    }
  }

  ReservationStation(this.name);
}

class LoadStoreStation extends ReservationStation {
  static List<Opcode> supportedOps = [Opcode.LOAD]; //Opcode.STORE];
  @override
  List<Opcode> getSupportedOps() => supportedOps;
  LoadStoreStation(String name) : super(name);
}

class AddSubStation extends ReservationStation {
  static List<Opcode> supportedOps = [Opcode.ADD, Opcode.SUB];
  @override
  List<Opcode> getSupportedOps() => supportedOps;
  AddSubStation(String name) : super(name);
}

class MulDivStation extends ReservationStation {
  static List<Opcode> supportedOps = [Opcode.MUL, Opcode.DIV];
  @override
  List<Opcode> getSupportedOps() => supportedOps;
  MulDivStation(String name) : super(name);
}

typedef Registers = Map<String, ReservationStation?>;

enum InstructionDataType { REGISTER, IMMEDIATE, ADDRESS }

class InstructionData {
  final InstructionDataType type;
  final dynamic data;
  InstructionData(this.type, this.data);
}

/// Instruction contains an OpCode and Rs, Rt, Rd
class Instruction {
  final Opcode op;
  final InstructionData data1, data2, data3;

  int? issueCycle, startCycle, finishCycle, writeCycle;

  bool get isIssued => issueCycle != null;
  bool get isStarted => startCycle != null;
  bool get isResultWritten => writeCycle != null;

  Instruction(this.op, this.data1, this.data2, this.data3);
}

class CPU {
  final List<ReservationStation> reservationStations;
  final List<Instruction> instructions;
  final Registers registers;
  int cycle = 0;

  void nextCycle() {
    cycle++;

    // Load next instruction
    try {
      final nextInstruction =
          instructions.firstWhere((instruction) => !instruction.isIssued);
      try {
        final availableStation = reservationStations.firstWhere((station) =>
            station.getSupportedOps().contains(nextInstruction.op) &&
            !station.busy);
        availableStation.issueInstruction(cycle, nextInstruction, registers);
      } on StateError catch (_) {
        // No available station
        // Wait for next cycle
      }
    } on StateError catch (_) {
      // No more instructions to issue
    }

    // Update reservation stations
    for (final station in reservationStations) {
      station.onCycleUpdate(cycle);
    }

    // Let's see which instructions have finished
    for (final station in reservationStations) {
      if (cycle >= (station.opWriteCycle ?? BIG_NUMBER)) {
        // Set register table
        if (station.currentInstruction!.data1.type ==
            InstructionDataType.REGISTER) {
          registers[station.currentInstruction!.data1.data] = null;
        }
        createCDBBroadcast(
            station, station.A == null ? 'V1' : 'Mem[${station.A}]');
        // Finished instruction, reset station
        station.reset();
      }
    }
  }

  /// Create CDB Broadcast to all reservation stations
  void createCDBBroadcast(ReservationStation origin, dynamic data) {
    for (final station in reservationStations) {
      if (station.busy) {
        station.onReceiveCDBBroadcast(origin, cycle, data);
      }
    }
  }

  CPU(this.reservationStations, this.instructions, this.registers);
}

class Opcode {
  int latency;
  final String code;
  Opcode(this.latency, this.code);

  static List<Opcode> all = [LOAD, ADD, SUB, MUL, DIV];

  static Opcode LOAD = Opcode(2, 'L.D');
  //static Opcode STORE = Opcode(2, 'S.D');
  static Opcode ADD = Opcode(3, 'ADD.D');
  static Opcode SUB = Opcode(3, 'SUB.D');
  static Opcode MUL = Opcode(11, 'MUL.D');
  static Opcode DIV = Opcode(41, 'DIV.D');
}
