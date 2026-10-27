/// 成形窗口模块（工具核心）
///
/// 安全内压区间 [p_wrinkle, p_burst]：
///   p_burst = 2·t·σ_y / D  （破裂上限，已实现，见 burst 模块）
///   p_wrinkle = 起皱下限内压（轴向压缩失稳，TODO 待补经验式）
///
/// 当 p_wrinkle < p_burst 时存在可行窗口；否则工艺不可行（必起皱或必破裂）

pub struct FormingWindow {
  p_wrinkle : Double // 起皱下限内压 (MPa)
  p_burst : Double   // 破裂上限内压 (MPa)
  feasible : Bool    // 是否存在可行窗口
}

/// 计算成形窗口
pub fn forming_window(material : TubeMaterial, t : Double, d : Double) -> FormingWindow {
  let p_burst = burst_pressure_of(material, t, d)
  let p_wrinkle = wrinkle_pressure_lower_bound(material, t, d) // 见 wrinkle 模块（已实现）
  let feasible = p_wrinkle < p_burst && p_burst > 0.0
  FormingWindow::{ p_wrinkle: p_wrinkle, p_burst: p_burst, feasible: feasible }
}

test "成形窗口：p_burst 已计算" {
  let w = forming_window(steel_dc04(), 2.0, 60.0)
  assert_eq(w.p_burst, 12.0)
}
