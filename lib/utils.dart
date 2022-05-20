/*
 *     Copyright (C) 2021 singularity-s0
 *
 *     This program is free software: you can redistribute it and/or modify
 *     it under the terms of the GNU General Public License as published by
 *     the Free Software Foundation, either version 3 of the License, or
 *     (at your option) any later version.
 *
 *     This program is distributed in the hope that it will be useful,
 *     but WITHOUT ANY WARRANTY; without even the implied warranty of
 *     MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *     GNU General Public License for more details.
 *
 *     You should have received a copy of the GNU General Public License
 *     along with this program.  If not, see <https://www.gnu.org/licenses/>.
 */

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tomasolu/devices.dart';

class Noticing {
  static showAlert(BuildContext context, String message, String title) {
    return showDialog(
        context: context,
        builder: (BuildContext context) => AlertDialog(
              scrollable: true,
              title: Text(title),
              content: Text(message),
              actions: <Widget>[
                TextButton(
                    child: const Text("OK"),
                    onPressed: () => Navigator.pop(context)),
              ],
            ));
  }

  static Future<bool?> showConfirmationDialog(
      BuildContext context, String message, String title) {
    return showDialog<bool>(
        context: context,
        builder: (BuildContext context) => AlertDialog(
              scrollable: true,
              title: Text(title),
              content: Text(message),
              actions: <Widget>[
                TextButton(
                    child: const Text("Cancel"),
                    onPressed: () => Navigator.pop(context, false)),
                TextButton(
                    child: const Text("OK"),
                    onPressed: () => Navigator.pop(context, true)),
              ],
            ));
  }

  static Future<String?> showInputDialog(BuildContext context, String title,
      {int? maxLength}) {
    var text = "";
    return showDialog<String>(
        context: context,
        builder: (BuildContext context) => AlertDialog(
              title: Text(title),
              content: TextField(
                onChanged: (value) => text = value,
                onSubmitted: (value) => Navigator.pop(context, value),
                maxLength: maxLength,
                maxLengthEnforcement:
                    MaxLengthEnforcement.truncateAfterCompositionEnds,
                maxLines: maxLength == null ? 1 : null,
                expands: maxLength == null ? false : true,
              ),
              actions: <Widget>[
                TextButton(
                    child: const Text("OK"),
                    onPressed: () => Navigator.pop(context, text)),
              ],
            ));
  }

  static showDeviceModificationDialog(
      BuildContext context, List<ReservationStation> stations) {
    return showDialog(
        context: context,
        builder: (BuildContext context) => AlertDialog(
              scrollable: true,
              title: const Text("Device Settings"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Table(
                    children: stations
                        .map((e) => TableRow(children: [
                              Text(e.name),
                              TextButton(
                                  onPressed: () {
                                    stations.remove(e);
                                    Navigator.pop(context);
                                    Noticing.showAlert(
                                        context,
                                        "${e.name} removed",
                                        "Operation successful");
                                  },
                                  child: Text(
                                    "Remove",
                                    style: TextStyle(
                                        color: Theme.of(context).errorColor),
                                  ))
                            ]))
                        .toList(),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                      onPressed: () async {
                        final name = await Noticing.showInputDialog(
                            context, "Input Name:");
                        if (name != null) {
                          stations.add(LoadStoreStation(name));
                          Navigator.pop(context);
                          Noticing.showAlert(
                              context, "${name} added", "Operation successful");
                        }
                      },
                      child: const Text("Add another Load Station")),
                  const SizedBox(height: 8),
                  TextButton(
                      onPressed: () async {
                        final name = await Noticing.showInputDialog(
                            context, "Input Name:");
                        if (name != null) {
                          stations.add(AddSubStation(name));
                          Navigator.pop(context);
                          Noticing.showAlert(
                              context, "${name} added", "Operation successful");
                        }
                      },
                      child: const Text("Add another Add/Sub Station")),
                  const SizedBox(height: 8),
                  TextButton(
                      onPressed: () async {
                        final name = await Noticing.showInputDialog(
                            context, "Input Name:");
                        if (name != null) {
                          stations.add(MulDivStation(name));
                          Navigator.pop(context);
                          Noticing.showAlert(
                              context, "${name} added", "Operation successful");
                        }
                      },
                      child: const Text("Add another Mul/Div Station")),
                ],
              ),
              actions: <Widget>[
                TextButton(
                    child: const Text("Cancel"),
                    onPressed: () => Navigator.pop(context)),
              ],
            ));
  }

  static showLatencyModificationDialog(BuildContext context) {
    return showDialog(
        context: context,
        builder: (BuildContext context) => AlertDialog(
              scrollable: true,
              title: const Text("Latency Settings"),
              content: Column(mainAxisSize: MainAxisSize.min, children: [
                Table(
                  children: Opcode.all
                      .map((e) => TableRow(children: [
                            Text(e.code),
                            Text(e.latency.toString()),
                            TextButton(
                              onPressed: () async {
                                final newLat = int.tryParse(
                                    await showInputDialog(
                                            context, "New Latency:") ??
                                        "");
                                if (newLat != null) {
                                  e.latency = newLat;
                                  Navigator.pop(context);
                                  Noticing.showAlert(
                                      context,
                                      "${e.code} lantency changed to ${newLat}",
                                      "Operation successful");
                                }
                              },
                              child: Text("Change"),
                            )
                          ]))
                      .toList(),
                ),
              ]),
              actions: <Widget>[
                TextButton(
                    child: const Text("Cancel"),
                    onPressed: () => Navigator.pop(context)),
              ],
            ));
  }
}
