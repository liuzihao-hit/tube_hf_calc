/// 白盒集成测试：覆盖完整流程（与库同包，可访问全部函数）
test "完整流程：DC04 管 60x2 的破裂压力与几何" {
  let m = @tube_hf_calc.steel_dc04()
  let dr = @tube_hf_calc.diameter_to_thickness_ratio(60.0, 2.0)
  assert_eq(dr, 30.0)
  let pb = @tube_hf_calc.burst_pressure_of(m, 2.0, 60.0)
  assert_eq(pb, 12.0)
  let w = @tube_hf_calc.forming_window(m, 2.0, 60.0)
  assert_eq(w.p_burst, 12.0)
}

test "单位换算链路可逆" {
  assert_eq(@tube_hf_calc.mpa_to_bar(@tube_hf_calc.bar_to_mpa(5.0)), 5.0)
}
