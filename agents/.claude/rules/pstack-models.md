# pstack model configuration. One line per role. Delete a line to fall back to the skill default.
# `inherit-parent` or `auto` as a value: the role runs on the parent chat model (omit Task `model`). Alias entries in a panel list still count toward its fan-out.
# defaults: 2
# budget: large (xhigh)
feature, refactoring: opus xhigh
bug-fix: opus xhigh
perf-issue: opus xhigh
hillclimb: opus xhigh
judgment and prose: opus xhigh
hardest tasks: opus max
reflect tooling: opus high
reflect judgment, divergent, synthesizer: opus xhigh
arena runners: opus xhigh, opus high, opus high
arena cross-judge pool: opus xhigh, opus high, opus high
swarm workers: opus high
architect runners: opus xhigh, opus high, opus high
interrogate reviewers: opus xhigh, opus high, opus high
