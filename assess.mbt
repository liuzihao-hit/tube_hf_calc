/// 工艺评估聚合模块（编排层）
///
/// 将分散在各功能模块（burst / wrinkle / window / feeding / loading / safety）
/// 的单项计算统一编排为一次"评估"，作为报告(report)与命令行入口(main)的
/// 单一数值来源，避免多处重复计算、参数散落。
///
/// 采用的设计模式：
///   - 参数对象 (Parameter Object)：ProcessInput 把 6 个散参数聚为一组，
///     调用方与被调用方都更清晰，新增参数不影响既有签名。
///   - 结果聚合 (Result Aggregate)：ProcessAssessment 一次性承载所有派生量，
///     新增指标只需在此加一个字段并在 assess 中计算一次。
///   - 编排 (Orchestration)：assess 复用各模块既有纯函数，不重复实现物理公式。

/// 工艺输入（参数对象）
///   材料 + 几何 + 工艺参数，作为所有计算的统一入口
pub struct ProcessInput {
  material : TubeMaterial // 管材材料
  t0 : Double             // 初始壁厚 (mm)
  d0 : Double             // 初始外径 (mm)
  feed : Double           // 轴向进给量 (mm)
  db : Double             // 目标胀形外径 (mm)
  bulge_len : Double      // 胀形段长度 (mm)
}

/// 工艺输入构造函数（供外部包使用）
/// 说明：MoonBit 中跨包的 struct 字面量构造受限（被视为只读类型），
/// 因此提供本工厂函数，使外部调用方也能使用 assess / format_report_of。
pub fn process_input(
  material : TubeMaterial,
  t0 : Double,
  d0 : Double,
  feed : Double,
  db : Double,
  bulge_len : Double
) -> ProcessInput {
  ProcessInput::{
    material: material, t0: t0, d0: d0, feed: feed, db: db, bulge_len: bulge_len,
  }
}

/// 工艺评估结果（结果聚合）
///   所有派生量在 assess 中一次性算出，供报告/CLI 直接消费
pub struct ProcessAssessment {
  // 几何
  diameter_to_thickness : Double // 径厚比 D0/t0
  feed_ratio : Double           // 归一化进给 feed/D0
  // 失效极限
  p_burst : Double              // 破裂上限内压 (MPa)
  p_wrinkle : Double            // 起皱下限内压 (MPa)
  window : FormingWindow        // 成形窗口（含可行性）
  // 壁厚与补料
  thickness_reduction : Double  // 壁厚减薄率 (0~1)
  wall_after : Double           // 胀形后壁厚 (mm)
  optimal_feed : Double         // 推荐补料量 (mm)
  feed_adequacy : Double        // 实际/推荐补料比
  // 皱纹分类
  wrinkle_class : WrinkleClass                  // 仅按进给判据
  wrinkle_class_with_pressure : WrinkleClass    // 进给 + 内压双判据
  // 加载推荐
  loading : LoadingRecommendation
  // 安全
  min_safety_factor : Double     // 推荐内压下的最小安全系数
}

/// 编排：计算一次完整评估
/// 复用各模块纯函数，保证数值与各单项函数完全一致（单一来源）
pub fn assess(input : ProcessInput) -> ProcessAssessment {
  let m = input.material
  let t = input.t0
  let d = input.d0
  let feed = input.feed
  let db = input.db
  let bl = input.bulge_len

  let dtr = diameter_to_thickness_ratio(d, t)
  let fr = feeding_ratio(feed, d)
  let pb = burst_pressure_of(m, t, d)
  let pw = wrinkle_pressure_lower_bound(m, t, d)
  let w = forming_window(m, t, d)
  let red = thickness_reduction_ratio(d, db, feed, bl)
  let tb = wall_thickness_after(t, d, db, feed, bl)
  let opt = optimal_feed_estimate(d, db, bl)
  let adq = feed_adequacy(feed, d, db, bl)
  let wc = classify_wrinkle(feed, d)
  // 双判据演示压力：取"起皱下限 + 1 MPa"作为受控内压示例
  let wc_p = classify_wrinkle_with_pressure(feed, d, t, m, pw + 1.0)
  let rec = recommend_loading(m, t, d, feed, db, bl)
  let sf = min_safety_factor(m, t, d, rec.recommended_pressure)

  ProcessAssessment::{
    diameter_to_thickness: dtr,
    feed_ratio: fr,
    p_burst: pb,
    p_wrinkle: pw,
    window: w,
    thickness_reduction: red,
    wall_after: tb,
    optimal_feed: opt,
    feed_adequacy: adq,
    wrinkle_class: wc,
    wrinkle_class_with_pressure: wc_p,
    loading: rec,
    min_safety_factor: sf,
  }
}

test "评估聚合：DC04 60x2 关键量与单项函数一致" {
  let a = assess(
    ProcessInput::{
      material: steel_dc04(), t0: 2.0, d0: 60.0, feed: 40.0, db: 66.0,
      bulge_len: 100.0,
    },
  )
  assert_eq(a.p_burst, 12.0)
  assert_eq(a.p_wrinkle, 6.0)
  assert_eq(a.window.feasible, true)
  assert_eq(
    a.loading.recommended_pressure > 6.0 && a.loading.recommended_pressure < 12.0,
    true,
  )
  // 与直接调用单项函数结果一致（单一来源验证）
  assert_eq(a.p_burst, burst_pressure_of(steel_dc04(), 2.0, 60.0))
  assert_eq(a.wrinkle_class, classify_wrinkle(40.0, 60.0))
}
