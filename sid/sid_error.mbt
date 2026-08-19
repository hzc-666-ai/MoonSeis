///|
pub(all) struct SidError {
  message : String
  fragment : String
} derive(Eq, Debug)

///|
pub fn SidError::new(message : String, fragment : String) -> SidError {
  { message, fragment }
}

///|
pub fn SidError::message(self : SidError) -> String {
  self.message
}

///|
pub fn SidError::fragment(self : SidError) -> String {
  self.fragment
}

///|
pub fn SidError::to_string(self : SidError) -> String {
  "\{self.message} (\{self.fragment})"
}
