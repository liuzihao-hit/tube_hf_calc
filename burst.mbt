/// 破裂极限内压模块
///
/// 薄膜理论（Tresca 屈服准则）：
///   管材环向应力 σ_θ = p·D / (2t)
///   破裂条件 σ_θ ≥ σ_y  →  p_burst = 2·t·σ_y / D
///
/// 量纲核对：p_burst[MPa] = 2·t[mm]·σ_y[MPa] / D[mm]  →  mm·MPa/mm = MPa  ✓

/// 破裂极限内压（已知屈服强度）
pub fn burst_pressure(t : Double, sigma_y : Double, d : Double) -> Double {
  if d <= 0.0 {
    return 0.0
  }
  2.0 * t * sigma_y / d
}

/// 给定材料，计算破裂极限内压
pub fn burst_pressure_of(material : TubeMaterial, t : Double, d : Double) -> Double {
  burst_pressure(t, material.sigma_y, d)
}

test "破裂极限内压：DC04 t=2 D=60" {
  // p_b = 2*2*180/60 = 12 MPa
  assert_eq(burst_pressure(2.0, 180.0, 60.0), 12.0)
}

test "破裂极限内压随壁厚增大而升高" {
  assert_eq(
    burst_pressure(3.0, 180.0, 60.0) > burst_pressure(2.0, 180.0, 60.0),
    true,
  )
}
