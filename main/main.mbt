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
    [path] => {
      let code = @fs.read_file_to_string(path) catch {
        e => {
          println("Error reading file \{path}:\{e} ")
          return
        }
      }
      let ctx = @runtime.create_global()
      let _ = ctx.eval(code)

    }
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

  // let source_arg = @clap.Arg::positional(
  //   nargs=@clap.One,
  //   help="Execute a file with Tutu or run a package.json script",
  // )
  // let parser = @clap.Parser::new(
  //   prog="tutu",
  //   subcmds={
  //     // "new": @clap.SubCommand::new(help="Create a new MoonBit module"),
  //     // "build": @clap.SubCommand::new(help="Build the current package"),
  //     // "check": @clap.SubCommand::new(
  //     //   help="Check the current package, but don't build object files",
  //     // ),
  //     "run": @clap.SubCommand::new(help="Run a script", args={
  //       "SCRIPT_OR_FILE": source_arg,
  //     }),
  //     "version": @clap.SubCommand::new(help="Print version information"),
  //     "repl": @clap.SubCommand::new(help="Start a REPL session with Tutu"),
  //   },
  //   args={ "SCRIPT_OR_FILE": source_arg },
  // )
  // let value = @clap.SimpleValue::new(parser.prog)
  // let help_message = parser.parse(value, args) catch {
  //   e =>
  //     match e {
  //       // 让我们自己的逻辑处理无效命令
  //       InvalidSubCommandName(e) => {
  //         invalid_command(e)
  //         return
  //       }
  //       _ => {
  //         println(e)
  //         return
  //       }
  //     }
  // }
  // if help_message is Some(help) {
  //   println(help)
  //   return
  // }

  // // 没有子命令，默认进入 REPL
  // start_repl()
}

// ///|
// fn invalid_command(subcmd : String) -> Unit {
//   println("Unknown command: " + subcmd)
//   println("Use 'tutu --help' for more information.")
// }
