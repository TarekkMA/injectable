import 'package:injectable_generator/dependency_config.dart';
import 'package:injectable_generator/generator/config_code_generator.dart';
import 'package:injectable_generator/utils.dart';

abstract class RegisterFuncGenerator {
  final buffer = StringBuffer();

  write(Object o) => buffer.write(o);
  writeln(Object o) => buffer.writeln(o);
  String generate(DependencyConfig dep);
  String generateConstructor(DependencyConfig dep, {String getIt = 'g'}) {
    final params = dep.dependencies.map((injectedDep) {
      var type = injectedDep.type == 'dynamic' ? '' : '<${injectedDep.type}>';
      var instanceName = '';
      if (injectedDep.name != null) {
        instanceName = "instanceName:'${injectedDep.name}'";
      }
      final paramName =
          (!injectedDep.isPositional) ? '${injectedDep.paramName}:' : '';

      if (injectedDep.isFactoryParam) {
        return '$paramName${injectedDep.paramName}';
      } else {
        return '${paramName}$getIt$type($instanceName)';
      }
    }).toList();

    final constructName =
        dep.constructorName.isEmpty ? "" : ".${dep.constructorName}";
    if (params.length > 2) {
      params.add('');
    }
    return '${stripGenericTypes(dep.bindTo)}$constructName(${params.join(',')})';
  }

  String generateAwaitSetup(DependencyConfig dep, String constructBody) {
    var awaitedVar = toCamelCase(stripGenericTypes(dep.type));
    if (registeredVarNames.contains(awaitedVar)) {
      awaitedVar =
          '$awaitedVar${registeredVarNames.where((i) => i.startsWith(awaitedVar)).length}';
    }
    registeredVarNames.add(awaitedVar);

    writeln('final $awaitedVar = await $constructBody;');
    return awaitedVar;
  }

  String generateConstructorForModule(DependencyConfig dep) {
    final mConfig = dep.moduleConfig;
    final mName = toCamelCase(mConfig.moduleName);

    var initializer = StringBuffer()..write(mConfig.name);
    if (mConfig.isMethod) {
      initializer.write('(');
      initializer.write(mConfig.params.keys.join(','));
      initializer.write(')');
    }

    return '$mName.${initializer.toString()}';
  }

  void closeRegisterFunc(DependencyConfig dep) {
    if (dep.signalsReady != null) {
      write(',signalsReady: ${dep.signalsReady}');
    }
    if (dep.instanceName != null) {
      write(",instanceName: '${dep.instanceName}'");
    }
    write(");");
  }
}
