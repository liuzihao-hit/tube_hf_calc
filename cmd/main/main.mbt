/// 命令行演示：用大一年度项目的实际参数跑一遍完整工艺评估
/// 参数：低碳钢 DC04，外径 60 mm，壁厚 2 mm，左端轴向进给 40 mm，
///       目标胀形外径 66 mm（扩张 10%），胀形段长度 100 mm
fn main {
  let material = @tube_hf_calc.steel_dc04()
  let d = 60.0
  let t = 2.0
  let feed = 40.0
  let db = 66.0
  let bulge_len = 100.0

  println("========== 管材液压成形工艺参数计算 ==========")
  println("材料: " + material.name)
  println("初始外径 D0 = " + d.to_string() + " mm, 壁厚 t0 = " + t.to_string() + " mm")
  println("轴向进给 = " + feed.to_string() + " mm, 目标胀形外径 Db = " + db.to_string() + " mm")
  println("")

  // 1) 几何参数
  println("[几何]")
  println("  径厚比 D0/t0 = " + @tube_hf_calc.diameter_to_thickness_ratio(d, t).to_string())
  println("  归一化进给 feed/D0 = " + @tube_hf_calc.feeding_ratio(feed, d).to_string())
  println("")

  // 2) 破裂极限
  println("[破裂极限]")
  println("  破裂上限内压 p_burst = " + @tube_hf_calc.burst_pressure_of(material, t, d).to_string() + " MPa")
  println("")

  // 3) 起皱下限与皱纹分类
  println("[起皱与皱纹]")
  let p_wrinkle = @tube_hf_calc.wrinkle_pressure_lower_bound(material, t, d)
  println("  起皱下限内压 p_wrinkle = " + p_wrinkle.to_string() + " MPa")
  let wc = @tube_hf_calc.classify_wrinkle(feed, d)
  println("  皱纹分类(进给判据) = " + @tube_hf_calc.wrinkle_class_label(wc))
  let wc_p = @tube_hf_calc.classify_wrinkle_with_pressure(feed, d, t, material, p_wrinkle + 1.0)
  println("  皱纹分类(进给+压力) = " + @tube_hf_calc.wrinkle_class_label(wc_p))
  println("")

  // 4) 成形窗口
  println("[成形窗口]")
  let w = @tube_hf_calc.forming_window(material, t, d)
  println("  安全区间 [p_wrinkle, p_burst] = [" + w.p_wrinkle.to_string() + ", " + w.p_burst.to_string() + "] MPa")
  let feas = if w.feasible { "存在" } else { "不存在" }
  println("  可行窗口: " + feas)
  println("")

  // 5) 壁厚减薄与推荐补料
  println("[壁厚与补料]")
  let red = @tube_hf_calc.thickness_reduction_ratio(d, db, feed, bulge_len)
  println("  壁厚减薄率(进给" + feed.to_string() + "mm) = " + (red * 100.0).to_string() + " %")
  let red0 = @tube_hf_calc.thickness_reduction_ratio(d, db, 0.0, bulge_len)
  println("  壁厚减薄率(无进给)   = " + (red0 * 100.0).to_string() + " %  (对比：进给显著抑制减薄)")
  let tb = @tube_hf_calc.wall_thickness_after(t, d, db, feed, bulge_len)
  println("  胀形后壁厚 tb ≈ " + tb.to_string() + " mm")
  let opt_feed = @tube_hf_calc.optimal_feed_estimate(d, db, bulge_len)
  println("  推荐补料量(几何估算) = " + opt_feed.to_string() + " mm")
  let adq = @tube_hf_calc.feed_adequacy(feed, d, db, bulge_len)
  println("  实际/推荐补料比 = " + adq.to_string() + " (" + (if adq < 1.0 { "不足" } else if adq > 1.3 { "过量" } else { "合适" }) + ")")
  println("")

  // 5.5) 加载推荐与安全系数
  let rec = @tube_hf_calc.recommend_loading(material, t, d, feed, db, bulge_len)
  println("[加载推荐]")
  println("  推荐操作内压 = " + rec.recommended_pressure.to_string() + " MPa")
  println("  窗口稳健性 = " + @tube_hf_calc.window_robustness(rec.pressure_margin))
  println("  工艺建议: " + rec.note)
  let sf = @tube_hf_calc.min_safety_factor(material, t, d, rec.recommended_pressure)
  println("  最小安全系数 = " + sf.to_string() + " (" + @tube_hf_calc.safety_grade(sf) + ")")
  println("")

  // 6) 单位换算示例
  println("[单位换算示例]")
  println("  p_burst = " + @tube_hf_calc.mpa_to_bar(w.p_burst).to_string() + " bar")
  println("  D0 = " + @tube_hf_calc.mm_to_inch(d).to_string() + " inch")
  println("")

  // 7) 内置材料在统一几何下的窗口对比（D0=60, t0=2）
  println("[材料窗口对比 @ D0=60mm, t0=2mm]")
  let mats = @tube_hf_calc.all_materials()
  let mut i = 0
  while i < mats.length() {
    println("  " + @tube_hf_calc.summary_line(mats[i], 2.0, 60.0))
    i = i + 1
  }
  println("===============================================")
}
