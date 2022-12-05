" Initialize module

if exists("g:loaded_gh_co")
  finish
endif

lua require("gh-co").init()

let g:loaded_gh_co = 1
