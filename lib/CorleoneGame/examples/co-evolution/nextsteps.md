# Co-evolution project: next steps

Editable working document. Edit, reorder, delete, or annotate items; mark decisions
with `DECISION:` and questions to Claude with `Q:`. Claude reads this file as input
for the continuation of the project. Status markers: [ ] open, [x] done, [-] dropped.

## 0. Current state (2026-10-05)

- [x] Literature survey: `literature.md` (verified references; open items marked [VERIFY]).
- [x] First example: `simple.jl` (who-adapts-to-whom game, design of the implant's
      mismatch weight μ, two starts per design); results in `output/` (design_scan.csv,
      trajectories, controls, simple.png); report `report/report.pdf` (sent 2026-10-05).
- Main finding of the first example: the sincere implant (μ = 1, same objective as the
  designer) is exploited; the body free-rides on its accommodation. The designed implant
  that ignores the mismatch (μ = 0) leads the body to health and ends with *less* total
  designer cost, although the designer values integration. This is the commitment
  effect of strategic delegation, here in a dynamic co-adaptation game.
- Python prototypes (scratch, not in the repository) tested and rejected:
  (A) additive LQ model with implant compliance β as design: β only weakens the implant,
  the outer optimum is trivial or numerically fragile (open-loop LQ Nash may not exist);
  (B) implant that can only yield (u_P ≥ 0): cannot lead, best Φ ≈ 0.5;
  (C) terminal-cost-only variant: best-response iteration oscillates.

DECISION (terminology): keep "co-evolution" or switch to "co-adaptation"? (Biology uses
co-evolution for genetic change across generations.)

## 1. Make the first example solid

- [ ] Equilibrium multiplicity / grid dependence: for μ = 0.5 and μ = 2 the 20-interval
      grid gives certified candidates with Φ = 3.97 and 6.05 (`checks/grid20_2026-10-05.txt`),
      the 40-interval refinement gives 5.32 (not certified) and 7.20 (certified). Clarify:
      several equilibria, or different selection by the refinement start? Run from many
      starts on both grids; consider continuation in μ.
- [ ] μ = 0.25 does not converge (best-response cycling) with damping 0.2 and 300 rounds;
      try smaller damping or a different response order.
- [ ] Continuous design curve: finer μ grid incl. μ in (0, 0.25); check whether the
      optimum is at the boundary μ = 0 for other parameter sets (w_s, c_B, c_P, T).
- [ ] Second design variable: implant initial setting p0 (the user's "controls as
      initial values"); 2-D design map Φ(μ, p0).
- [ ] Robustness: is the designed μ* still good if the body's w_s or c_B differ from
      the designer's assumption? (motivates dual control, Section 4)
- [ ] Multistart audit of the equilibria (extra starts), uniqueness check; compare
      equilibrium selection for μ near the switch where u_P changes sign.
- [ ] Compare with Stackelberg: designer/implant as leader with the body's best
      response (bilevel OCP); does the delegated Nash design with μ* reach the
      Stackelberg value? (delegation theory says it can, with enough design freedom)

## 2. Richer adaptation mechanisms of the implant (the actual design object)

- [ ] Parametrized adaptation laws instead of objective weights, e.g.,
      p' = β (b - p) + γ (h - p) with designed (β, γ), possibly time-varying β(t):
      implant then is not a player but a designed dynamical law; the body is the only
      optimizer (single OCP per design) -- compare with the game version.
- [ ] Feedback (closed-loop) implant policies p' = κ(b, p; θ) instead of open-loop
      controls: the body then plays against a reactive implant; open-loop vs feedback
      Nash differ (Başar and Olsder).
- [ ] Learning-rate design as in the BMI literature (Madduri et al.): implant adapts
      by gradient steps on its own objective with designed rate; relate to our μ design.

## 3. Biologically grounded instances

Q: Which application first? Candidates:
- [ ] Bone implant and stress shielding: implant stiffness adapts, bone density adapts
      to load (Wolff's law); healthy = target bone density.
- [ ] Closed-loop neuromodulation (deep brain stimulation) with neural plasticity.
- [ ] Artificial pancreas: controller adapts while insulin sensitivity adapts.
- [ ] Tolerance/rejection: body attacks the implant if mismatch exceeds a threshold
      (path constraint |p - b| <= δ, generalized Nash); implant must "pace and lead".

## 4. Unknown body: inverse games and dual control

- [ ] Calibrate the body's objective weights from (synthetic) data by inverse games
      (link to the inverse-game use of the library paper).
- [ ] Implant that learns the body's parameters while steering (dual effect: probing
      vs. steering), e.g., two-scenario robust design over w_s.

## 5. Numerics and software

- [ ] Outer optimization over designs by derivative-free search (golden section on μ)
      or by sensitivities of the equilibrium (implicit function theorem on the
      best-response fixed point).
- [ ] Reuse `Workspace` warm starts along the design path (already done in the scan).
- [ ] Decide whether the project gets its own Julia environment or keeps using
      `corleoneproblems/Project.toml`.

## 6. Writing

- [ ] Report `report/report.tex` extended into a short paper: problem class,
      delegation effect, examples, positioning (literature.md).
- [ ] Target venue? Q: e.g., Dynamic Games and Applications, J. Math. Biol., IEEE TBME.
