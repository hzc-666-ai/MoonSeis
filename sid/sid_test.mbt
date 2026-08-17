///|
test "parse full sid" {
  let s = @sid.parse("FDSN:IU_ANMO_00_B_H_Z").unwrap()
  assert_eq(s.network(), "IU")
  assert_eq(s.station(), "ANMO")
  assert_eq(s.location(), "00")
  assert_eq(s.band(), "B")
  assert_eq(s.source(), "H")
  assert_eq(s.subsource(), "Z")
  assert_eq(s.to_string(), "FDSN:IU_ANMO_00_B_H_Z")
}

///|
test "parse abbreviated forms" {
  assert_eq(@sid.parse("FDSN:IU").unwrap().network(), "IU")
  assert_eq(@sid.parse("FDSN:IU_ANMO").unwrap().station(), "ANMO")
  assert_eq(@sid.parse("FDSN:IU_ANMO_00").unwrap().location(), "00")
}

///|
test "reject invalid sid" {
  assert_true(@sid.parse("IU_ANMO").is_err())
  assert_true(@sid.parse("FDSN:").is_err())
  assert_true(@sid.parse("FDSN:IU__00_B_H_Z").is_err())
  assert_true(@sid.parse("FDSN:IU_ANMO_--_B_H_Z").is_err())
  assert_true(@sid.parse("FDSN:iu_anmo_00_B_H_Z").is_err())
  assert_true(@sid.parse("FDSN:IU_ANMO_00_B_H_Z_").is_err())
}

///|
test "empty location as empty segment" {
  let s = @sid.parse("FDSN:NL_HGN__L_H_Z").unwrap()
  assert_eq(s.location(), "")
  assert_eq(s.to_string(), "FDSN:NL_HGN__L_H_Z")
}
