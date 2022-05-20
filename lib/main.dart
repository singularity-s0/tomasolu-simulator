import 'dart:async';

import 'package:flutter/material.dart';
import 'package:tomasolu/devices.dart';
import 'package:tomasolu/io.dart';
import 'package:tomasolu/utils.dart';

void main() {
  runApp(const TomasoluSimulatorApp());
}

class TomasoluSimulatorApp extends StatelessWidget {
  const TomasoluSimulatorApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tomasolu Simulator',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const HomePage(title: 'Tomasolu Simulator'),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({Key? key, required this.title}) : super(key: key);
  final String title;
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late CPU cpu;
  Timer? timer;
  List<ReservationStation> stations = [
    LoadStoreStation('Load0'),
    LoadStoreStation('Load1'),
    AddSubStation('Add0'),
    AddSubStation('Add1'),
    AddSubStation('Add2'),
    MulDivStation('Mul0'),
    MulDivStation('Mul1'),
  ];
  Registers registers = {
    'F0': null,
    'F2': null,
    'F4': null,
    'F6': null,
    'F8': null,
    'F10': null,
    'F12': null,
    'F14': null,
    'F16': null,
    'F18': null,
    'F20': null,
    'F22': null,
    'F24': null,
    'F26': null,
    'F28': null,
    'F30': null,
  };
  String instrs = '''L.D F6,34(R2)
  L.D F2,45(R3)
  MUL.D F0,F2,F4
  SUB.D F8,F2,F6
  DIV.D F10,F0,F6
  ADD.D F6,F8,F2''';

  void reset() {
    cpu = CPU(stations, parseInstruction(instrs), registers);
    for (final station in stations) {
      station.reset();
    }
    for (final register in registers.keys) {
      registers[register] = null;
    }
  }

  @override
  void initState() {
    super.initState();
    cpu = CPU(stations, parseInstruction(instrs), registers);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: SingleChildScrollView(
            child: Column(
              children: <Widget>[
                Wrap(
                  children: [
                    ElevatedButton(
                        onPressed: () {
                          if (timer?.isActive == true) {
                            setState(() {
                              timer?.cancel();
                            });
                          } else {
                            setState(() {
                              timer = Timer.periodic(const Duration(seconds: 1),
                                  (timer) {
                                setState(() {
                                  cpu.nextCycle();
                                });
                              });
                            });
                          }
                        },
                        child: Text(timer?.isActive == true ? "Stop" : "Run")),
                    const SizedBox(height: 8, width: 8),
                    ElevatedButton(
                        onPressed: () {
                          setState(() {
                            cpu.nextCycle();
                          });
                        },
                        child: const Text("Single Step")),
                    const SizedBox(height: 8, width: 8),
                    ElevatedButton(
                        onPressed: () {
                          setState(() {
                            reset();
                          });
                        },
                        child: const Text("Reset")),
                  ],
                ),
                const SizedBox(height: 8),
                Wrap(
                  children: [
                    TextButton(
                        onPressed: () async {
                          try {
                            instrs = (await loadFile())!;
                            setState(() {
                              reset();
                            });
                          } catch (e) {
                            await Noticing.showAlert(
                                context, e.toString(), "Failed to read file");
                          }
                        },
                        child: const Text("Load Instructions From File")),
                    const SizedBox(height: 8, width: 8),
                    TextButton(
                        onPressed: () async {
                          await Noticing.showDeviceModificationDialog(
                              context, stations);
                          setState(() {});
                        },
                        child: const Text("Devices Settings")),
                    const SizedBox(height: 8, width: 8),
                    TextButton(
                        onPressed: () async {
                          await Noticing.showLatencyModificationDialog(context);
                        },
                        child: const Text("Latency Settings")),
                    const SizedBox(height: 8, width: 8),
                    TextButton(
                        onPressed: () {
                          writeFile(statusToString(cpu));
                        },
                        child: const Text("Save Results to File")),
                  ],
                ),
                const SizedBox(height: 16),
                const Text("Cycle"),
                Text(
                  cpu.cycle.toString(),
                  textScaleFactor: 2.0,
                ),
                const SizedBox(height: 8),
                const Text("Instructions"),
                Table(
                  border: TableBorder.all(color: Colors.black),
                  children: [
                        const TableRow(children: [
                          PaddedText("Op", bold: true),
                          PaddedText("R", bold: true),
                          PaddedText("Issue", bold: true),
                          PaddedText("Execute", bold: true),
                          PaddedText("Write", bold: true),
                        ])
                      ] +
                      cpu.instructions
                          .map((e) => TableRow(children: [
                                PaddedText(e.op.code),
                                PaddedText(
                                    '${e.data1.data} ${e.data2.data} ${e.data3.data}'),
                                PaddedText(
                                    e.isIssued ? '✅ ${e.issueCycle}' : ''),
                                PaddedText(e.isStarted
                                    ? (e.finishCycle == null
                                        ? '🤔 ${e.startCycle} -'
                                        : '✅ ${e.startCycle} - ${e.finishCycle!}')
                                    : ''),
                                PaddedText(e.isResultWritten
                                    ? '✅ ${e.writeCycle}'
                                    : ''),
                              ]))
                          .toList(),
                ),
                const SizedBox(height: 8),
                const Text("Reservation Stations & Load/Store Buffers"),
                Table(
                  border: TableBorder.all(color: Colors.black),
                  children: [
                        const TableRow(children: [
                          PaddedText("Station", bold: true),
                          PaddedText("Busy", bold: true),
                          PaddedText("Op", bold: true),
                          PaddedText("Vj", bold: true),
                          PaddedText("Vk", bold: true),
                          PaddedText("Qj", bold: true),
                          PaddedText("Qk", bold: true),
                          PaddedText("A", bold: true),
                        ])
                      ] +
                      cpu.reservationStations
                          .map((e) => TableRow(children: [
                                PaddedText(e.name),
                                PaddedText(e.busy ? '✅' : '❌'),
                                PaddedText(e.currentInstruction?.op.code ?? ''),
                                PaddedText(e.vj ?? ''),
                                PaddedText(e.vk ?? ''),
                                PaddedText(e.qj?.name ?? ''),
                                PaddedText(e.qk?.name ?? ''),
                                PaddedText(e.A ?? ''),
                              ]))
                          .toList(),
                ),
                const SizedBox(height: 8),
                const Text("CPU Registers"),
                Table(
                  border: TableBorder.all(color: Colors.black),
                  children: [
                    TableRow(
                        children: cpu.registers
                            .map<String, Widget>((key, value) =>
                                MapEntry(key, PaddedText(key, bold: true)))
                            .values
                            .toList()),
                    TableRow(
                        children: cpu.registers
                            .map<String, Widget>((key, value) =>
                                MapEntry(key, PaddedText(value?.name ?? '')))
                            .values
                            .toList()),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class PaddedText extends StatelessWidget {
  final EdgeInsets padding;
  final String text;
  final bool bold;

  const PaddedText(this.text,
      {super.key,
      this.padding = const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      this.bold = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
        padding: padding,
        child: Text(text,
            style: bold ? const TextStyle(fontWeight: FontWeight.bold) : null));
  }
}
