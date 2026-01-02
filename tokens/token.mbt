///|
pub(all) enum TokenKind {
  // Literals
  NumericLiteral
  StringLiteral
  BooleanLiteral
  NullLiteral
  RegularExpressionLiteral
  TemplateLiteral

  // Identifiers and Keywords
  Identifier
  Break
  Case
  Catch
  Class
  Const
  Continue
  Debugger
  Default
  Delete
  Do
  Else
  Export
  Extends
  Finally
  For
  Function
  If
  Import
  In
  Instanceof
  Let
  New
  Return
  Super
  Switch
  This
  Throw
  Try
  Typeof
  Var
  Void
  While
  With
  Yield
  Async
  Await
  Enum
  Implements
  Interface
  Package
  Private
  Protected
  Public
  Static

  // Punctuation
  /// (
  LParen
  /// )
  RParen
  /// {
  LBrace
  /// }
  RBrace
  /// [
  LBracket
  /// ]
  RBracket
  /// ;
  Semicolon
  /// ,
  Comma
  /// .
  Dot
  /// :
  Colon
  /// ?
  QuestionMark
  /// ...
  Ellipsis

  // Operators
  /// +
  Plus
  /// -
  Minus
  /// *
  Star
  /// /
  Slash
  /// %
  Percent
  /// ++
  PlusPlus
  /// --
  MinusMinus
  /// =
  Equal
  /// +=
  PlusEqual
  /// -=
  MinusEqual
  /// *=
  StarEqual
  /// /=
  SlashEqual
  /// %=
  PercentEqual
  /// ==
  EqualEqual
  /// !=
  ExclamationEqual
  /// ===
  EqualEqualEqual
  /// !==
  ExclamationEqualEqual
  /// <
  LessThan
  /// <=
  LessThanOrEqual
  /// >
  GreaterThan
  /// >=
  GreaterThanOrEqual
  /// !
  Exclamation
  /// ~
  Tilde
  /// &
  Ampersand
  /// |
  Pipe
  /// ^
  Caret
  /// <<
  LeftShift
  /// >>
  RightShift
  /// >>>
  UnsignedRightShift
  /// &=
  AmpersandEqual
  /// |=
  PipeEqual
  /// ^=
  CaretEqual
  /// <<=
  LeftShiftEqual
  /// >>=
  RightShiftEqual
  /// >>>=
  UnsignedRightShiftEqual
  /// **
  StarStar
  /// **=
  StarStarEqual
  /// =>
  Arrow
  /// ??
  QuestionQuestion
  /// &&
  AmpersandAmpersand
  /// ||
  BarBar
  /// Illegal
  Illegal
  /// ?
  Question

  // Other
  /// EOF
  EndOfFile
  /// Whitespace
  Whitespace
  /// LineTerminator
  LineTerminator
  /// Comment
  Comment
  /// Template
  Template
  /// TemplateHead
  TemplateHead
  /// TemplateMiddle
  TemplateMiddle
  /// TemplateTail
  TemplateTail
} derive(Show, Eq, ToJson, FromJson)

///|
pub fn TokenKind::is_keyword(self : TokenKind) -> Bool {
  self
  is (Break
  | Case
  | Catch
  | Class
  | Const
  | Continue
  | Debugger
  | Default
  | Delete
  | Do
  | Else
  | Export
  | Extends
  | Finally
  | For
  | Function
  | If
  | Import
  | In
  | Instanceof
  | Let
  | New
  | Return
  | Super
  | Switch
  | This
  | Throw
  | Try
  | Typeof
  | Var
  | Void
  | While
  | With
  | Yield
  | Async
  | Await
  | Enum
  | Implements
  | Interface
  | Package
  | Private
  | Protected
  | Public
  | Static)
}
