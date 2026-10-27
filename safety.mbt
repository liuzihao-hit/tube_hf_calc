/// 工艺安全系数模块
///
/// 工程上以“安全系数”量化工艺裕度：
///   破裂安全系数  SF_burst = p_burst / p_op   （>1 表示未破裂）
///   起皱安全系数  SF_wrinkle = p_op / p_wrinkle（>1 表示未起皱）
///   p_op 为实际操作内压。两者均 >1 且越大越稳健。
///
/// ⚠️ 安全系数阈值为通用工程经验，具体行业/零件要求请按规范核对。

/// 破裂安全系数 = 破裂上限 / 操作内压
pub fn burst_safety_factor(material : TubeMaterial, t : Double, d : Double, op : Double) -> Double {
  let pb = burst_pressure_of(material, t, d)
  if op <= 0.0 {
    return 0.0
  }
  pb / op
}

/// 起皱安全系数 = 操作内压 / 起皱下限
pub fn wrinkle_safety_factor(material : TubeMaterial, t : Double, d : Double, op : Double) -> Double {
  let pw = wrinkle_pressure_lower_bound(material, t, d)
  if pw <= 0.0 {
    return 0.0
  }
  op / pw
}

/// 综合最小安全系数（取破裂/起皱两者较小值）
pub fn min_safety_factor(material : TubeMaterial, t : Double, d : Double, op : Double) -> Double {
  let sf_b = burst_safety_factor(material, t, d, op)
  let sf_w = wrinkle_safety_factor(material, t, d, op)
  if sf_b <= 0.0 || sf_w <= 0.0 {
    return 0.0
  }
  if sf_b < sf_w {
    sf_b
  } else {
    sf_w
  }
}

/// 安全等级评定
pub fn safety_grade(factor : Double) -> String {
  if factor <= 0.0 {
    "无效(内压或几何异常)"
  } else if factor < 1.0 {
    "危险(超出窗口)"
  } else if factor < 1.2 {
    "临界(裕度不足)"
  } else if factor < 1.5 {
    "合格"
  } else {
    "稳健"
  }
}

test "破裂安全系数随操作压力升高而下降" {
  let sf1 = burst_safety_factor(steel_dc04(), 2.0, 60.0, 6.0)
  let sf2 = burst_safety_factor(steel_dc04(), 2.0, 60.0, 10.0)
  assert_eq(sf1 > sf2, true)
}

test "操作压力在窗口内时双安全系数>1" {
  // p_wrinkle=6, p_burst=12, 取 op=9
  let sf_b = burst_safety_factor(steel_dc04(), 2.0, 60.0, 9.0)
  let sf_w = wrinkle_safety_factor(steel_dc04(), 2.0, 60.0, 9.0)
  assert_eq(sf_b > 1.0 && sf_w > 1.0, true)
}

test "安全等级分级" {
  assert_eq(safety_grade(0.8), "危险(超出窗口)")
  assert_eq(safety_grade(2.0), "稳健")
}

test "安全等级边界: 临界/合格/稳健" {
  assert_eq(safety_grade(1.0), "临界(裕度不足)")
  assert_eq(safety_grade(1.2), "合格")
  assert_eq(safety_grade(1.5), "稳健")
}

test "操作内压非正时安全系数返回0(防除零)" {
  assert_eq(burst_safety_factor(steel_dc04(), 2.0, 60.0, 0.0), 0.0)
  assert_eq(wrinkle_safety_factor(steel_dc04(), 2.0, 60.0, 0.0), 0.0)
}
