// Per-function cyclomatic complexity gate for the Dart sources.
//
// Scores every function, method, constructor, and closure as
// 1 + decision points (if/for/while/do statements and elements, switch cases,
// catch clauses, ternaries, and &&/||/?? operators). Closures nested inside
// a function body are scored as their own unit and excluded from the
// enclosing unit's score. Any unit above the threshold fails the run.
//
// Usage: dart run tool/check_complexity.dart [--max N] [lib ...]

// A CLI tool; printing to stdout is its output channel.
// ignore_for_file: avoid_print
import 'dart:io';

import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';

const defaultMaxComplexity = 20;

class FunctionUnit {
  const FunctionUnit(this.path, this.line, this.name, this.complexity);

  final String path;
  final int line;
  final String name;
  final int complexity;
}

void main(List<String> arguments) {
  var maxComplexity = defaultMaxComplexity;
  final roots = <String>[];
  for (var i = 0; i < arguments.length; i++) {
    if (arguments[i] == '--max') {
      maxComplexity = int.parse(arguments[++i]);
    } else {
      roots.add(arguments[i]);
    }
  }
  if (roots.isEmpty) {
    roots.add('lib');
  }

  final files = <File>[];
  for (final root in roots) {
    final directory = Directory(root);
    if (!directory.existsSync()) {
      stderr.writeln('check_complexity: no such directory: $root');
      exitCode = 2;
      return;
    }
    files.addAll(directory
        .listSync(recursive: true)
        .whereType<File>()
        .where((file) => file.path.endsWith('.dart')));
  }

  final units = <FunctionUnit>[];
  for (final file in files) {
    final result = parseFile(
        path: file.path,
        featureSet: FeatureSet.latestLanguageVersion(),
        throwIfDiagnostics: false);
    final collector = _UnitCollector(file.path,
        (int offset) => result.lineInfo.getLocation(offset).lineNumber);
    result.unit.accept(collector);
    units.addAll(collector.units);
  }

  units.sort((a, b) => b.complexity.compareTo(a.complexity));
  print('Analyzed ${units.length} functions in ${files.length} files.');
  print('Top complexity offenders:');
  for (final unit in units.take(10)) {
    print('  ${unit.complexity.toString().padLeft(3)}  '
        '${relativePath(unit.path)}:${unit.line} ${unit.name}');
  }

  final violations =
      units.where((unit) => unit.complexity > maxComplexity).toList();
  if (violations.isNotEmpty) {
    print('Complexity limit $maxComplexity exceeded by:');
    for (final unit in violations) {
      print('  ${relativePath(unit.path)}:${unit.line} '
          '${unit.name} is ${unit.complexity}');
    }
    exitCode = 1;
  } else {
    print('All functions are within the complexity limit of $maxComplexity.');
  }
}

String relativePath(String path) => path.startsWith(Directory.current.path)
    ? path.substring(Directory.current.path.length + 1)
    : path;

class _UnitCollector extends RecursiveAstVisitor<void> {
  _UnitCollector(this.path, this.toLine);

  final String path;
  final int Function(int offset) toLine;
  final units = <FunctionUnit>[];

  @override
  void visitFunctionDeclaration(FunctionDeclaration node) {
    _record(node.name.lexeme, node.functionExpression.body, node);
  }

  @override
  void visitMethodDeclaration(MethodDeclaration node) {
    _record(node.name.lexeme, node.body, node);
  }

  @override
  void visitConstructorDeclaration(ConstructorDeclaration node) {
    _record(node.name?.lexeme ?? 'constructor', node.body, node);
  }

  @override
  void visitFunctionExpression(FunctionExpression node) {
    _record('<closure>', node.body, node);
  }

  void _record(String name, FunctionBody body, AstNode declaration) {
    final counter = _DecisionCounter();
    body.accept(counter);
    units.add(FunctionUnit(
        path, toLine(declaration.offset), name, 1 + counter.decisions));
    // Descend so nested local functions and closures become their own units.
    body.accept(this);
  }
}

class _DecisionCounter extends UnifyingAstVisitor<void> {
  int decisions = 0;

  @override
  void visitNode(AstNode node) {
    if (node is FunctionExpression || node is FunctionDeclaration) {
      return; // Nested units are scored separately.
    }
    if (node is IfStatement ||
        node is ForStatement ||
        node is WhileStatement ||
        node is DoStatement ||
        node is SwitchCase ||
        node is SwitchPatternCase ||
        node is CatchClause ||
        node is ConditionalExpression ||
        node is IfElement ||
        node is ForElement) {
      decisions++;
    } else if (node is BinaryExpression) {
      final lexeme = node.operator.lexeme;
      if (lexeme == '&&' || lexeme == '||' || lexeme == '??') {
        decisions++;
      }
    }
    node.visitChildren(this);
  }
}
