/// 命令行演示：用大一年度项目的实际参数跑一遍完整工艺评估
/// 参数：低碳钢 DC04，外径 60 mm，壁厚 2 mm，左端轴向进给 40 mm，
///       目标胀形外径 66 mm（扩张 10%），胀形段长度 100 mm
///
/// 设计原则：
///   本入口只做“组装输入 + 委托输出”，不重复实现任何报告章节。
///   计算由 assess 编排层完成，格式化由 report 模块完成，
///   此前此处手工重印各章节的冗余逻辑已全部移除。
fn main {
  // 构造参数对象（参数模式），一次组装、处处复用
  let input = @tube_hf_calc.process_input(
    @tube_hf_calc.steel_dc04(), 2.0, 60.0, 40.0, 66.0, 100.0,
  )

  // 主报告（含几何/极限/窗口/壁厚补料/皱纹/加载/安全系数/参考对比）
  println(@tube_hf_calc.format_report_of(input))
  println("")

  // 全部内置材料在统一几何 (D0=60, t0=2) 下的窗口对比
  println(@tube_hf_calc.format_material_comparison(2.0, 60.0))
}
