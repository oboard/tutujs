///|
pub struct ClassFieldRecord {
  is_private : Bool
  name : String
  display_name : String
  init : @engine.Expr?
}

///|
pub struct FunctionValue {
  name : String?
  mut source : String?
  source_root : String?
  source_path : String?
  line_number : Int?
  column_number : Int?
  local_name_binding : Bool
  params : Array[@engine.ParamBinding]
  param_inits : Array[@engine.Expr?]
  body : Array[@engine.Stmt]
  env : Env
  id : Int
  props : Map[String, Property]
  mut proto : JSValue?
  mut home_object : JSValue?
  mut super_constructor : JSValue?
  mut instance_fields : Array[ClassFieldRecord]
  private_instance_fields : Array[(String, @engine.Expr?)]
  mut private_instance_props : Map[String, Property]
  mut is_constructor : Bool
  mut is_class_constructor : Bool
  mut is_default_constructor : Bool
  mut extensible : Bool
  is_strict : Bool
  is_generator : Bool
  is_async : Bool
  is_arrow : Bool
  mut in_class_field_init : Bool
}

///|
pub impl Show for FunctionValue with output(self, logger) {
  let label = match self.name {
    Some(name) => "function \{name}"
    None => "function"
  }
  logger.write_string(label)
}

///|
pub impl ToJson for FunctionValue with to_json(self) {
  let label = match self.name {
    Some(name) => "function \{name}"
    None => "function"
  }
  Json::string(label)
}

///|
priv enum GenControl {
  Normal(JSValue)
  Return(JSValue)
  Break(String?, JSValue?)
  Continue(String?, JSValue?)
  Throw(JSValue)
}

///|
priv enum GenResume {
  Next(JSValue)
  Return(JSValue)
  Throw(JSValue)
}

///|
priv enum GenStep {
  Yield(JSValue, (GenResume) -> GenStep raise)
  Await(JSValue, (GenResume) -> GenStep raise)
  Done(GenControl)
}

///|
priv enum GeneratorState {
  SuspendedStart
  SuspendedYield
  Executing
  Completed
}

///|
priv enum AsyncGeneratorState {
  SuspendedStart
  SuspendedYield
  Executing
  AwaitingReturn
  Completed
}

///|
priv struct AsyncGeneratorRequest {
  resume_state : GenResume
  promise : JSValue
  resolve : JSValue
  reject : JSValue
}

///|
struct AsyncGeneratorData {
  mut state : AsyncGeneratorState
  mut queue_index : Int
  queue : Array[AsyncGeneratorRequest]
}

///|
struct GeneratorData {
  mut state : GeneratorState
  env : Env
  func : FunctionValue
  mut next_step : (GenResume) -> GenStep raise
  roots : Array[JSValue]
}

///|
pub struct BoundFunctionValue {
  id : Int
  mut target : JSValue
  mut bound_this : JSValue
  bound_args : Array[JSValue]
  props : Map[String, Property]
  mut proto : JSValue?
  is_constructor : Bool
  mut extensible : Bool
}

///|
pub impl Show for BoundFunctionValue with output(self, logger) {
  let _ = self
  logger.write_string("function")
}

///|
pub impl ToJson for BoundFunctionValue with to_json(self) {
  let _ = self
  Json::string("function")
}
