/// 工艺评估报告生成模块
/// 汇总几何、破裂、起皱、壁厚、补料、加载推荐，输出可读报告字符串。
/// 该字符串可直接打印（CLI），也可序列化供 WASM / Web 前端展示。

/// 生成完整工艺评估报告
pub fn format_report(
  material : TubeMaterial,
  t : Double,
  d : Double,
  feed : Double,
  db : Double,
  bulge_len : Double
) -> String {
  let dr = diameter_to_thickness_ratio(d, t)
  let fr = feeding_ratio(feed, d)
  let pb = burst_pressure_of(material, t, d)
  let pw = wrinkle_pressure_lower_bound(material, t, d)
  let w = forming_window(material, t, d)
  let red = thickness_reduction_ratio(d, db, feed, bulge_len)
  let tb = wall_thickness_after(t, d, db, feed, bulge_len)
  let opt = optimal_feed_estimate(d, db, bulge_len)
  let adq = feed_adequacy(feed, d, db, bulge_len)
  let wc = classify_wrinkle(feed, d)
  let rec = recommend_loading(material, t, d, feed, db, bulge_len)

  let mut s = "========== 管材液压成形工艺评估报告 =========="
  s = s + "\n材料: " + material.name
  s = s + "\n初始外径 D0 = " + d.to_string() + " mm, 壁厚 t0 = " + t.to_string() + " mm"
  s = s + "\n轴向进给 = " + feed.to_string() + " mm, 目标胀形外径 Db = " + db.to_string() + " mm"
  s = s + "\n---------------------------------------------------"
  s = s + "\n[几何]"
  s = s + "\n  径厚比 D0/t0 = " + dr.to_string()
  s = s + "\n  归一化进给 feed/D0 = " + fr.to_string()
  s = s + "\n[失效极限]"
  s = s + "\n  破裂上限内压 p_burst = " + pb.to_string() + " MPa"
  s = s + "\n  起皱下限内压 p_wrinkle = " + pw.to_string() + " MPa"
  s = s + "\n[成形窗口]"
  s = s + "\n  安全区间 [" + w.p_wrinkle.to_string() + ", " + w.p_burst.to_string() + "] MPa"
  s = s + "\n  可行窗口: " + (if w.feasible { "存在" } else { "不存在" })
  s = s + "\n  窗口稳健性: " + window_robustness(rec.pressure_margin)
  s = s + "\n[壁厚与补料]"
  s = s + "\n  壁厚减薄率 = " + (red * 100.0).to_string() + " %"
  s = s + "\n  胀形后壁厚 tb ≈ " + tb.to_string() + " mm"
  s = s + "\n  推荐补料量 = " + opt.to_string() + " mm"
  s = s + "\n  实际/推荐补料比 = " + adq.to_string()
  s = s + "\n[皱纹分类]"
  s = s + "\n  " + wrinkle_class_label(wc)
  s = s + "\n[加载推荐]"
  s = s + "\n  推荐操作内压 = " + rec.recommended_pressure.to_string() + " MPa"
  s = s + "\n  工艺建议: " + rec.note
  s = s + "\n[安全系数 @ 推荐内压]"
  let sf = min_safety_factor(material, t, d, rec.recommended_pressure)
  s = s + "\n  最小安全系数 = " + sf.to_string() + " (" + safety_grade(sf) + ")"
  s = s + "\n==================================================="
  s
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
