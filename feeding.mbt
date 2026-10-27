/// 轴向进给、壁厚减薄与推荐补料模块
///
/// 设计依据（理论推导，可手算核对）：
///  塑性体积守恒：ε_c + ε_a + ε_t = 0
///    ε_c 周向应变 = ln(D_b / D_0)        （胀形扩张）
///    ε_a 轴向应变 = -feed / L_0          （轴向进给为压缩，取负）
///    ε_t 厚向应变 = -(ε_c + ε_a)
///  壁厚减薄率 = 1 - exp(ε_t)
///    · 无轴向进给(feed=0)：ε_t = -ε_c → 减薄率 = 1 - D_0/D_b（纯胀形最严重）
///    · 有轴向进给：ε_a<0 抵消部分 ε_c，减薄率下降（补料抑制破裂）
///  推荐补料量（几何体积守恒，假设壁厚不变）：
///    胀形段由 D_0 扩至 D_b、长度 L_b 所需体积 ΔV = π/4·(D_b²-D_0²)·L_b
///    该体积由轴向进给经管截面 π/4·D_0² 补入 → feed = ((D_b/D_0)²-1)·L_b
///
/// ⚠️ 上述为工程简化模型；精确值依赖材料硬化、摩擦与模具约束，
///    提交前结合《现代液压成形技术》相关章节核对。

/// 壁厚减薄率（0~1 之间，0 表示无减薄）
///   d0       初始外径 (mm)
///   db       胀形后外径 (mm)
///   feed     轴向进给量 (mm)
///   length   管坯成形区初始长度 (mm)
pub fn thickness_reduction_ratio(d0 : Double, db : Double, feed : Double, length : Double) -> Double {
  if d0 <= 0.0 || db <= 0.0 || length <= 0.0 {
    return 0.0
  }
  let eps_c = @math.ln(db / d0)        // 周向应变（拉）
  let eps_a = -(feed / length)        // 轴向应变（压，进给取负）
  let eps_t = -(eps_c + eps_a)        // 厚向应变（体积守恒）
  let t_ratio = 1.0 - @math.exp(eps_t) // 减薄率 = 1 - t/t0
  if t_ratio < 0.0 {
    0.0
  } else if t_ratio > 1.0 {
    1.0
  } else {
    t_ratio
  }
}

/// 胀形后壁厚估算（mm）：t_b = t0·exp(ε_t)
pub fn wall_thickness_after(t0 : Double, d0 : Double, db : Double, feed : Double, length : Double) -> Double {
  if d0 <= 0.0 || db <= 0.0 || length <= 0.0 {
    return 0.0
  }
  let eps_c = @math.ln(db / d0)
  let eps_a = -(feed / length)
  let eps_t = -(eps_c + eps_a)
  t0 * @math.exp(eps_t)
}

/// 推荐补料量（几何体积守恒估算，mm）
///   d0           初始外径 (mm)
///   db           胀形目标外径 (mm)
///   bulge_length 胀形段长度 (mm)
/// 返回为保持壁厚不变填满胀形段所需的轴向进给量。
pub fn optimal_feed_estimate(d0 : Double, db : Double, bulge_length : Double) -> Double {
  if d0 <= 0.0 || db <= 0.0 {
    return 0.0
  }
  let ratio = db / d0
  (ratio * ratio - 1.0) * bulge_length
}

/// 补料充分性评估：实际进给相对推荐补料的占比（<1 不足，≈1 合适，>1 过量）
pub fn feed_adequacy(feed : Double, d0 : Double, db : Double, bulge_length : Double) -> Double {
  let opt = optimal_feed_estimate(d0, db, bulge_length)
  if opt <= 0.0 {
    0.0
  } else {
    feed / opt
  }
}

test "无补料时减薄率 = 1 - D0/Db" {
  // D0=60, Db=72 → 1 - 60/72 = 0.1667
  let r = thickness_reduction_ratio(60.0, 72.0, 0.0, 200.0)
  assert_eq((r - (1.0 - 60.0 / 72.0)).abs() < 1.0e-9, true)
}

test "补料减小减薄率" {
  let no_feed = thickness_reduction_ratio(60.0, 72.0, 0.0, 200.0)
  let with_feed = thickness_reduction_ratio(60.0, 72.0, 30.0, 200.0)
  assert_eq(with_feed < no_feed, true)
}

test "推荐补料量为正且随胀形增大" {
  let small = optimal_feed_estimate(60.0, 66.0, 100.0)
  let large = optimal_feed_estimate(60.0, 90.0, 100.0)
  assert_eq(small > 0.0 && large > small, true)
}

test "补料充分性: 实际=推荐 时约为 1" {
  let opt = optimal_feed_estimate(60.0, 80.0, 100.0)
  let adq = feed_adequacy(opt, 60.0, 80.0, 100.0)
  assert_eq((adq - 1.0).abs() < 1.0e-9, true)
}
