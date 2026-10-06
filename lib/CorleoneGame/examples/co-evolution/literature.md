# Literature survey: co-evolution of an adaptive body and a designed adaptive implant

Status: 2026-10-05, first survey by web search. All references below were checked
for authors, title, venue, and year (DOI where given) against publisher or
indexing pages; contents are summarized from abstracts and publisher summaries,
not from full-text reading unless stated. Items marked [VERIFY] need a full-text check.

## Research question in one sentence

Two adaptive agents (body B, implant P) co-adapt to an equilibrium; the designer
cannot act on the body and does not prescribe the implant's actions, but designs
the implant's *adaptation mechanism* (objective, adaptation law, rates) so that the
equilibrium reached by the coupled system is as close as possible to a desired
("healthy") state. Short: **control of adaptation** rather than adaptive control.

## A. Two-learner problem and co-adaptation in neural and body-machine interfaces

- Perdikis, S., Millán, J. d. R. (2020). Brain-machine interfaces: A tale of two
  learners. *IEEE Systems, Man, and Cybernetics Magazine* 6(3), 12-19.
  doi:10.1109/MSMC.2019.2958200. Mutual learning of user and decoder; argues the field
  is biased to the machine-learning side.
- DiGiovanna, J., Mahmoudi, B., Fortes, J., Principe, J. C., Sanchez, J. C. (2009).
  Coadaptive brain-machine interface via reinforcement learning. *IEEE Trans. Biomed.
  Eng.* 56(1), 54-64. doi:10.1109/TBME.2008.926699.
- Orsborn, A. L., Moorman, H. G., Overduin, S. A., Shanechi, M. M., Dimitrov, D. F.,
  Carmena, J. M. (2014). Closed-loop decoder adaptation shapes neural plasticity for
  skillful neuroprosthetic control. *Neuron* 82(6), 1380-1393.
  doi:10.1016/j.neuron.2014.04.048.
- De Santis, D. (2021). A framework for optimizing co-adaptation in body-machine
  interfaces. *Frontiers in Neurorobotics* 15. doi:10.3389/fnbot.2021.662181.
  User and interface as co-adapting, non-independent agents.
- Hsieh, H.-L., Shanechi, M. M. (2018). Optimizing the learning rate for adaptive
  estimation of neural encoding models. *PLoS Comput. Biol.* 14(5).
  doi:10.1371/journal.pcbi.1006168. Learning rate chosen for estimation speed and
  accuracy, not for the outcome of a strategic interaction.
- Madduri, M. M., Burden, S. A., Orsborn, A. L. (2021). A game-theoretic model for
  co-adaptive brain-machine interfaces. *10th Int. IEEE/EMBS Conf. on Neural
  Engineering (NER)*. Brain and decoder as strategic agents with own costs; gradient
  learning; convergence to Nash equilibria depends on the learning rates. [VERIFY pages/DOI]
- Madduri, M. M., Yamagami, M., Li, S. J., Burckhardt, S., Burden, S. A., Orsborn, A. L.
  (2024). Predicting and shaping human-machine interactions in closed-loop,
  co-adaptive neural interfaces. bioRxiv doi:10.1101/2024.05.23.595598; published as
  "Computational framework to predict and shape human-machine interactions in
  closed-loop, co-adaptive neural interfaces", *Nature Machine Intelligence* (2026).
  [VERIFY volume/pages/DOI of the journal version]
  **Closest work:** decoder learning rate and regularization are designed to shape the
  user's adaptation and the joint outcome; game-theoretic model with quadratic costs.
- Chasnov, B. J., Ratliff, L. J., Burden, S. A. (2025). Human adaptation to adaptive
  machines converges to game-theoretic equilibria. *Scientific Reports* 15, 29364.
  doi:10.1038/s41598-025-12998-1 (arXiv:2305.01124). Machine learning algorithms select
  the outcome among Nash/Stackelberg-type equilibria; one algorithm steers humans to the
  machine's optimum.

**Relation.** The two-learner problem is the same coupling structure. The BMI work
already *designs machine adaptation to shape the joint equilibrium* (Madduri et al.;
Chasnov et al.), so the concept is not new as such. Differences of this project:
(A) continuous-time dynamic games with state dynamics, horizons, and running costs
instead of static quadratic games with gradient learners; (B) the design variable is
the implant's objective (preference) and adaptation law, evaluated by a designer
criterion that differs from the implant's own objective; (C) biological implant-body
interaction (tissue, physiology, regulation) instead of neural decoding;
(D) equilibria computed by optimal-control best responses (CorleoneGame), so state
and path constraints, nonlinear dynamics, and duration choice are available.

## B. Human-in-the-loop optimization

- Zhang, J., Fiers, P., Witte, K. A., Jackson, R. W., Poggensee, K. L., Atkeson, C. G.,
  Collins, S. H. (2017). Human-in-the-loop optimization of exoskeleton assistance
  during walking. *Science* 356(6344), 1280-1283. doi:10.1126/science.aal5054.

**Relation.** The human is a measured, implicitly adapting black-box objective
(metabolic cost); the device parameters are searched online. No model of the human
as a strategic adaptive agent, no equilibrium concept. Here, the body is modeled
explicitly as an optimizing agent, and the design is evaluated through the predicted
equilibrium.

## C. Adaptive control and dual control

- Åström, K. J., Wittenmark, B. (1995). *Adaptive Control*, 2nd ed., Addison-Wesley
  (Dover reprint 2008).
