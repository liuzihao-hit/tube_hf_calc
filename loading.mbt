/// 压力加载路径与工艺推荐模块
///
/// 液压成形成败的关键在于“内压—轴向进给”加载路径的匹配：
///   阶段一（起皱/补料阶段）：相对低压 + 较高进给，可引入有益皱纹、储料；
///   阶段二（胀形阶段）：提高内压使皱纹熨平、贴模；
///   阶段三（校准阶段）：高压定形，但需低于破裂上限。
/// 本模块基于已实现的破裂/起皱窗口，给出推荐操作压力与安全裕度。
///
/// ⚠️ 推荐值为窗口内的经验取点，非最优加载曲线；精确路径需 FEA/试验标定。

/// 加载工艺推荐结果
pub struct LoadingRecommendation {
  feasible : Bool      // 是否存在可行窗口
  recommended_pressure : Double // 推荐操作内压 (MPa)
  pressure_margin : Double      // 窗口相对宽度 (p_burst-p_wrinkle)/p_burst
  recommended_feed : Double     // 推荐补料量 (mm)
  feed_adequacy : Double        // 实际/推荐补料比
  note : String                 // 工艺说明
}

/// 推荐加载工艺
///   material     管材材料
///   t, d         壁厚 / 初始外径 (mm)
///   feed_target  实际/目标轴向进给 (mm)
///   db, bulge_len 胀形目标外径 / 胀形段长度 (mm)
pub fn recommend_loading(
  material : TubeMaterial,
  t : Double,
  d : Double,
  feed_target : Double,
  db : Double,
  bulge_len : Double
) -> LoadingRecommendation {
  let w = forming_window(material, t, d)
  let p_margin = if w.p_burst > 0.0 { (w.p_burst - w.p_wrinkle) / w.p_burst } else { 0.0 }
  let rec_pressure = if w.feasible { w.p_wrinkle + 0.2 * (w.p_burst - w.p_wrinkle) } else { 0.0 }
  let opt_feed = optimal_feed_estimate(d, db, bulge_len)
  let adq = feed_adequacy(feed_target, d, db, bulge_len)
  let note =
    if !w.feasible {
      "⚠️ 当前参数下起皱下限 ≥ 破裂上限，无可行窗口；多为经验系数偏高或几何不适，请核对系数/几何。"
    } else if adq < 1.0 {
      "补料偏少：建议增大轴向进给至推荐值附近，以抑制破裂、诱导有益皱纹。"
    } else if adq > 1.3 {
      "补料偏多：注意过度皱纹/折叠风险，可适当降低进给或提高内压熨平。"
    } else {
      "补料与内压匹配良好：按“低压高进给→增压熨平→高压校准”路径执行。"
    }
  LoadingRecommendation::{
    feasible: w.feasible,
    recommended_pressure: rec_pressure,
    pressure_margin: p_margin,
    recommended_feed: opt_feed,
    feed_adequacy: adq,
    note: note,
  }
}

/// 窗口相对宽度分级（用于快速评估工艺稳健性）
pub fn window_robustness(margin : Double) -> String {
  if margin <= 0.0 {
    "无窗口"
  } else if margin < 0.2 {
    "窄窗口(敏感)"
  } else if margin < 0.5 {
    "中等窗口"
  } else {
    "宽窗口(稳健)"
  }
}

test "可行窗口下推荐压力落在窗口内" {
  let rec = recommend_loading(steel_dc04(), 2.0, 60.0, 21.0, 66.0, 100.0)
  assert_eq(rec.feasible, true)
  assert_eq(rec.recommended_pressure > 6.0 && rec.recommended_pressure < 12.0, true)
}

test "窗口稳健性分级" {
  assert_eq(window_robustness(0.0), "无窗口")
  assert_eq(window_robustness(0.6), "宽窗口(稳健)")
}
