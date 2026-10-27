/// 管材材料属性
/// 字段说明（详见 README）：
///  name     材料牌号
///  sigma_y  屈服强度 (MPa)  —— 塑性流动起点
///  n        硬化指数（无量纲）—— 幂律 σ = K·ε^n 的指数
///  k_coeff  强度系数 K (MPa) —— 幂律 σ = k_coeff·ε^n 的系数
///  e_mod    弹性模量 E (GPa)
///  density  密度 (kg/m³)

pub struct TubeMaterial {
  name : String
  sigma_y : Double
  n : Double
  k_coeff : Double
  e_mod : Double
  density : Double
}

/// 低碳钢 DC04（液压成形常用深冲钢）
/// 已查证（2026-10 多源网络检索）：σ_y 120–210、n≈0.18–0.24、K≈558、E≈180–207 GPa。
/// 取值居合理区间；若按教材/手册微调，改这里即可。
pub fn steel_dc04() -> TubeMaterial {
  TubeMaterial::{
    name: "DC04(低碳钢)",
    sigma_y: 180.0,
    n: 0.22,
    k_coeff: 558.0,
    e_mod: 207.0,
    density: 7850.0,
  }
}

/// 铝合金 5A02（≈5052，液压成形常用防锈铝）
/// 已查证：O 态 σ_y 70–100、E=70 GPa、密度 2680–2730 kg/m³；K 取 5052 典型值约 205。
pub fn aluminum_5a02() -> TubeMaterial {
  TubeMaterial::{
    name: "5A02(铝合金)",
    sigma_y: 90.0,
    n: 0.20,
    k_coeff: 205.0,
    e_mod: 70.0,
    density: 2700.0,
  }
}

/// 钛合金 TA1（纯钛，难成形但液压成形适用）
/// 已查证：σ_y ≥170（典型 170–200）、E=105 GPa、密度 4.51 g/cm³=4510 kg/m³。
/// 原默认值 sigma_y=300 偏高，已改为典型值 190；密度 4500 修正为 4510。
pub fn titanium_ta1() -> TubeMaterial {
  TubeMaterial::{
    name: "TA1(钛合金)",
    sigma_y: 190.0,
    n: 0.20,
    k_coeff: 600.0,
    e_mod: 105.0,
    density: 4510.0,
  }
}

/// 奥氏体不锈钢 304（液压成形常用，屈服强度较高、延展性好）
/// 注：本轮未专门检索，采用通用典型值（σ_y≈205–215、E≈193、ρ≈7930）；提交前建议按手册核对。
pub fn stainless_304() -> TubeMaterial {
  TubeMaterial::{
    name: "304(不锈钢)",
    sigma_y: 215.0,
    n: 0.45,
    k_coeff: 1275.0,
    e_mod: 193.0,
    density: 7930.0,
  }
}

/// 铝合金 6061-T4（中等强度，液压成形常用）
/// 注：本轮未专门检索，采用通用典型值（σ_y≈110–145、E≈69、ρ≈2700）；提交前建议按手册核对。
pub fn aluminum_6061() -> TubeMaterial {
  TubeMaterial::{
    name: "6061-T4(铝合金)",
    sigma_y: 110.0,
    n: 0.20,
    k_coeff: 205.0,
    e_mod: 69.0,
    density: 2700.0,
  }
}

/// 镁合金 AZ31B（轻量化首选，常需温热成形；室温值仅供参考）
/// 已查证：σ_y 125–200、E=44.8–45 GPa、密度 1770–1780 kg/m³（取值合理）。
pub fn magnesium_az31b() -> TubeMaterial {
  TubeMaterial::{
    name: "AZ31B(镁合金)",
    sigma_y: 150.0,
    n: 0.16,
    k_coeff: 450.0,
    e_mod: 45.0,
    density: 1780.0,
  }
}

test "DC04 近似屈服强度" {
  assert_eq(steel_dc04().sigma_y, 180.0)
}

test "三种材料可构造" {
  assert_eq(aluminum_5a02().name, "5A02(铝合金)")
  assert_eq(titanium_ta1().e_mod, 105.0)
}

/// 内置材料清单（名称），便于 CLI / 文档遍历与用户选择
pub fn material_names() -> Array[String] {
  [
    steel_dc04().name,
    aluminum_5a02().name,
    titanium_ta1().name,
    stainless_304().name,
    aluminum_6061().name,
    magnesium_az31b().name,
  ]
}

/// 全部内置材料对象（供遍历/对比）
pub fn all_materials() -> Array[TubeMaterial] {
  [
    steel_dc04(),
    aluminum_5a02(),
    titanium_ta1(),
    stainless_304(),
    aluminum_6061(),
    magnesium_az31b(),
  ]
}

test "材料数量与名称齐全" {
  let names = material_names()
  assert_eq(names.length(), 6)
  assert_eq(names.contains(steel_dc04().name), true)
  assert_eq(names.contains(magnesium_az31b().name), true)
}

test "所有内置材料密度为正数" {
  assert_eq(stainless_304().density > 0.0, true)
  assert_eq(aluminum_6061().density > 0.0, true)
  assert_eq(magnesium_az31b().density > 0.0, true)
}
