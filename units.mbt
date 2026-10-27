/// 单位换算模块
/// 液压成形常用单位混用（MPa / bar；mm / inch），统一换算便于计算

/// MPa -> bar  (1 MPa = 10 bar)
pub fn mpa_to_bar(p : Double) -> Double { p * 10.0 }

/// bar -> MPa
pub fn bar_to_mpa(p : Double) -> Double { p / 10.0 }

/// mm -> inch  (1 inch = 25.4 mm)
pub fn mm_to_inch(l : Double) -> Double { l / 25.4 }

/// inch -> mm
pub fn inch_to_mm(l : Double) -> Double { l * 25.4 }

/// N -> kN
pub fn n_to_kn(f : Double) -> Double { f / 1000.0 }

/// kN -> N
pub fn kn_to_n(f : Double) -> Double { f * 1000.0 }

test "MPa<->bar" {
  assert_eq(mpa_to_bar(5.0), 50.0)
  assert_eq(bar_to_mpa(50.0), 5.0)
}

test "mm<->inch" {
  assert_eq(mm_to_inch(25.4), 1.0)
  assert_eq(inch_to_mm(1.0), 25.4)
}
