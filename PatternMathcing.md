模式匹配
模式匹配允许我们匹配特定模式并从数据结构中绑定数据。

简单模式
我们可以将表达式与以下内容进行模式匹配：

字面量，例如布尔值、数字、字符、字符串等

常量

结构体

枚举

数组

键值对

JSON

等等。我们可以定义标识符来绑定匹配的值，以便稍后使用。

const ONE = 1

fn match_int(x : Int) -> Unit {
  match x {
    0 => println("zero")
    ONE => println("one")
    value => println(value)
  }
}
我们可以使用 _ 作为我们不关心的值的通配符，并使用 .. 忽略结构体或枚举的剩余字段，或数组（参见 [数组模式](#array-pattern））。

struct Point3D {
  x : Int
  y : Int
  z : Int
}

fn match_point3D(p : Point3D) -> Unit {
  match p {
    { x: 0, .. } => println("on yz-plane")
    _ => println("not on yz-plane")
  }
}

enum Point[T] {
  Point2D(Int, Int, name~ : String, payload~ : T)
}

fn[T] match_point(p : Point[T]) -> Unit {
  match p {
    //! Point2D(0, 0) => println("2D origin")
    Point2D(0, 0, ..) => println("2D origin")
    Point2D(_) => println("2D point")
    _ => panic()
  }
}
我们可以使用 as 为某些模式命名，可以使用 | 一次匹配多个情况。在单个模式中，变量名只能绑定一次，并且在 | 模式的两侧应绑定相同的变量集。

match expr {
  //! Add(e1, e2) | Lit(e1) => ...
  Lit(n) as a => ...
  Add(e1, e2) | Mul(e1, e2) => ...
  ...
}
数组模式
数组模式可以用来匹配以下类型以获取其对应的元素或视图（View）：

类型

元素

视图

Array[T], ArrayView[T], FixedArray[T]

T

ArrayView[T]

Bytes, BytesView

字节

BytesView

String, StringView

字符

StringView

数组模式可以有以下形式：

[]：匹配空数组

[pa, pb, pc]：匹配长度为 3 的数组，并将其中的元素分别绑定到 pa, pb, pc

[pa, ..rest, pb]：匹配至少有两个元素的数组，并将第一个元素绑定到pa，最后一个元素绑定到 pb，其余元素绑定到 rest。如果不需要其余元素，可以省略绑定 rest。在 .. 部分前后允许任意数量的元素。由于 .. 可以匹配不确定数量的元素，因此在数组模式中最多只能出现一次。

test {
  let ary = [1, 2, 3, 4]
  if ary is [a, b, .. rest] && a == 1 && b == 2 && rest.length() == 2 {
    inspect("a = \{a}, b = \{b}", content="a = 1, b = 2")
  } else {
    fail("")
  }
  guard ary is [.., a, b] else { fail("") }
  inspect("a = \{a}, b = \{b}", content="a = 3, b = 4")
}
数组模式提供了一种 Unicode 安全的方式来操作字符串，这意味着它在访问元素的时候不会跨越代码单元边界。例如，我们可以检查一个包含 Unicode 的字符串是否是回文：

test {
  fn palindrome(s : String) -> Bool {
    loop s.view() {
      [] | [_] => true
      [a, .. rest, b] => if a == b { continue rest } else { false }
    }
  }

  inspect(palindrome("abba"), content="true")
  inspect(palindrome("中b中"), content="true")
  inspect(palindrome("文bb中"), content="false")
}
当数组模式中有连续的字符或字节常量时，可以使用模式展开 .. 运算符将它们组合起来，使代码看起来更整洁。在这种情况下，.. 后跟字符串或字节常量匹配确切数量的元素，因此它可以在数组模式中多次使用。

const NO : Bytes = "no"

test {
  fn match_string(s : String) -> Bool {
    match s {
      [.. "yes", ..] => true // equivalent to ['y', 'e', 's', ..]
    }
  }

  fn match_bytes(b : Bytes) -> Bool {
    match b {
      [.. NO, ..] => false // equivalent to ['n', 'o', ..]
    }
  }
}
范围模式
对于内置整数类型和 Char，MoonBit 允许匹配值是否落在特定范围内。

范围模式的形式为 a..<b 或 a..=b，其中 ..< 表示上限是排他的，..= 表示包含上限。a 和 b 可以是以下之一：

字面量

使用 const 声明的常量

_，表示此模式在此侧没有限制

以下是一些示例：

const Zero = 0

fn sign(x : Int) -> Int {
  match x {
    _..<Zero => -1
    Zero => 0
    1..<_ => 1
  }
}

fn classify_char(c : Char) -> String {
  match c {
    'a'..='z' => "lowercase"
    'A'..='Z' => "uppercase"
    '0'..='9' => "digit"
    _ => "other"
  }
}
Map 模式
MoonBit 允许在类似 map 的数据结构上方便地进行匹配。在 map 模式内，key : value 语法将在 map 中存在 key 时匹配，并将 key 的值与模式 value 匹配。key? : value 语法将无论 key 是否存在都匹配，value 将与 map[key]（一个可选项）匹配。

match map {
  // 仅在 `map` 中存在 "b" 时匹配
  { "b": _, .. } => ...
  // 仅在 `map` 中不存在 "b" 且 "a" 存在于 `map` 时匹配。
  // 匹配时，将 `map` 中的 "a" 的值绑定到 `x`
  { "b"? : None, "a": x, .. } => ...
  // 编译器报告缺失的情况：{ "b"? : None, "a"? : None }
}
要使用 map 模式匹配数据类型 T，T 必须具有某种类型 K 和 V 的方法 op_get(Self, K) -> Option[V]（请参见 方法和特征）。

目前，map 模式的键部分必须是字面量或常量

Map 模式始终是开放的：未匹配的键会被静默忽略，并且需要添加 .. 以显示这一点

Map 模式将编译为高效的代码：每个键最多只会被获取一次

Json 模式
当匹配的值具有类型 Json 时，可以直接使用字面量模式，以及构造函数：

match json {
  { "version": "1.0.0", "import": [..] as imports, .. } => ...
  { "version": Number(i, ..), "import": Array(imports), .. } => ...
  ...
}
守卫条件
模式匹配表达式中的每个分支都可以有一个守卫条件。守卫条件是一个布尔表达式，只有当该条件为真时，对应的分支才会被匹配。如果守卫条件为假，则跳过该分支并尝试下一个分支。例如：

fn guard_cond(x : Int?) -> Int {
  fn f(x : Int) -> Array[Int] {
    [x, x + 42]
  }

  match x {
    Some(a) if f(a) is [0, b] => a + b
    Some(b) => b
    None => -1
  }
}

test {
  assert_eq(guard_cond(None), -1)
  assert_eq(guard_cond(Some(0)), 42)
  assert_eq(guard_cond(Some(1)), 1)
}
注意，在检查所有模式是否都被匹配表达式覆盖时，不会考虑守卫条件。因此，您会看到以下情况的警告：

fn guard_check(x : Int?) -> Unit {
  match x {
    Some(a) if a >= 0 => ()
    Some(a) if a < 0 => ()
    None => ()
  }
}