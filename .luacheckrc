std = "luajit"
globals = {"vim"}

ignore = {
  -- unused loop variable
  "213",
  -- ignore unused test functions
  "[Tt]est[%w_]+",
}