- Feldbaum, A. A. (1960-1961). Dual control theory I-IV. *Automation and Remote
  Control*. [VERIFY volume/pages]
- Wittenmark, B. (1995). Adaptive dual control methods: An overview. *IFAC Proc.
  Volumes* 28(13). doi:10.1016/S1474-6670(17)45327-4.

**Relation.** In adaptive and dual control the controller adapts (and probes) to
learn a *non-strategic* plant with unknown parameters. Here the plant (body) is itself
adaptive and goal-directed; the controller's *adaptation law* is the design variable,
and success is judged by the equilibrium of two adapting agents. Dual control becomes
relevant once the body's parameters are unknown and the implant must learn them while
steering (next steps).

## D. Learning in games, opponent shaping, steering learners, machine teaching

- Fudenberg, D., Levine, D. K. (1998). *The Theory of Learning in Games*. MIT Press.
- Chasnov, B., Ratliff, L., Mazumdar, E., Burden, S. (2020). Convergence analysis of
  gradient-based learning in continuous games. *Proc. 35th Conf. on Uncertainty in
  Artificial Intelligence (UAI), PMLR* 115.
- Foerster, J., Chen, R. Y., Al-Shedivat, M., Whiteson, S., Abbeel, P., Mordatch, I.
  (2018). Learning with opponent-learning awareness. *Proc. AAMAS 2018*, 122-130.
  [VERIFY pages] LOLA: an agent shapes the anticipated learning step of the other.
- Zhang, B. H., Farina, G., Anagnostides, I., Cacciamani, F., McAleer, S. M., Haupt,
  A. A., Celli, A., Gatti, N., Conitzer, V., Sandholm, T. (2024). Steering no-regret
  learners to a desired equilibrium. ICLR 2024 submission (OpenReview EsjoMaNeVo);
  arXiv:2306.05221. [VERIFY final venue]
- Zhu, X. (2015). Machine teaching: An inverse problem to machine learning and an
  approach toward optimal education. *Proc. AAAI* 29(1). doi:10.1609/aaai.v29i1.9761.

**Relation.** Opponent shaping and steering act on the other learner through one's
own actions or payments during learning; machine teaching designs inputs for a
single learner. Here the designer acts *once, before the interaction*, on the
implant's preferences; the body is shaped only indirectly through the equilibrium.

## E. Incentive design, Stackelberg games, strategic delegation, preference evolution

- Başar, T., Olsder, G. J. (1999). *Dynamic Noncooperative Game Theory*, 2nd ed.,
  SIAM Classics in Applied Mathematics 23.
- Ho, Y.-C., Luh, P. B., Olsder, G. J. (1982). A control-theoretic view on incentives.
  *Automatica* 18(2), 167-179. [VERIFY issue]
- Ratliff, L. J., Dong, R., Sekar, S., Fiez, T. (2019). A perspective on incentive
  design: Challenges and opportunities. *Annu. Rev. Control Robot. Auton. Syst.* 2,
  305-338. doi:10.1146/annurev-control-053018-023634.
- Vickers, J. (1985). Delegation and the theory of the firm. *Economic Journal* 95
  (Supplement), 138-147. doi:10.2307/2232877.
- Fershtman, C., Judd, K. L. (1987). Equilibrium incentives in oligopoly. *American
  Economic Review* 77(5), 927-940.
- Güth, W., Yaari, M. (1992). Explaining reciprocal behavior in simple strategic
  games: An evolutionary approach. In: Witt, U. (ed.), *Explaining Process and Change*,
  Univ. of Michigan Press. [VERIFY book details and pages]

**Relation.** The designer-implant-body structure is a principal (designer) delegating
to an agent (implant) who plays a Nash game with a third party (body). Strategic
delegation predicts that the principal gains by giving the agent preferences that
*differ* from its own, as a commitment device. The first simple example reproduces
exactly this effect in a dynamic co-adaptation game: the best implant ignores the
mismatch that the designer cares about. The indirect evolutionary approach
(preferences selected by material outcomes of equilibrium play) is the evolutionary
counterpart of the outer design loop.

## F. Coevolution in evolutionary biology

- Dieckmann, U., Law, R. (1996). The dynamical theory of coevolution: A derivation
  from stochastic ecological processes. *J. Math. Biol.* 34, 579-612.
  doi:10.1007/BF02409751.

**Relation and terminology.** In biology "coevolution" means reciprocal genetic change
across generations. The project concerns within-lifetime *co-adaptation* (plasticity,
regulation, device adaptation). Recommend the term *co-adaptation* in publications, or
define "co-evolution" explicitly.

## Not yet covered

- "Adaptive games": the term is ambiguous (games with adapting players, adaptive
  dynamics in games, adaptive game AI); no dedicated search yet.
- Biological implant-tissue adaptation (foreign-body response, stress shielding,
  closed-loop neuromodulation, artificial pancreas with insulin sensitivity
  adaptation) as application background.
- Inverse games (estimating the body's objective from data), needed to calibrate B.

## Working position

Not new: modeling user and machine as co-adapting strategic agents; designing the
machine's learning rate to shape the joint outcome (BMI literature); strategic
delegation as a commitment device (economics).
Possibly new (to be checked further): designing an implant's *objective/adaptation law*
for a *dynamic* (ODE-based, constrained) co-adaptation game with a biological body,
computed by bilevel optimization over open-loop (generalized) Nash equilibria; and the
systematic comparison of naive, sincere, and designed adaptation mechanisms.
