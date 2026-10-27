/// 工艺评估报告生成模块
/// 汇总几何、破裂、起皱、壁厚、补料、加载推荐，输出可读报告字符串。
/// 该字符串可直接打印（CLI），也可序列化供 WASM / Web 前端展示。
///
/// 设计原则：
///   - 本模块只负责“呈现 (presentation)”，不做任何物理计算。
///   - 全部数值来自 assess 编排层（单一来源），避免与 CLI 各自重算。
///   - 报告正文用“行数组 + join”构造，替代此前的 30 余次字符串拼接链，
///     既可读也避免重复分配。

/// 生成完整工艺评估报告（核心实现，接受参数对象）
pub fn format_report_of(input : ProcessInput) -> String {
  let a = assess(input)
  let material = input.material
  let t = input.t0
  let d = input.d0
  let feed = input.feed
  let db = input.db
  let bulge_len = input.bulge_len
  let w = a.window
  let rec = a.loading

  let lines : Array[String] = [
    "========== 管材液压成形工艺评估报告 ==========",
    "材料: " + material.name,
    "初始外径 D0 = " + d.to_string() + " mm, 壁厚 t0 = " + t.to_string() + " mm",
    "轴向进给 = " + feed.to_string() + " mm, 目标胀形外径 Db = " + db.to_string() + " mm",
    "---------------------------------------------------",
    "[几何]",
    "  径厚比 D0/t0 = " + a.diameter_to_thickness.to_string(),
    "  归一化进给 feed/D0 = " + a.feed_ratio.to_string(),
    "[失效极限]",
    "  破裂上限内压 p_burst = " + a.p_burst.to_string() + " MPa",
    "  起皱下限内压 p_wrinkle = " + a.p_wrinkle.to_string() + " MPa",
    "[成形窗口]",
    "  安全区间 [" + w.p_wrinkle.to_string() + ", " + w.p_burst.to_string() + "] MPa",
    "  可行窗口: " + (if w.feasible { "存在" } else { "不存在" }),
    "  窗口稳健性: " + window_robustness(rec.pressure_margin),
    "[壁厚与补料]",
    "  壁厚减薄率 = " + (a.thickness_reduction * 100.0).to_string() + " %",
    "  胀形后壁厚 tb ≈ " + a.wall_after.to_string() + " mm",
    "  推荐补料量 = " + a.optimal_feed.to_string() + " mm",
    "  实际/推荐补料比 = " + a.feed_adequacy.to_string(),
    "[皱纹分类]",
    "  " + wrinkle_class_label(a.wrinkle_class) + " (进给判据)",
    "  " + wrinkle_class_label(a.wrinkle_class_with_pressure) + " (进给+压力判据)",
    "[加载推荐]",
    "  推荐操作内压 = " + rec.recommended_pressure.to_string() + " MPa",
    "  工艺建议: " + rec.note,
    "[安全系数 @ 推荐内压]",
    "  最小安全系数 = " + a.min_safety_factor.to_string() +
    " (" + safety_grade(a.min_safety_factor) + ")",
    "[参考对比]",
    // “无进给” 是另一个工况 (feed=0)，用于对比说明进给对减薄的抑制作用
    "  壁厚减薄率(无进给) = " +
    (thickness_reduction_ratio(d, db, 0.0, bulge_len) * 100.0).to_string() +
    " % (对比: 进给抑制减薄)",
    "  换算: p_burst = " + mpa_to_bar(a.p_burst).to_string() + " bar, D0 = " +
    mm_to_inch(d).to_string() + " inch",
    "===================================================",
  ]
  lines.join("\n")
}

/// 生成完整工艺评估报告（兼容 6 参数调用，委托给参数对象版本）
pub fn format_report(
  material : TubeMaterial,
  t : Double,
  d : Double,
  feed : Double,
  db : Double,
  bulge_len : Double
) -> String {
  format_report_of(
    ProcessInput::{
      material: material, t0: t, d0: d, feed: feed, db: db, bulge_len: bulge_len,
    },
  )
}

/// 多种内置材料在统一几何下的成形窗口对比表（由材料登记处自动派生）
pub fn format_material_comparison(t : Double, d : Double) -> String {
  let lines : Array[String] = [
    "[材料窗口对比 @ D0=" + d.to_string() + "mm, t0=" + t.to_string() + "mm]",
  ]
  let mats = all_materials()
  let mut i = 0
  while i < mats.length() {
    lines.push(summary_line(mats[i], t, d))
    i = i + 1
  }
  lines.push("===============================================")
  lines.join("\n")
}

/// 单行摘要（便于日志/批量对比）
pub fn summary_line(material : TubeMaterial, t : Double, d : Double) -> String {
  let w = forming_window(material, t, d)
  (material.name + " | D0=" + d.to_string() + " t0=" + t.to_string() +
  " | p_burst=" + w.p_burst.to_string() + " p_wrinkle=" + w.p_wrinkle.to_string() +
  " | feasible=" + (if w.feasible { "Y" } else { "N" }))
}

test "报告包含材料名与破裂压力" {
  let r = format_report(steel_dc04(), 2.0, 60.0, 21.0, 66.0, 100.0)
  assert_eq(r.contains(steel_dc04().name), true)
  assert_eq(r.contains("p_burst"), true)
}

test "单行摘要可生成" {
  let l = summary_line(aluminum_5a02(), 2.0, 60.0)
  assert_eq(l.contains("5A02"), true)
}

test "报告包含补料推荐与安全系数段落" {
  let r = format_report(steel_dc04(), 2.0, 60.0, 21.0, 66.0, 100.0)
  assert_eq(r.contains("推荐补料量"), true)
  assert_eq(r.contains("最小安全系数"), true)
  assert_eq(r.contains("壁厚减薄率"), true)
}

test "参数对象版与6参数版报告内容一致" {
  let input = ProcessInput::{
    material: steel_dc04(), t0: 2.0, d0: 60.0, feed: 21.0, db: 66.0, bulge_len: 100.0,
  }
  assert_eq(
    format_report_of(input),
    format_report(steel_dc04(), 2.0, 60.0, 21.0, 66.0, 100.0),
  )
}

test "材料对比表列出全部内置材料" {
  let table = format_material_comparison(2.0, 60.0)
  let names = material_names()
  let mut i = 0
  while i < names.length() {
    assert_eq(table.contains(names[i]), true)
    i = i + 1
  }
}
