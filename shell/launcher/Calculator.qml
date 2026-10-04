pragma ComponentBehavior: Bound

import QtQuick
import Quickshell.Io
import qs.config
import "LauncherLogic.js" as Logic

Item {
    id: root

    property string query: ""
    readonly property var conversion: Config.launcher.currency ? Logic.currencyConversion(query) : null
    readonly property string expression: conversion?.expression ?? Logic.calcExpression(query)
    readonly property var options: ["-defaults", "-set", "update exchange rates 0", "-set", "decimal comma 0", "-set", "digit grouping 1", "-set", "division sign 2", "-time", "500"]
    property var result: null
    property real ratesTriedAt: 0

    onExpressionChanged: evaluate()

    function evaluate(): void {
        if (expression === "") {
            result = null;
            return;
        }
        const decimals = conversion && conversion.target !== "BTC" ? ["-set", "max decimals 2"] : [];
        const process = evaluator.createObject(root, {
            expression: expression,
            conversion: conversion,
            command: ["qalc", ...options, ...decimals, expression]
        });
        process.running = true;
    }

    function finish(expression: string, conversion: var, output: string): void {
        if (expression !== root.expression)
            return;
        if (conversion && Logic.staleRates(output))
            updateRates();
        const calculation = Logic.parseCalculation(output, conversion !== null);
        if (!calculation || (conversion && calculation.echo !== conversion.echo)) {
            result = null;
            return;
        }
        result = Object.assign(calculation, conversion ? {
            title: "Currency",
            pretty: `${calculation.pretty} → ${conversion.target}`
        } : {
            title: "Calculator"
        });
    }

    function updateRates(): void {
        if (ratesUpdater.running || Date.now() - ratesTriedAt < 3600 * 1000)
            return;
        ratesTriedAt = Date.now();
        ratesUpdater.running = true;
    }

    Process {
        id: ratesUpdater

        command: ["qalc", "-defaults", "-exrates", "1"]
        onExited: root.evaluate()
    }

    Component {
        id: evaluator

        Process {
            id: process

            property string expression
            property var conversion

            stdout: StdioCollector {
                onStreamFinished: {
                    root.finish(process.expression, process.conversion, text);
                    process.destroy();
                }
            }
        }
    }
}
