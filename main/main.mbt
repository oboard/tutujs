///|
/// The build system.
fn main {
  let args = @env.args()[1:].to_array()
  let args = if args.search("--") is Some(idx) {
    args[idx + 1:].to_array()
  } else {
    args
  }
  match args {
    ["repl"] => start_repl()
    ["test262", path] => run_test262(path)
    ["exec", code] => {
      let ctx = @runtime.Context::new()
      let _ = ctx.eval(code) catch { _ => @runtime.value_undefined() }

    }
    ["run", script_or_file, .. args] => {
      let is_file = @fs.is_file(script_or_file) catch { _ => false }
      if is_file {
        // Run as file
        run_file(script_or_file)
      } else {
        // Try to run as script
        match resolve_package_script(script_or_file) {
          Some(cmd) => {
            let cmd_parts = cmd
              .split(" ")
              .map(fn(s) { s.to_string() })
              .collect()
            // Append extra args
            args.each(fn(arg) { cmd_parts.push(arg) })
            let exit_code = run_shell_command(cmd_parts)
            @sys.exit(exit_code)
          }
          None => {
            println(
              "Error: Script '\{script_or_file}' not found in package.json and file does not exist",
            )
            @sys.exit(1)
          }
        }
      }
    }
    [path] =>
      // Legacy behavior: treat single arg as run file
      run_file(path)
    _ =>
      println(
        (
          #| Tutu is a JavaScript runtime.
          #|   Usage: tutu <command> [...flags] [...args]
          #|   Commands:
          #|     run       ./my-script.js       Execute a file with Tutu
          #|               lint                 Run a package.json script
          #|     repl                           Start a REPL session with Tutu
          #|     exec                           Run a shell script directly with Tutu
        ),
      )
  }
}

///|
fn run_file(path : String) -> Unit {
  let path = resolve_entry_point(path)
  let code = @fs.read_file_to_string(path) catch {
    e => {
      println("Error reading file \{path}:\{e} ")
      return
    }
  }
  let ctx = @runtime.Context::new()
  let _ = ctx.eval_with_path(code, path) catch {
    _ => @runtime.value_undefined()
  }

}

///|
fn run_shell_command(args : Array[String]) -> Int {
  if args.is_empty() {
    return 0
  }
  let cmd = args[0]
  let cmd_args = args[1:]
  // Placeholder until we fix async process execution
  println("Executing: \{cmd} \{cmd_args}")
  // @process.run(...)
  0
}

///|
fn resolve_package_script(name : String) -> String? {
  // Look for package.json in current directory
  let pkg_path = "package.json"
  if @fs.path_exists(pkg_path) {
    let content = @fs.read_file_to_string(pkg_path) catch { _ => return None }
    let json = @json.parse(content) catch { _ => return None }
    match json {
      Object(fields) =>
        match fields.get("scripts") {
          Some(Object(scripts)) =>
            match scripts.get(name) {
              Some(String(cmd)) => Some(cmd)
              _ => None
            }
          _ => None
        }
      _ => None
    }
  } else {
    None
  }
}

///|
fn resolve_entry_point(path : String) -> String {
  let is_dir = @fs.is_dir(path) catch { _ => false }
  if is_dir {
    let p = @path.Path(path)
    let pkg_path = p.join(@path.Path("package.json")).0
    if @fs.path_exists(pkg_path) {
      match parse_package_json(pkg_path, base_dir=path) {
        Ok(p) => return p
        Err(e) => println("Warning: Failed to parse package.json: \{e}")
      }
    }
    // Fallback to index.js
    let index_path = p.join(@path.Path("index.js")).0
    if @fs.path_exists(index_path) {
      return index_path
    }
    return path
  }
  if path.has_suffix("package.json") && @fs.path_exists(path) {
    let p = @path.Path(path)
    let parent = p.dirname().0
    let base_dir = if parent == "" { "." } else { parent }
    match parse_package_json(path, base_dir~) {
      Ok(p) => return p
      Err(e) => println("Warning: Failed to parse package.json: \{e}")
    }
  }
  path
}

///|
fn parse_package_json(
  path : String,
  base_dir~ : String,
) -> Result[String, String] {
  let content = @fs.read_file_to_string(path) catch {
    e => return Err(e.to_string())
  }
  let json_val = @json.parse(content) catch { e => return Err(e.to_string()) }
  match json_val {
    Object({ "main": String(main_file), .. }) => {
      let p = @path.Path(base_dir).join(@path.Path(main_file))
      Ok(p.0)
    }
    _ => Err("package.json must be an object or missing 'main' field")
  }
}
