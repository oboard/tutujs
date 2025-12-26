// --- Token Definition ---

///|
enum TokenKind {
  EOF
  Identifier(String)
  StringLiteral(String)
  Number(String)
  // Keywords
  Function
  Return
  Let
  Var
  Const
  If
  Else
  // Punctuation
  Assign
  Semi
  LParen
  RParen
  LBrace
  RBrace
  Comma
  Dot
  Plus
  Minus
  Star
  Slash
} derive(Show, Eq, ToJson, FromJson)
