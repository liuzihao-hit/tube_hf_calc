/// 几何参数模块
/// 管材液压成形关键几何量：外径 D、壁厚 t、径厚比 D/t、轴线送料量

/// 径厚比 D/t —— 液压成形最核心的几何参数，越小越难成形
pub fn diameter_to_thickness_ratio(d : Double, t : Double) -> Double {
  if t <= 0.0 {
    return 0.0 // TODO: 处理非法输入，当前占位返回 0
  }
  d / t
}

/// 初始管内体积（圆柱段近似，length 为成形区长度）
pub fn tube_volume(d : Double, t : Double, length : Double) -> Double {
  let r_out = d / 2.0
  let r_in = r_out - t
  let area = 3.141592653589793 * (r_out * r_out - r_in * r_in)
  area * length
}

/// 轴线送料量归一化（相对管径，用于皱纹 / 补料判据）
pub fn feeding_ratio(feed : Double, d : Double) -> Double {
  if d <= 0.0 {
    return 0.0
  }
  feed / d
}

test "径厚比" {
  assert_eq(diameter_to_thickness_ratio(60.0, 2.0), 30.0)
}

test "送料比" {
  assert_eq(feeding_ratio(40.0, 60.0), 40.0 / 60.0)
}
