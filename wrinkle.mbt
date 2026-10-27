/// 起皱极限与皱纹分类模块
///
/// 液压成形两大失效模式之一：起皱（另一为破裂，见 burst 模块）。
/// 起皱本质是轴向受压失稳：当内压不足以“撑住”管坯、轴向进给又过大时，
/// 管端/导向区出现轴向压缩皱褶。
///
/// 文献依据：
///  [1] Yuan et al. (2003) 提出“有益皱纹 (useful/beneficial wrinkle)”概念：
///      受控的适度皱纹可储存材料、抑制破裂、提高成形极限；只有失稳性
///      大皱褶或补料不足导致的皱纹才是缺陷。本工具据此做有益/有害分类。
///  [2] Bogojavlenski & Serjakow 给出 T 型接头防皱最小内压经验关联式
///      P_min = (0.13 + 1.15·t0/Dp)·σ_Y（见本文件末尾注释，供对照）。
///
/// 起皱下限内压模型（本工具默认采用）：
///   薄壁管轴向受压失稳的临界内压在量纲上满足 p_wrinkle ~ σ_y·(t/D)·α，
///   其中 α 为经验形状因子（无量纲）。该式与薄膜应力关系 p = 2tσ/D 同量级，
///   物理上表示“内压需提供的环向约束以抑制轴向屈曲”。
///   ⚠️ α 为可调经验系数，默认 1.0；直管/非对称轴线送料工况请在
///      《现代液压成形技术》相关章节核对后调整 WRINKLE_SHAPE_FACTOR。

/// 起皱下限内压经验形状因子（无量纲，待按教材核对调整）
pub let wrinkle_shape_factor : Double = 1.0

/// 起皱下限内压（经验估计，单位 MPa）
/// 公式 p_wrinkle = α · σ_y · (t / D)，α = wrinkle_shape_factor
pub fn wrinkle_pressure_lower_bound(material : TubeMaterial, t : Double, d : Double) -> Double {
  if d <= 0.0 {
    return 0.0
  }
  wrinkle_shape_factor * material.sigma_y * (t / d)
}

/// 皱纹分类结果
pub enum WrinkleClass {
  Beneficial // 有益皱纹：受控适度，利于补料与抑制破裂
  Harmful    // 有害皱纹：补料不足导致失稳性大皱褶（缺陷）
  Excessive  // 过度皱纹：补料过量导致折叠/压溃（缺陷）
  None       // 无皱（内压高于起皱下限且进给受控）
} derive(Eq, @debug.Debug)

pub extend WrinkleClass with Eq::{not_equal, equal}
pub extend WrinkleClass with @moonbitlang/core/debug.Debug::{to_repr}

/// 皱纹分类：依据轴向进给比与起皱/破裂窗口判定
///
/// 判据（示意性阈值，必须按《现代液压成形技术》有益皱纹章节与你的
///      ABAQUS 标定结果校准；此处仅作工程快速估计）：
///   feed_ratio = feed / d  （轴向进给相对管径归一化）
///
///   有益皱纹 (Beneficial) 范式（Yuan et al., 2003）：
///     早期“高进给 + 相对低压”有意引入受控皱纹储存材料，后期增压熨平；
///     故适度至较高 feed_ratio 落入有益区间。
///   - feed_ratio < 0.05        几乎无补料，难以形成有益皱纹、易失稳 → Harmful
///   - 0.05 ≤ feed_ratio ≤ 1.0  适度至较高补料 → Beneficial（有益皱纹）
///   - feed_ratio > 1.0         进给超过管径，折叠/压溃风险 → Excessive
///
/// ⚠️ 阈值与有益/有害皱纹的严格界定属于你的课题核心，请务必校准后再用于判断。
pub fn classify_wrinkle(feed : Double, d : Double) -> WrinkleClass {
  let feed_ratio = if d > 0.0 { feed / d } else { 0.0 }
  if feed_ratio < 0.05 {
    Harmful
  } else if feed_ratio > 1.0 {
    Excessive
  } else {
    Beneficial
  }
}

/// 皱纹分类（含内压与起皱下限）：综合进给与压力双判据
/// 当内压高于起皱下限且进给落在有益区间，视为受控无皱或有益皱纹；
/// 当内压低于起皱下限（失稳）且进给不足，判为有害皱纹。
pub fn classify_wrinkle_with_pressure(
  feed : Double,
  d : Double,
  t : Double,
  material : TubeMaterial,
  pressure : Double
) -> WrinkleClass {
  let p_wrinkle = wrinkle_pressure_lower_bound(material, t, d)
  let base = classify_wrinkle(feed, d)
  if pressure >= p_wrinkle {
    // 内压足以抑制失稳：即便进给适中也不致起皱
    if base == Beneficial {
      None
    } else {
      base
    }
  } else {
    // 内压低于起皱下限：处于失稳区
    if base == Harmful {
      Harmful
    } else if base == Excessive {
      Excessive
    } else {
      Beneficial // 内压低但进给适度，形成受控有益皱纹
    }
  }
}

/// 皱纹分类结果转中文标签（用于报告输出）
pub fn wrinkle_class_label(c : WrinkleClass) -> String {
  match c {
    Beneficial => "有益皱纹"
    Harmful => "有害皱纹"
    Excessive => "过度皱纹(折叠)"
    None => "无皱(受控)"
  }
}

test "起皱下限内压随径厚比增大而降低" {
  let m = steel_dc04()
  // t/D 越小（薄壁）越易起皱 → 下限内压越低
  let low = wrinkle_pressure_lower_bound(m, 1.0, 60.0)
  let high = wrinkle_pressure_lower_bound(m, 4.0, 60.0)
  assert_eq(low < high, true)
}

test "起皱下限内压正值且依赖屈服强度" {
  let p_dc04 = wrinkle_pressure_lower_bound(steel_dc04(), 2.0, 60.0)
  let p_al = wrinkle_pressure_lower_bound(aluminum_5a02(), 2.0, 60.0)
  assert_eq(p_dc04 > 0.0, true)
  assert_eq(p_dc04 > p_al, true) // DC04 屈服强度更高 → 下限更高
}

test "皱纹分类：补料不足为有害" {
  assert_eq(classify_wrinkle(2.0, 60.0), Harmful)
}

test "皱纹分类：适度补料为有益" {
  assert_eq(classify_wrinkle(30.0, 60.0), Beneficial)
}

test "皱纹分类：补料过量为过度" {
  assert_eq(classify_wrinkle(70.0, 60.0), Excessive)
}

test "标签映射正确" {
  assert_eq(wrinkle_class_label(Beneficial), "有益皱纹")
  assert_eq(wrinkle_class_label(Harmful), "有害皱纹")
  assert_eq(wrinkle_class_label(Excessive), "过度皱纹(折叠)")
  assert_eq(wrinkle_class_label(None), "无皱(受控)")
}
