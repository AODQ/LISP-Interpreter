module parser;
import std.stdio : writeln;

import std.string, std.algorithm, std.range;
import std.variant;

/**
  A lot of thanks to
  http://norvig.com/lispy.html
*/

class StrList {
public:
  string[] list;
  this ( string[] _list ) { list = _list; }
}

StrList Tokenize(string chars) {
  return new StrList(chars.replace("(", " ( ")
                          .replace(")", " ) ")
                          .split());
}

Variant ToVariant(T)(T n) {
  Variant t;
  t = n;
  return t;
}

class Str {
public:
  string str;
  this ( string _str ) { str = _str.dup; }
}

Variant Atom(string token) {
  import std.conv : to;
  Variant var;
  if ( token[$-1] == 'f' ) {
    try { // try float
      return to!float(token[0 .. $-1]).ToVariant;
    } catch ( Exception e ) {}
  }
  try { // try int
    return to!int(token).ToVariant;
  } catch ( Exception e ) {
    return token.ToVariant;
  }
}

Variant Read_From_Tokens(StrList tokens) {
  if ( tokens.list.length == 0 ) assert(0);
  auto token  = tokens.list[0];
  tokens.list = tokens.list[1 .. $];

  if ( token == "(" ) {
    Variant[] L = [];
    while ( tokens.list[0] != ")" ) {
      L ~= Read_From_Tokens(tokens);
    }
    tokens.list = tokens.list[1 .. $]; // pop off ')'
    return L.ToVariant;
  } else if ( token == ")" ) {
    assert(0);
  } else {
    return Atom(token);
  }
}

Variant Parse ( string program ) {
  return ("( . " ~ program ~ " )").Tokenize.Read_From_Tokens.Eval;
}

alias FnType = Variant delegate(Variant[] args)[string];
alias VarType = Variant[string];

void Add_Func(T)(string name, T func) {
  global_env[name] = delegate Variant(Variant[] args) {
    // call it with return type ( if one exists )
    Variant retval;
    static if ( is(ReturnType!func == void) ) {          func(args); }
    else                                      { retval = func(args); }
    return retval;
  };
}

void Default_Environment ( ) {
  // Add_Func("sqrt", delegate(Variant[] vars) {
  //   import std.math;
  //   return sqrt(vars[0]);
  // });
  // Add_Func("abs", delegate(Variant[] vars) {
  //   import std.math;
  //   return abs(vars[0]);
  // });
  Add_Func("sqrt", delegate(Variant[] vars) {
    import std.math;
    return sqrt(vars[0].coerce!float);
  });
  Add_Func("-", delegate(Variant[] vars) {
    auto res = 0;
    foreach ( n; vars ) res -= n.coerce!int;
    return res;
  });
  Add_Func("+", delegate(Variant[] vars) {
    auto res = 0;
    foreach ( n; vars ) res += n.coerce!int;
    return res;
  });
  Add_Func("/", delegate(Variant[] vars) {
    auto res = 0;
    foreach ( n; vars ) res /= n.coerce!int;
    return res;
  });
  Add_Func("*", delegate(Variant[] vars) {
    auto res = 0;
    foreach ( n; vars ) res *= n.coerce!int;
    return res;
  });
  Add_Func(".", delegate(Variant[] vars) {
    if ( vars.length > 0 )
      return vars[$-1];
    return null.ToVariant;
  });
  Add_Func("pair?", delegate(Variant[] vars) {
    return vars[0].length > 1;
  });
  Add_Func("null?", delegate(Variant[] vars) {
    return vars[0].length == 0;
  });
  Add_Func("cons", delegate(Variant[] vars) {
    Variant[] list1, list2;
    foreach ( i; 0 .. vars[0].length )
      list1 ~= vars[0][i];
    foreach ( i; 0 .. vars[1].length )
      list2 ~= vars[1][i];
    return list1 ~ list2;
  });
  Add_Func("car", delegate(Variant[] vars) {
    return vars[0][0];
  });
  Add_Func("cdr", delegate(Variant[] vars) {
    Variant[] list;
    foreach ( i; 1 .. vars[0].length )
      list ~= vars[0][i];
    return list;
  });
  global_var["pi"] = 3;

  global_environment = new Environment(global_env, global_var);
}

private FnType global_env;
private VarType global_var;
private Environment global_environment;

import std.conv : to;
bool Symbol(Variant x) { return x.convertsTo!string; }
bool List  (Variant x) { return x.type.to!string[$-2 .. $] == "[]"; }

void Init() { Default_Environment(); }


Variant REnv(Environment env, Variant x) {
  auto renv = env.Search(x);
  auto t = x.coerce!string in renv.env;
  if ( t !is null ) {
    return (*t).ToVariant;
  }
  auto l = x.coerce!string in renv.var;
  if ( l !is null ) {
    return *l;
  }
  assert(0);
}

class Procedure {
  Variant[] parameters;
  Variant fn;
  Environment env;
  this ( Variant _parameters, Variant _fn, Environment _env ) {
    for ( int i = 0; i < _parameters.length; ++ i ) {
      parameters ~= _parameters[i];
    }
    fn         = _fn;
    env        = _env;
  }
  Variant Call ( Variant[] args ) {
    return Eval(fn, new Environment(parameters, args, env));
  }
}

class Environment {
public:
  FnType env;
  VarType var;
  Environment outer;
  this ( Variant[] parameters, Variant[] args, Environment _outer ) {
    import std.range;
    foreach ( tup; zip(parameters, args) ) {
      var[tup[0].coerce!string] = tup[1];
    }
    outer = _outer;
  }
  this ( FnType _env, VarType _var, Environment _outer = null) {
    env = _env;
    var = _var;
    outer = _outer;
  }

  Environment Search ( Variant val ) {
    return Search ( val.coerce!string );
  }
  Environment Search ( string val ) {
    if ( val in env ) return this;
    if ( val in var ) return this;
    if ( outer is null ) {
      writeln("COULD NOT FIND: ", val);
    }
    return outer.Search(val);
  }
}

Variant Eval(Variant x, Environment env = global_environment) {
  if ( !x.List  ) return x;
  if ( x[0] == "~" ) {
    return x[1];
  }
  if ( x[0] == "if" ) {
    return Eval(Eval(x[1], env).coerce!bool ? x[2] : x[3], env);
  }
  if ( x[0] == "cond" ) {
  }
  if ( x[0] == "define" ) {
    env.var[ x[1].coerce!string ] = Eval( x[2], env).ToVariant;
    return null.ToVariant;
  }
  if ( x[0] == "set!" ) {
    auto var = x[1].coerce!string;
    env.Search(var).var[var] = Eval(x[2], env);
  }
  if ( x[0] == "lambda" ) {
    return (new Procedure(x[1], x[2], env)).ToVariant;
  }
  if ( x.Symbol ) {
    return env.Search(x).REnv(x);
  }
  auto func = Eval(x[0], env);
  Variant[] args;
  for ( int i = 1; i < x.length; ++ i ) {
    args ~= Eval(x[i], env);
  }
  auto ret = func.convertsTo!Procedure ? func.coerce!Procedure.Call(args) :
                                          func(args);
  return ret;
}
