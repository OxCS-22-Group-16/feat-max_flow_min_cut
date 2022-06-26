/-
Copyright (c) 2019 Mario Carneiro. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Reid Barton, Mario Carneiro, Isabel Longbottom, Scott Morrison
-/
import data.fin.basic
import data.list.basic
import logic.relation

/-!
# Combinatorial (pre-)games.

The basic theory of combinatorial games, following Conway's book `On Numbers and Games`. We
construct "pregames", define an ordering and arithmetic operations on them, then show that the
operations descend to "games", defined via the equivalence relation `p ≈ q ↔ p ≤ q ∧ q ≤ p`.

The surreal numbers will be built as a quotient of a subtype of pregames.

A pregame (`pgame` below) is axiomatised via an inductive type, whose sole constructor takes two
types (thought of as indexing the possible moves for the players Left and Right), and a pair of
functions out of these types to `pgame` (thought of as describing the resulting game after making a
move).

Combinatorial games themselves, as a quotient of pregames, are constructed in `game.lean`.

## Conway induction

By construction, the induction principle for pregames is exactly "Conway induction". That is, to
prove some predicate `pgame → Prop` holds for all pregames, it suffices to prove that for every
pregame `g`, if the predicate holds for every game resulting from making a move, then it also holds
for `g`.

While it is often convenient to work "by induction" on pregames, in some situations this becomes
awkward, so we also define accessor functions `pgame.left_moves`, `pgame.right_moves`,
`pgame.move_left` and `pgame.move_right`. There is a relation `pgame.subsequent p q`, saying that
`p` can be reached by playing some non-empty sequence of moves starting from `q`, an instance
`well_founded subsequent`, and a local tactic `pgame_wf_tac` which is helpful for discharging proof
obligations in inductive proofs relying on this relation.

## Order properties

Pregames have both a `≤` and a `<` relation, satisfying the usual properties of a `preorder`. The
relation `0 < x` means that `x` can always be won by Left, while `0 ≤ x` means that `x` can be won
by Left as the second player.

It turns out to be quite convenient to define various relations on top of these. We define the "less
or fuzzy" relation `x ⧏ y` as `¬ y ≤ x`, the equivalence relation `x ≈ y` as `x ≤ y ∧ y ≤ x`, and
the fuzzy relation `x ∥ y` as `x ⧏ y ∧ y ⧏ x`. If `0 ⧏ x`, then `x` can be won by Left as the
first player. If `x ≈ 0`, then `x` can be won by the second player. If `x ∥ 0`, then `x` can be won
by the first player.

Statements like `zero_le_lf`, `zero_lf_le`, etc. unfold these definitions. The theorems `le_def` and
`lf_def` give a recursive characterisation of each relation in terms of themselves two moves later.
The theorems `zero_le`, `zero_lf`, etc. also take into account that `0` has no moves.

Later, games will be defined as the quotient by the `≈` relation; that is to say, the
`antisymmetrization` of `pgame`.

## Algebraic structures

We next turn to defining the operations necessary to make games into a commutative additive group.
Addition is defined for $x = \{xL | xR\}$ and $y = \{yL | yR\}$ by $x + y = \{xL + y, x + yL | xR +
y, x + yR\}$. Negation is defined by $\{xL | xR\} = \{-xR | -xL\}$.

The order structures interact in the expected way with addition, so we have
```
theorem le_iff_sub_nonneg {x y : pgame} : x ≤ y ↔ 0 ≤ y - x := sorry
theorem lt_iff_sub_pos {x y : pgame} : x < y ↔ 0 < y - x := sorry
```

We show that these operations respect the equivalence relation, and hence descend to games. At the
level of games, these operations satisfy all the laws of a commutative group. To prove the necessary
equivalence relations at the level of pregames, we introduce the notion of a `relabelling` of a
game, and show, for example, that there is a relabelling between `x + (y + z)` and `(x + y) + z`.

## Future work

* The theory of dominated and reversible positions, and unique normal form for short games.
* Analysis of basic domineering positions.
* Hex.
* Temperature.
* The development of surreal numbers, based on this development of combinatorial games, is still
  quite incomplete.

## References

The material here is all drawn from
* [Conway, *On numbers and games*][conway2001]

An interested reader may like to formalise some of the material from
* [Andreas Blass, *A game semantics for linear logic*][MR1167694]
* [André Joyal, *Remarques sur la théorie des jeux à deux personnes*][joyal1997]
-/

open function relation

universes u

/-! ### Pre-game moves -/

/-- The type of pre-games, before we have quotiented
  by equivalence (`pgame.setoid`). In ZFC, a combinatorial game is constructed from
  two sets of combinatorial games that have been constructed at an earlier
  stage. To do this in type theory, we say that a pre-game is built
  inductively from two families of pre-games indexed over any type
  in Type u. The resulting type `pgame.{u}` lives in `Type (u+1)`,
  reflecting that it is a proper class in ZFC. -/
inductive pgame : Type (u+1)
| mk : ∀ α β : Type u, (α → pgame) → (β → pgame) → pgame

namespace pgame

/-- The indexing type for allowable moves by Left. -/
def left_moves : pgame → Type u
| (mk l _ _ _) := l
/-- The indexing type for allowable moves by Right. -/
def right_moves : pgame → Type u
| (mk _ r _ _) := r

/-- The new game after Left makes an allowed move. -/
def move_left : Π (g : pgame), left_moves g → pgame
| (mk l _ L _) := L
/-- The new game after Right makes an allowed move. -/
def move_right : Π (g : pgame), right_moves g → pgame
| (mk _ r _ R) := R

@[simp] lemma left_moves_mk {xl xr xL xR} : (⟨xl, xr, xL, xR⟩ : pgame).left_moves = xl := rfl
@[simp] lemma move_left_mk {xl xr xL xR} : (⟨xl, xr, xL, xR⟩ : pgame).move_left = xL := rfl
@[simp] lemma right_moves_mk {xl xr xL xR} : (⟨xl, xr, xL, xR⟩ : pgame).right_moves = xr := rfl
@[simp] lemma move_right_mk {xl xr xL xR} : (⟨xl, xr, xL, xR⟩ : pgame).move_right = xR := rfl

/--
Construct a pre-game from list of pre-games describing the available moves for Left and Right.
-/
-- TODO define this at the level of games, as well, and perhaps also for finsets of games.
def of_lists (L R : list pgame.{u}) : pgame.{u} :=
mk (ulift (fin L.length)) (ulift (fin R.length))
  (λ i, L.nth_le i.down i.down.is_lt) (λ j, R.nth_le j.down j.down.prop)

lemma left_moves_of_lists (L R : list pgame) : (of_lists L R).left_moves = ulift (fin L.length) :=
rfl
lemma right_moves_of_lists (L R : list pgame) : (of_lists L R).right_moves = ulift (fin R.length) :=
rfl

/-- Converts a number into a left move for `of_lists`. -/
def to_of_lists_left_moves {L R : list pgame} : fin L.length ≃ (of_lists L R).left_moves :=
((equiv.cast (left_moves_of_lists L R).symm).trans equiv.ulift).symm

/-- Converts a number into a right move for `of_lists`. -/
def to_of_lists_right_moves {L R : list pgame} : fin R.length ≃ (of_lists L R).right_moves :=
((equiv.cast (right_moves_of_lists L R).symm).trans equiv.ulift).symm

theorem of_lists_move_left {L R : list pgame} (i : fin L.length) :
  (of_lists L R).move_left (to_of_lists_left_moves i) = L.nth_le i i.is_lt :=
rfl

@[simp] theorem of_lists_move_left' {L R : list pgame} (i : (of_lists L R).left_moves) :
  (of_lists L R).move_left i =
  L.nth_le (to_of_lists_left_moves.symm i) (to_of_lists_left_moves.symm i).is_lt :=
rfl

theorem of_lists_move_right {L R : list pgame} (i : fin R.length) :
  (of_lists L R).move_right (to_of_lists_right_moves i) = R.nth_le i i.is_lt :=
rfl

@[simp] theorem of_lists_move_right' {L R : list pgame} (i : (of_lists L R).right_moves) :
  (of_lists L R).move_right i =
  R.nth_le (to_of_lists_right_moves.symm i) (to_of_lists_right_moves.symm i).is_lt :=
rfl

/-- A variant of `pgame.rec_on` expressed in terms of `pgame.move_left` and `pgame.move_right`.

Both this and `pgame.rec_on` describe Conway induction on games. -/
@[elab_as_eliminator] def move_rec_on {C : pgame → Sort*} (x : pgame)
  (IH : ∀ (y : pgame), (∀ i, C (y.move_left i)) → (∀ j, C (y.move_right j)) → C y) : C x :=
x.rec_on $ λ yl yr yL yR, IH (mk yl yr yL yR)

/-- `is_option x y` means that `x` is either a left or right option for `y`. -/
@[mk_iff] inductive is_option : pgame → pgame → Prop
| move_left {x : pgame} (i : x.left_moves) : is_option (x.move_left i) x
| move_right {x : pgame} (i : x.right_moves) : is_option (x.move_right i) x

theorem is_option.mk_left {xl xr : Type u} (xL : xl → pgame) (xR : xr → pgame) (i : xl) :
  (xL i).is_option (mk xl xr xL xR) :=
@is_option.move_left (mk _ _ _ _) i

theorem is_option.mk_right {xl xr : Type u} (xL : xl → pgame) (xR : xr → pgame) (i : xr) :
  (xR i).is_option (mk xl xr xL xR) :=
@is_option.move_right (mk _ _ _ _) i

theorem wf_is_option : well_founded is_option :=
⟨λ x, move_rec_on x $ λ x IHl IHr, acc.intro x $ λ y h, begin
  induction h with _ i _ j,
  { exact IHl i },
  { exact IHr j }
end⟩

/-- `subsequent x y` says that `x` can be obtained by playing some nonempty sequence of moves from
`y`. It is the transitive closure of `is_option`. -/
def subsequent : pgame → pgame → Prop :=
trans_gen is_option

instance : is_trans _ subsequent := trans_gen.is_trans

@[trans] theorem subsequent.trans {x y z} : subsequent x y → subsequent y z → subsequent x z :=
trans_gen.trans

theorem wf_subsequent : well_founded subsequent := wf_is_option.trans_gen

instance : has_well_founded pgame := ⟨_, wf_subsequent⟩

lemma subsequent.move_left {x : pgame} (i : x.left_moves) : subsequent (x.move_left i) x :=
trans_gen.single (is_option.move_left i)

lemma subsequent.move_right {x : pgame} (j : x.right_moves) : subsequent (x.move_right j) x :=
trans_gen.single (is_option.move_right j)

lemma subsequent.mk_left {xl xr} (xL : xl → pgame) (xR : xr → pgame) (i : xl) :
  subsequent (xL i) (mk xl xr xL xR) :=
@subsequent.move_left (mk _ _ _ _) i

lemma subsequent.mk_right {xl xr} (xL : xl → pgame) (xR : xr → pgame) (j : xr) :
  subsequent (xR j) (mk xl xr xL xR) :=
@subsequent.move_right (mk _ _ _ _) j

/-- A local tactic for proving well-foundedness of recursive definitions involving pregames. -/
meta def pgame_wf_tac :=
`[solve_by_elim
  [psigma.lex.left, psigma.lex.right, subsequent.move_left, subsequent.move_right,
   subsequent.mk_left, subsequent.mk_right, subsequent.trans]
  { max_depth := 6 }]

/-! ### Basic pre-games -/

/-- The pre-game `zero` is defined by `0 = { | }`. -/
instance : has_zero pgame := ⟨⟨pempty, pempty, pempty.elim, pempty.elim⟩⟩

@[simp] lemma zero_left_moves : left_moves 0 = pempty := rfl
@[simp] lemma zero_right_moves : right_moves 0 = pempty := rfl

instance is_empty_zero_left_moves : is_empty (left_moves 0) := pempty.is_empty
instance is_empty_zero_right_moves : is_empty (right_moves 0) := pempty.is_empty

instance : inhabited pgame := ⟨0⟩

/-- The pre-game `one` is defined by `1 = { 0 | }`. -/
instance : has_one pgame := ⟨⟨punit, pempty, λ _, 0, pempty.elim⟩⟩

@[simp] lemma one_left_moves : left_moves 1 = punit := rfl
@[simp] lemma one_move_left (x) : move_left 1 x = 0 := rfl
@[simp] lemma one_right_moves : right_moves 1 = pempty := rfl

instance unique_one_left_moves : unique (left_moves 1) := punit.unique
instance is_empty_one_right_moves : is_empty (right_moves 1) := pempty.is_empty

/-! ### Pre-game order relations -/

/-- Define simultaneously by mutual induction the `≤` relation and its swapped converse `⧏` on
  pre-games.

  The ZFC definition says that `x = {xL | xR}` is less or equal to `y = {yL | yR}` if
  `∀ x₁ ∈ xL, x₁ ⧏ y` and `∀ y₂ ∈ yR, x ⧏ y₂`, where `x ⧏ y` means `¬ y ≤ x`. This is a tricky
  induction because it only decreases one side at a time, and it also swaps the arguments in the
  definition of `≤`. The solution is to define `x ≤ y` and `x ⧏ y` simultaneously. -/
def le_lf : Π (x y : pgame.{u}), Prop × Prop
| (mk xl xr xL xR) (mk yl yr yL yR) :=
  -- the orderings of the clauses here are carefully chosen so that
  --   and.left/or.inl refer to moves by Left, and
  --   and.right/or.inr refer to moves by Right.
((∀ i, (le_lf (xL i) ⟨yl, yr, yL, yR⟩).2) ∧ ∀ j, (le_lf ⟨xl, xr, xL, xR⟩ (yR j)).2,
 (∃ i, (le_lf ⟨xl, xr, xL, xR⟩ (yL i)).1) ∨ ∃ j, (le_lf (xR j) ⟨yl, yr, yL, yR⟩).1)
using_well_founded { dec_tac := pgame_wf_tac }

/-- The less or equal relation on pre-games.

If `0 ≤ x`, then Left can win `x` as the second player. -/
instance : has_le pgame := ⟨λ x y, (le_lf x y).1⟩

/-- The less or fuzzy relation on pre-games.

If `0 ⧏ x`, then Left can win `x` as the first player. -/
def lf (x y : pgame) : Prop := (le_lf x y).2

localized "infix ` ⧏ `:50 := pgame.lf" in pgame

/-- Definition of `x ≤ y` on pre-games built using the constructor. -/
@[simp] theorem mk_le_mk {xl xr xL xR yl yr yL yR} :
  mk xl xr xL xR ≤ mk yl yr yL yR ↔
  (∀ i, xL i ⧏ mk yl yr yL yR) ∧ ∀ j, mk xl xr xL xR ⧏ yR j :=
show (le_lf _ _).1 ↔ _, by { rw le_lf, refl }

/-- Definition of `x ≤ y` on pre-games, in terms of `⧏` -/
theorem le_iff_forall_lf {x y : pgame} :
  x ≤ y ↔ (∀ i, x.move_left i ⧏ y) ∧ ∀ j, x ⧏ y.move_right j :=
by { cases x, cases y, exact mk_le_mk }

theorem le_of_forall_lf {x y : pgame} (h₁ : ∀ i, x.move_left i ⧏ y) (h₂ : ∀ j, x ⧏ y.move_right j) :
  x ≤ y :=
le_iff_forall_lf.2 ⟨h₁, h₂⟩

/-- Definition of `x ⧏ y` on pre-games built using the constructor. -/
@[simp] theorem mk_lf_mk {xl xr xL xR yl yr yL yR} :
  mk xl xr xL xR ⧏ mk yl yr yL yR ↔
  (∃ i, mk xl xr xL xR ≤ yL i) ∨ ∃ j, xR j ≤ mk yl yr yL yR :=
show (le_lf _ _).2 ↔ _, by { rw le_lf, refl }

/-- Definition of `x ⧏ y` on pre-games, in terms of `≤` -/
theorem lf_iff_exists_le {x y : pgame} :
  x ⧏ y ↔ (∃ i, x ≤ y.move_left i) ∨ ∃ j, x.move_right j ≤ y :=
by { cases x, cases y, exact mk_lf_mk }

private theorem not_le_lf {x y : pgame} : (¬ x ≤ y ↔ y ⧏ x) ∧ (¬ x ⧏ y ↔ y ≤ x) :=
begin
  induction x with xl xr xL xR IHxl IHxr generalizing y,
  induction y with yl yr yL yR IHyl IHyr,
  simp only [mk_le_mk, mk_lf_mk, IHxl, IHxr, IHyl, IHyr,
    not_and_distrib, not_or_distrib, not_forall, not_exists,
    and_comm, or_comm, iff_self, and_self]
end

@[simp] protected theorem not_le {x y : pgame} : ¬ x ≤ y ↔ y ⧏ x := not_le_lf.1
@[simp] theorem not_lf {x y : pgame} : ¬ x ⧏ y ↔ y ≤ x := not_le_lf.2
theorem _root_.has_le.le.not_gf {x y : pgame} : x ≤ y → ¬ y ⧏ x := not_lf.2
theorem lf.not_ge {x y : pgame} : x ⧏ y → ¬ y ≤ x := pgame.not_le.2

theorem le_or_gf (x y : pgame) : x ≤ y ∨ y ⧏ x :=
by { rw ←pgame.not_le, apply em }

theorem move_left_lf_of_le {x y : pgame} (i) (h : x ≤ y) : x.move_left i ⧏ y :=
(le_iff_forall_lf.1 h).1 i

theorem lf_move_right_of_le {x y : pgame} (j) (h : x ≤ y) : x ⧏ y.move_right j :=
(le_iff_forall_lf.1 h).2 j

theorem lf_of_move_right_le {x y : pgame} {j} (h : x.move_right j ≤ y) : x ⧏ y :=
lf_iff_exists_le.2 $ or.inr ⟨j, h⟩

theorem lf_of_le_move_left {x y : pgame} {i} (h : x ≤ y.move_left i) : x ⧏ y :=
lf_iff_exists_le.2 $ or.inl ⟨i, h⟩

theorem lf_of_le_mk {xl xr xL xR y} : ∀ i, mk xl xr xL xR ≤ y → xL i ⧏ y :=
@move_left_lf_of_le (mk _ _ _ _) y

theorem lf_of_mk_le {x yl yr yL yR} : ∀ j, x ≤ mk yl yr yL yR → x ⧏ yR j :=
@lf_move_right_of_le x (mk _ _ _ _)

theorem mk_lf_of_le {xl xr y j} (xL) {xR : xr → pgame} : xR j ≤ y → mk xl xr xL xR ⧏ y :=
@lf_of_move_right_le (mk _ _ _ _) y j

theorem lf_mk_of_le {x yl yr} {yL : yl → pgame} (yR) {i} : x ≤ yL i → x ⧏ mk yl yr yL yR :=
@lf_of_le_move_left x (mk _ _ _ _) i

private theorem le_trans_aux
  {xl xr} {xL : xl → pgame} {xR : xr → pgame}
  {yl yr} {yL : yl → pgame} {yR : yr → pgame}
  {zl zr} {zL : zl → pgame} {zR : zr → pgame}
  (h₁ : ∀ i, mk yl yr yL yR ≤ mk zl zr zL zR → mk zl zr zL zR ≤ xL i → mk yl yr yL yR ≤ xL i)
  (h₂ : ∀ i, zR i ≤ mk xl xr xL xR → mk xl xr xL xR ≤ mk yl yr yL yR → zR i ≤ mk yl yr yL yR) :
  mk xl xr xL xR ≤ mk yl yr yL yR →
  mk yl yr yL yR ≤ mk zl zr zL zR →
  mk xl xr xL xR ≤ mk zl zr zL zR :=
by simp only [mk_le_mk] at *; exact
λ ⟨xLy, xyR⟩ ⟨yLz, yzR⟩, ⟨
  λ i, pgame.not_le.1 (λ h, (h₁ _ ⟨yLz, yzR⟩ h).not_gf (xLy _)),
  λ i, pgame.not_le.1 (λ h, (h₂ _ h ⟨xLy, xyR⟩).not_gf (yzR _))⟩

instance : preorder pgame :=
{ le_refl := λ x, begin
    induction x with _ _ _ _ IHl IHr,
    exact le_of_forall_lf (λ i, lf_of_le_move_left (IHl i)) (λ i, lf_of_move_right_le (IHr i))
  end,
  le_trans := λ x y z, suffices ∀ {x y z : pgame},
    (x ≤ y → y ≤ z → x ≤ z) ∧ (y ≤ z → z ≤ x → y ≤ x) ∧ (z ≤ x → x ≤ y → z ≤ y),
  from this.1, begin
    clear x y z, intros,
    induction x with xl xr xL xR IHxl IHxr generalizing y z,
    induction y with yl yr yL yR IHyl IHyr generalizing z,
    induction z with zl zr zL zR IHzl IHzr,
    exact ⟨
      le_trans_aux (λ i, (IHxl _).2.1) (λ i, (IHzr _).2.2),
      le_trans_aux (λ i, (IHyl _).2.2) (λ i, (IHxr _).1),
      le_trans_aux (λ i, (IHzl _).1) (λ i, (IHyr _).2.1)⟩,
  end,
  ..pgame.has_le }

theorem lf_irrefl (x : pgame) : ¬ x ⧏ x := le_rfl.not_gf
instance : is_irrefl _ (⧏) := ⟨lf_irrefl⟩

@[trans] theorem lf_of_le_of_lf {x y z : pgame} (h₁ : x ≤ y) (h₂ : y ⧏ z) : x ⧏ z :=
by { rw ←pgame.not_le at h₂ ⊢, exact λ h₃, h₂ (h₃.trans h₁) }
@[trans] theorem lf_of_lf_of_le {x y z : pgame} (h₁ : x ⧏ y) (h₂ : y ≤ z) : x ⧏ z :=
by { rw ←pgame.not_le at h₁ ⊢, exact λ h₃, h₁ (h₂.trans h₃) }

alias lf_of_le_of_lf ← has_le.le.trans_lf
alias lf_of_lf_of_le ← pgame.lf.trans_le

@[trans] theorem lf_of_lt_of_lf {x y z : pgame} (h₁ : x < y) (h₂ : y ⧏ z) : x ⧏ z :=
h₁.le.trans_lf h₂

@[trans] theorem lf_of_lf_of_lt {x y z : pgame} (h₁ : x ⧏ y) (h₂ : y < z) : x ⧏ z :=
h₁.trans_le h₂.le

alias lf_of_lt_of_lf ← has_lt.lt.trans_lf
alias lf_of_lf_of_lt ← pgame.lf.trans_lt

theorem move_left_lf {x : pgame} (i) : x.move_left i ⧏ x :=
move_left_lf_of_le i le_rfl

theorem lf_move_right {x : pgame} (j) : x ⧏ x.move_right j :=
lf_move_right_of_le j le_rfl

theorem lf_mk {xl xr} (xL : xl → pgame) (xR : xr → pgame) (i) : xL i ⧏ mk xl xr xL xR :=
@move_left_lf (mk _ _ _ _) i

theorem mk_lf {xl xr} (xL : xl → pgame) (xR : xr → pgame) (j) : mk xl xr xL xR ⧏ xR j :=
@lf_move_right (mk _ _ _ _) j

theorem lt_iff_le_and_lf {x y : pgame} : x < y ↔ x ≤ y ∧ x ⧏ y :=
by rw [lt_iff_le_not_le, pgame.not_le]

theorem lt_of_le_of_lf {x y : pgame} (h₁ : x ≤ y) (h₂ : x ⧏ y) : x < y :=
lt_iff_le_and_lf.2 ⟨h₁, h₂⟩

theorem lf_of_lt {x y : pgame} (h : x < y) : x ⧏ y := (lt_iff_le_and_lf.1 h).2
alias lf_of_lt ← has_lt.lt.lf

/-- This special case of `pgame.le_of_forall_lf` is useful when dealing with surreals, where `<` is
preferred over `⧏`. -/
theorem le_of_forall_lt {x y : pgame} (h₁ : ∀ i, x.move_left i < y) (h₂ : ∀ j, x < y.move_right j) :
  x ≤ y :=
le_of_forall_lf (λ i, (h₁ i).lf) (λ i, (h₂ i).lf)

/-- The definition of `x ≤ y` on pre-games, in terms of `≤` two moves later. -/
theorem le_def {x y : pgame} : x ≤ y ↔
  (∀ i, (∃ i', x.move_left i ≤ y.move_left i')  ∨ ∃ j, (x.move_left i).move_right j ≤ y) ∧
   ∀ j, (∃ i, x ≤ (y.move_right j).move_left i) ∨ ∃ j', x.move_right j' ≤ y.move_right j :=
by { rw le_iff_forall_lf, conv { to_lhs, simp only [lf_iff_exists_le] } }

/-- The definition of `x ⧏ y` on pre-games, in terms of `⧏` two moves later. -/
theorem lf_def {x y : pgame} : x ⧏ y ↔
  (∃ i, (∀ i', x.move_left i' ⧏ y.move_left i)  ∧ ∀ j, x ⧏ (y.move_left i).move_right j) ∨
   ∃ j, (∀ i, (x.move_right j).move_left i ⧏ y) ∧ ∀ j', x.move_right j ⧏ y.move_right j' :=
by { rw lf_iff_exists_le, conv { to_lhs, simp only [le_iff_forall_lf] } }

/-- The definition of `0 ≤ x` on pre-games, in terms of `0 ⧏`. -/
theorem zero_le_lf {x : pgame} : 0 ≤ x ↔ ∀ j, 0 ⧏ x.move_right j :=
by { rw le_iff_forall_lf, dsimp, simp }

/-- The definition of `x ≤ 0` on pre-games, in terms of `⧏ 0`. -/
theorem le_zero_lf {x : pgame} : x ≤ 0 ↔ ∀ i, x.move_left i ⧏ 0 :=
by { rw le_iff_forall_lf, dsimp, simp }

/-- The definition of `0 ⧏ x` on pre-games, in terms of `0 ≤`. -/
theorem zero_lf_le {x : pgame} : 0 ⧏ x ↔ ∃ i, 0 ≤ x.move_left i :=
by { rw lf_iff_exists_le, dsimp, simp }

/-- The definition of `x ⧏ 0` on pre-games, in terms of `≤ 0`. -/
theorem lf_zero_le {x : pgame} : x ⧏ 0 ↔ ∃ j, x.move_right j ≤ 0 :=
by { rw lf_iff_exists_le, dsimp, simp }

/-- The definition of `0 ≤ x` on pre-games, in terms of `0 ≤` two moves later. -/
theorem zero_le {x : pgame} : 0 ≤ x ↔ ∀ j, ∃ i, 0 ≤ (x.move_right j).move_left i :=
by { rw le_def, dsimp, simp }

/-- The definition of `x ≤ 0` on pre-games, in terms of `≤ 0` two moves later. -/
theorem le_zero {x : pgame} : x ≤ 0 ↔ ∀ i, ∃ j, (x.move_left i).move_right j ≤ 0 :=
by { rw le_def, dsimp, simp }

/-- The definition of `0 ⧏ x` on pre-games, in terms of `0 ⧏` two moves later. -/
theorem zero_lf {x : pgame} : 0 ⧏ x ↔ ∃ i, ∀ j, 0 ⧏ (x.move_left i).move_right j :=
by { rw lf_def, dsimp, simp }

/-- The definition of `x ⧏ 0` on pre-games, in terms of `⧏ 0` two moves later. -/
theorem lf_zero {x : pgame} : x ⧏ 0 ↔ ∃ j, ∀ i, (x.move_right j).move_left i ⧏ 0 :=
by { rw lf_def, dsimp, simp }

@[simp] theorem zero_le_of_is_empty_right_moves (x : pgame) [is_empty x.right_moves] : 0 ≤ x :=
zero_le.2 is_empty_elim

@[simp] theorem le_zero_of_is_empty_left_moves (x : pgame) [is_empty x.left_moves] : x ≤ 0 :=
le_zero.2 is_empty_elim

/-- Given a game won by the right player when they play second, provide a response to any move by
left. -/
noncomputable def right_response {x : pgame} (h : x ≤ 0) (i : x.left_moves) :
  (x.move_left i).right_moves :=
classical.some $ (le_zero.1 h) i

/-- Show that the response for right provided by `right_response` preserves the right-player-wins
condition. -/
lemma right_response_spec {x : pgame} (h : x ≤ 0) (i : x.left_moves) :
  (x.move_left i).move_right (right_response h i) ≤ 0 :=
classical.some_spec $ (le_zero.1 h) i

/-- Given a game won by the left player when they play second, provide a response to any move by
right. -/
noncomputable def left_response {x : pgame} (h : 0 ≤ x) (j : x.right_moves) :
  (x.move_right j).left_moves :=
classical.some $ (zero_le.1 h) j

/-- Show that the response for left provided by `left_response` preserves the left-player-wins
condition. -/
lemma left_response_spec {x : pgame} (h : 0 ≤ x) (j : x.right_moves) :
  0 ≤ (x.move_right j).move_left (left_response h j) :=
classical.some_spec $ (zero_le.1 h) j

/-- The equivalence relation on pre-games. Two pre-games `x`, `y` are equivalent if `x ≤ y` and
`y ≤ x`.

If `x ≈ 0`, then the second player can always win `x`. -/
def equiv (x y : pgame) : Prop := x ≤ y ∧ y ≤ x

localized "infix ` ≈ ` := pgame.equiv" in pgame

instance : is_equiv _ (≈) :=
{ refl := λ x, ⟨le_rfl, le_rfl⟩,
  trans := λ x y z ⟨xy, yx⟩ ⟨yz, zy⟩, ⟨xy.trans yz, zy.trans yx⟩,
  symm := λ x y, and.symm }

theorem equiv.le {x y : pgame} (h : x ≈ y) : x ≤ y := h.1
theorem equiv.ge {x y : pgame} (h : x ≈ y) : y ≤ x := h.2

@[refl, simp] theorem equiv_rfl {x} : x ≈ x := refl x
theorem equiv_refl (x) : x ≈ x := refl x
@[symm] protected theorem equiv.symm {x y} : x ≈ y → y ≈ x := symm
@[trans] protected theorem equiv.trans {x y z} : x ≈ y → y ≈ z → x ≈ z := trans
theorem equiv.comm {x y} : x ≈ y ↔ y ≈ x := comm

theorem equiv_of_eq {x y} (h : x = y) : x ≈ y := by subst h

@[trans] theorem le_of_le_of_equiv {x y z} (h₁ : x ≤ y) (h₂ : y ≈ z) : x ≤ z := h₁.trans h₂.1
@[trans] theorem le_of_equiv_of_le {x y z} (h₁ : x ≈ y) : y ≤ z → x ≤ z := h₁.1.trans

theorem lf.not_equiv {x y} (h : x ⧏ y) : ¬ x ≈ y := λ h', h.not_ge h'.2
theorem lf.not_equiv' {x y} (h : x ⧏ y) : ¬ y ≈ x := λ h', h.not_ge h'.1

theorem lf.not_gt {x y} (h : x ⧏ y) : ¬ y < x := λ h', h.not_ge h'.le

theorem le_iff_lt_or_equiv {x y : pgame} : x ≤ y ↔ x < y ∨ x ≈ y :=
by { simp only [lt_iff_le_and_lf, equiv, ←pgame.not_le], tauto! }

theorem le_congr_imp {x₁ y₁ x₂ y₂} (hx : x₁ ≈ x₂) (hy : y₁ ≈ y₂) (h : x₁ ≤ y₁) : x₂ ≤ y₂ :=
hx.2.trans (h.trans hy.1)
theorem le_congr {x₁ y₁ x₂ y₂} (hx : x₁ ≈ x₂) (hy : y₁ ≈ y₂) : x₁ ≤ y₁ ↔ x₂ ≤ y₂ :=
⟨le_congr_imp hx hy, le_congr_imp hx.symm hy.symm⟩
theorem le_congr_left {x₁ x₂ y} (hx : x₁ ≈ x₂) : x₁ ≤ y ↔ x₂ ≤ y :=
le_congr hx equiv_rfl
theorem le_congr_right {x y₁ y₂} (hy : y₁ ≈ y₂) : x ≤ y₁ ↔ x ≤ y₂ :=
le_congr equiv_rfl hy

theorem lf_congr {x₁ y₁ x₂ y₂} (hx : x₁ ≈ x₂) (hy : y₁ ≈ y₂) : x₁ ⧏ y₁ ↔ x₂ ⧏ y₂ :=
pgame.not_le.symm.trans $ (not_congr (le_congr hy hx)).trans pgame.not_le
theorem lf_congr_imp {x₁ y₁ x₂ y₂} (hx : x₁ ≈ x₂) (hy : y₁ ≈ y₂) : x₁ ⧏ y₁ → x₂ ⧏ y₂ :=
(lf_congr hx hy).1
theorem lf_congr_left {x₁ x₂ y} (hx : x₁ ≈ x₂) : x₁ ⧏ y ↔ x₂ ⧏ y :=
lf_congr hx equiv_rfl
theorem lf_congr_right {x y₁ y₂} (hy : y₁ ≈ y₂) : x ⧏ y₁ ↔ x ⧏ y₂ :=
lf_congr equiv_rfl hy

@[trans] theorem lf_of_lf_of_equiv {x y z} (h₁ : x ⧏ y) (h₂ : y ≈ z) : x ⧏ z :=
lf_congr_imp equiv_rfl h₂ h₁
@[trans] theorem lf_of_equiv_of_lf {x y z} (h₁ : x ≈ y) : y ⧏ z → x ⧏ z :=
lf_congr_imp h₁.symm equiv_rfl

@[trans] theorem lt_of_lt_of_equiv {x y z} (h₁ : x < y) (h₂ : y ≈ z) : x < z := h₁.trans_le h₂.1
@[trans] theorem lt_of_equiv_of_lt {x y z} (h₁ : x ≈ y) : y < z → x < z := h₁.1.trans_lt

theorem lt_congr_imp {x₁ y₁ x₂ y₂} (hx : x₁ ≈ x₂) (hy : y₁ ≈ y₂) (h : x₁ < y₁) : x₂ < y₂ :=
hx.2.trans_lt (h.trans_le hy.1)
theorem lt_congr {x₁ y₁ x₂ y₂} (hx : x₁ ≈ x₂) (hy : y₁ ≈ y₂) : x₁ < y₁ ↔ x₂ < y₂ :=
⟨lt_congr_imp hx hy, lt_congr_imp hx.symm hy.symm⟩
theorem lt_congr_left {x₁ x₂ y} (hx : x₁ ≈ x₂) : x₁ < y ↔ x₂ < y :=
lt_congr hx equiv_rfl
theorem lt_congr_right {x y₁ y₂} (hy : y₁ ≈ y₂) : x < y₁ ↔ x < y₂ :=
lt_congr equiv_rfl hy

theorem lf_or_equiv_of_le {x y : pgame} (h : x ≤ y) : x ⧏ y ∨ x ≈ y :=
or_iff_not_imp_left.2 $ λ h', ⟨h, pgame.not_lf.1 h'⟩

theorem lf_or_equiv_or_gf (x y : pgame) : x ⧏ y ∨ x ≈ y ∨ y ⧏ x :=
begin
  by_cases h : x ⧏ y,
  { exact or.inl h },
  { right,
    cases (lf_or_equiv_of_le (pgame.not_lf.1 h)) with h' h',
    { exact or.inr h' },
    { exact or.inl h'.symm } }
end

theorem equiv_congr_left {y₁ y₂} : y₁ ≈ y₂ ↔ ∀ x₁, x₁ ≈ y₁ ↔ x₁ ≈ y₂ :=
⟨λ h x₁, ⟨λ h', h'.trans h, λ h', h'.trans h.symm⟩,
 λ h, (h y₁).1 $ equiv_rfl⟩

theorem equiv_congr_right {x₁ x₂} : x₁ ≈ x₂ ↔ ∀ y₁, x₁ ≈ y₁ ↔ x₂ ≈ y₁ :=
⟨λ h y₁, ⟨λ h', h.symm.trans h', λ h', h.trans h'⟩,
 λ h, (h x₂).2 $ equiv_rfl⟩

theorem equiv_of_mk_equiv {x y : pgame}
  (L : x.left_moves ≃ y.left_moves) (R : x.right_moves ≃ y.right_moves)
  (hl : ∀ (i : x.left_moves), x.move_left i ≈ y.move_left (L i))
  (hr : ∀ (j : y.right_moves), x.move_right (R.symm j) ≈ y.move_right j) :
  x ≈ y :=
begin
  fsplit; rw le_def,
  { exact ⟨λ i, or.inl ⟨L i, (hl i).1⟩, λ j, or.inr ⟨R.symm j, (hr j).1⟩⟩ },
  { fsplit,
    { intro i,
      left,
      specialize hl (L.symm i),
      simp only [move_left_mk, equiv.apply_symm_apply] at hl,
      use ⟨L.symm i, hl.2⟩ },
    { intro j,
      right,
      specialize hr (R j),
      simp only [move_right_mk, equiv.symm_apply_apply] at hr,
      use ⟨R j, hr.2⟩ } }
end

/-- The fuzzy, confused, or incomparable relation on pre-games.

If `x ∥ 0`, then the first player can always win `x`. -/
def fuzzy (x y : pgame) : Prop := x ⧏ y ∧ y ⧏ x

localized "infix ` ∥ `:50 := pgame.fuzzy" in pgame

@[symm] theorem fuzzy.swap {x y : pgame} : x ∥ y → y ∥ x := and.swap
instance : is_symm _ (∥) := ⟨λ x y, fuzzy.swap⟩
theorem fuzzy.comm {x y : pgame} : x ∥ y ↔ y ∥ x := comm

theorem fuzzy_irrefl (x : pgame) : ¬ x ∥ x := λ h, lf_irrefl x h.1
instance : is_irrefl _ (∥) := ⟨fuzzy_irrefl⟩

theorem lf_iff_lt_or_fuzzy {x y : pgame} : x ⧏ y ↔ x < y ∨ x ∥ y :=
by { simp only [lt_iff_le_and_lf, fuzzy, ←pgame.not_le], tauto! }

theorem lf_of_fuzzy {x y : pgame} (h : x ∥ y) : x ⧏ y := lf_iff_lt_or_fuzzy.2 (or.inr h)
alias lf_of_fuzzy ← pgame.fuzzy.lf

theorem lt_or_fuzzy_of_lf {x y : pgame} : x ⧏ y → x < y ∨ x ∥ y :=
lf_iff_lt_or_fuzzy.1

theorem fuzzy.not_equiv {x y : pgame} (h : x ∥ y) : ¬ x ≈ y :=
λ h', h'.1.not_gf h.2
theorem fuzzy.not_equiv' {x y : pgame} (h : x ∥ y) : ¬ y ≈ x :=
λ h', h'.2.not_gf h.2

theorem not_fuzzy_of_le {x y : pgame} (h : x ≤ y) : ¬ x ∥ y :=
λ h', h'.2.not_ge h
theorem not_fuzzy_of_ge {x y : pgame} (h : y ≤ x) : ¬ x ∥ y :=
λ h', h'.1.not_ge h

alias not_fuzzy_of_le ← has_le.le.not_fuzzy
alias not_fuzzy_of_ge ← has_le.le.not_fuzzy'

theorem equiv.not_fuzzy {x y : pgame} (h : x ≈ y) : ¬ x ∥ y :=
not_fuzzy_of_le h.1
theorem equiv.not_fuzzy' {x y : pgame} (h : x ≈ y) : ¬ y ∥ x :=
not_fuzzy_of_le h.2

theorem fuzzy_congr {x₁ y₁ x₂ y₂ : pgame} (hx : x₁ ≈ x₂) (hy : y₁ ≈ y₂) : x₁ ∥ y₁ ↔ x₂ ∥ y₂ :=
show _ ∧ _ ↔ _ ∧ _, by rw [lf_congr hx hy, lf_congr hy hx]
theorem fuzzy_congr_imp {x₁ y₁ x₂ y₂ : pgame} (hx : x₁ ≈ x₂) (hy : y₁ ≈ y₂) : x₁ ∥ y₁ → x₂ ∥ y₂ :=
(fuzzy_congr hx hy).1
theorem fuzzy_congr_left {x₁ x₂ y} (hx : x₁ ≈ x₂) : x₁ ∥ y ↔ x₂ ∥ y :=
fuzzy_congr hx equiv_rfl
theorem fuzzy_congr_right {x y₁ y₂} (hy : y₁ ≈ y₂) : x ∥ y₁ ↔ x ∥ y₂ :=
fuzzy_congr equiv_rfl hy

@[trans] theorem fuzzy_of_fuzzy_of_equiv {x y z} (h₁ : x ∥ y) (h₂ : y ≈ z) : x ∥ z :=
(fuzzy_congr_right h₂).1 h₁
@[trans] theorem fuzzy_of_equiv_of_fuzzy {x y z} (h₁ : x ≈ y) (h₂ : y ∥ z) : x ∥ z :=
(fuzzy_congr_left h₁).2 h₂

/-- Exactly one of the following is true (although we don't prove this here). -/
theorem lt_or_equiv_or_gt_or_fuzzy (x y : pgame) : x < y ∨ x ≈ y ∨ y < x ∨ x ∥ y :=
begin
  cases le_or_gf x y with h₁ h₁;
  cases le_or_gf y x with h₂ h₂,
  { right, left, exact ⟨h₁, h₂⟩ },
  { left, exact lt_of_le_of_lf h₁ h₂ },
  { right, right, left, exact lt_of_le_of_lf h₂ h₁ },
  { right, right, right, exact ⟨h₂, h₁⟩ }
end

theorem lt_or_equiv_or_gf (x y : pgame) : x < y ∨ x ≈ y ∨ y ⧏ x :=
begin
  rw [lf_iff_lt_or_fuzzy, fuzzy.comm],
  exact lt_or_equiv_or_gt_or_fuzzy x y
end

/-! ### Pre-game comparison -/

/-- The type representing the possible outcomes for the comparison of two games. -/
inductive game_ordering
| lt
| equiv
| gt
| fuzzy

namespace game_ordering

instance : inhabited game_ordering := ⟨equiv⟩

instance : has_repr game_ordering :=
⟨(λ s, match s with
| game_ordering.lt := "lt"
| game_ordering.equiv := "equiv"
| game_ordering.gt := "gt"
| game_ordering.fuzzy := "fuzzy"
end)⟩

instance : decidable_eq game_ordering :=
λ a b, begin
  cases a;
  cases b;
  try { exact is_true rfl };
  try { exact is_false (λ h, game_ordering.no_confusion h) }
end

/-- If `x` and `y` compare as `o`, then `y` and `x` compare as `o.swap`. -/
def swap : game_ordering → game_ordering
| lt := gt
| equiv := equiv
| gt := lt
| fuzzy := fuzzy

@[simp] theorem swap_swap (o : game_ordering) : o.swap.swap = o :=
by { cases o; refl }

@[simp] theorem swap_lt : lt.swap = gt := rfl
@[simp] theorem swap_equiv : game_ordering.equiv.swap = game_ordering.equiv := rfl
@[simp] theorem swap_gt : gt.swap = lt := rfl
@[simp] theorem swap_fuzzy : game_ordering.fuzzy.swap = fuzzy := rfl

@[simp] theorem swap_inj (o₁ o₂ : game_ordering) : o₁.swap = o₂.swap ↔ o₁ = o₂ :=
by { cases o₁; cases o₂; simp }

end game_ordering

/-- Compares two pre-games. -/
noncomputable def cmp (x y : pgame) : game_ordering :=
by { classical, exact if x ≤ y then
  if y ≤ x then game_ordering.equiv else game_ordering.lt
else
  if y ≤ x then game_ordering.gt else game_ordering.fuzzy }

@[simp] theorem cmp_swap (x y : pgame) : (cmp x y).swap = cmp y x :=
begin
  by_cases h₁ : x ≤ y;
  by_cases h₂ : y ≤ x;
  simpa only [cmp, h₁, h₂]
end

theorem cmp_eq_cmp_iff_cmp_eq_cmp {w x y z : pgame} : cmp w x = cmp y z ↔ cmp x w = cmp z y :=
by rw [←game_ordering.swap_inj, cmp_swap, cmp_swap]

@[simp] theorem cmp_eq_lt_iff {x y : pgame} : cmp x y = game_ordering.lt ↔ x < y :=
begin
  by_cases h₁ : x ≤ y;
  by_cases h₂ : y ≤ x;
  simp only [cmp, h₁, h₂, if_true, if_false, true_iff, false_iff, eq_self_iff_true];
  try { rw pgame.not_le at * },
  { exact h₂.not_lt },
  { exact lt_of_le_of_lf h₁ h₂ },
  { exact h₂.not_lt },
  { exact h₁.not_gt }
end

@[simp] theorem cmp_eq_equiv_iff {x y : pgame} : cmp x y = game_ordering.equiv ↔ x ≈ y :=
begin
  by_cases h₁ : x ≤ y;
  by_cases h₂ : y ≤ x;
  simp only [cmp, h₁, h₂, if_true, if_false, true_iff, false_iff, eq_self_iff_true];
  try { rw pgame.not_le at * },
  { exact ⟨h₁, h₂⟩ },
  { exact h₂.not_equiv },
  { exact h₁.not_equiv' },
  { exact h₂.not_equiv }
end

@[simp] theorem cmp_eq_gt_iff {x y : pgame} : cmp x y = game_ordering.gt ↔ y < x :=
by rw [←game_ordering.swap_inj, cmp_swap, game_ordering.swap_gt, cmp_eq_lt_iff]

@[simp] theorem cmp_eq_fuzzy_iff {x y : pgame} : cmp x y = game_ordering.fuzzy ↔ x ∥ y :=
begin
  by_cases h₁ : x ≤ y;
  by_cases h₂ : y ≤ x;
  simp only [cmp, h₁, h₂, if_true, if_false, true_iff, false_iff, eq_self_iff_true];
  try { rw pgame.not_le at * },
  { exact h₁.not_fuzzy },
  { exact h₁.not_fuzzy },
  { exact h₂.not_fuzzy' },
  { exact ⟨h₂, h₁⟩ }
end

theorem le_iff_cmp_eq_lt_or_equiv {x y : pgame} :
  x ≤ y ↔ cmp x y = game_ordering.lt ∨ cmp x y = game_ordering.equiv :=
by simpa using le_iff_lt_or_equiv

theorem lf_iff_cmp_eq_lt_or_fuzzy {x y : pgame} :
  x ⧏ y ↔ cmp x y = game_ordering.lt ∨ cmp x y = game_ordering.fuzzy :=
by simpa using lf_iff_lt_or_fuzzy

theorem cmp_eq_iff_le_iff_le {w x y z : pgame} :
  cmp w x = cmp y z ↔ (w ≤ x ↔ y ≤ z) ∧ (x ≤ w ↔ z ≤ y) :=
begin
  by_cases h₁ : w ≤ x;
  by_cases h₂ : x ≤ w;
  by_cases h₃ : y ≤ z;
  by_cases h₄ : z ≤ y;
  simp [cmp, h₁, h₂, h₃, h₄]
end

theorem cmp_eq_iff_lf_iff_lf {w x y z : pgame} :
  cmp w x = cmp y z ↔ (w ⧏ x ↔ y ⧏ z) ∧ (x ⧏ w ↔ z ⧏ y) :=
by simp_rw [cmp_eq_iff_le_iff_le, ←pgame.not_le, not_iff_not, and.comm]

theorem lt_iff_lt_of_cmp_eq {w x y z : pgame} (h : cmp w x = cmp y z) : w < x ↔ y < z :=
by rw [←cmp_eq_lt_iff, ←cmp_eq_lt_iff, h]

theorem le_iff_le_of_cmp_eq {w x y z : pgame} (h : cmp w x = cmp y z) : w ≤ x ↔ y ≤ z :=
by rw [le_iff_cmp_eq_lt_or_equiv, le_iff_cmp_eq_lt_or_equiv, h]

theorem lf_iff_lf_of_cmp_eq {w x y z : pgame} (h : cmp w x = cmp y z) : w ⧏ x ↔ y ⧏ z :=
by rw [lf_iff_cmp_eq_lt_or_fuzzy, lf_iff_cmp_eq_lt_or_fuzzy, h]

theorem equiv_iff_equiv_of_cmp_eq {w x y z : pgame} (h : cmp w x = cmp y z) : w ≈ x ↔ y ≈ z :=
by rw [←cmp_eq_equiv_iff, ←cmp_eq_equiv_iff, h]

theorem equiv_iff_equiv_of_cmp_eq' {w x y z : pgame} (h : cmp w x = cmp y z) : w ≈ x ↔ z ≈ y :=
by rw [equiv_iff_equiv_of_cmp_eq h, equiv.comm]

theorem fuzzy_iff_fuzzy_of_cmp_eq {w x y z : pgame} (h : cmp w x = cmp y z) : w ∥ x ↔ y ∥ z :=
by rw [←cmp_eq_fuzzy_iff, ←cmp_eq_fuzzy_iff, h]

theorem fuzzy_iff_fuzzy_of_cmp_eq' {w x y z : pgame} (h : cmp w x = cmp y z) : w ∥ x ↔ z ∥ y :=
by rw [fuzzy_iff_fuzzy_of_cmp_eq h, fuzzy.comm]

theorem cmp_congr {w x y z : pgame} (h₁ : w ≈ x) (h₂ : y ≈ z) : cmp w y = cmp x z :=
by { rw cmp_eq_iff_le_iff_le, exact ⟨le_congr h₁ h₂, le_congr h₂ h₁⟩ }

/-! ### Relabellings -/

/-- `restricted x y` says that Left always has no more moves in `x` than in `y`,
     and Right always has no more moves in `y` than in `x` -/
inductive restricted : pgame.{u} → pgame.{u} → Type (u+1)
| mk : Π {x y : pgame} (L : x.left_moves → y.left_moves) (R : y.right_moves → x.right_moves),
         (∀ i, restricted (x.move_left i) (y.move_left (L i))) →
         (∀ j, restricted (x.move_right (R j)) (y.move_right j)) → restricted x y

/-- The identity restriction. -/
@[refl] def restricted.refl : Π (x : pgame), restricted x x
| ⟨xl, xr, xL, xR⟩ := ⟨_, _, λ i, restricted.refl _, λ j, restricted.refl _⟩
using_well_founded { dec_tac := pgame_wf_tac }

instance (x : pgame) : inhabited (restricted x x) := ⟨restricted.refl _⟩

/-- Transitivity of restriction. -/
def restricted.trans : Π {x y z : pgame} (r : restricted x y) (s : restricted y z),
  restricted x z
| ⟨xl, xr, xL, xR⟩ ⟨yl, yr, yL, yR⟩ ⟨zl, zr, zL, zR⟩ ⟨L₁, R₁, hL₁, hR₁⟩ ⟨L₂, R₂, hL₂, hR₂⟩ :=
⟨_, _, λ i, (hL₁ i).trans (hL₂ _), λ j, (hR₁ _).trans (hR₂ j)⟩

theorem restricted.le : Π {x y : pgame} (r : restricted x y), x ≤ y
| ⟨xl, xr, xL, xR⟩ ⟨yl, yr, yL, yR⟩ ⟨L, R, hL, hR⟩ :=
le_def.2 ⟨λ i, or.inl ⟨L i, (hL i).le⟩, λ i, or.inr ⟨R i, (hR i).le⟩⟩

/--
`relabelling x y` says that `x` and `y` are really the same game, just dressed up differently.
Specifically, there is a bijection between the moves for Left in `x` and in `y`, and similarly
for Right, and under these bijections we inductively have `relabelling`s for the consequent games.
-/
inductive relabelling : pgame.{u} → pgame.{u} → Type (u+1)
| mk : Π {x y : pgame} (L : x.left_moves ≃ y.left_moves) (R : x.right_moves ≃ y.right_moves),
         (∀ i, relabelling (x.move_left i) (y.move_left (L i))) →
         (∀ j, relabelling (x.move_right (R.symm j)) (y.move_right j)) →
       relabelling x y

localized "infix ` ≡r `:50 := pgame.relabelling" in pgame

/-- If `x` is a relabelling of `y`, then `x` is a restriction of  `y`. -/
def relabelling.restricted : Π {x y : pgame} (r : x ≡r y), restricted x y
| ⟨xl, xr, xL, xR⟩ ⟨yl, yr, yL, yR⟩ ⟨L, R, hL, hR⟩ :=
⟨L, R.symm, λ i, (hL i).restricted, λ j, (hR j).restricted⟩

-- It's not the case that `restricted x y → restricted y x → relabelling x y`,
-- but if we insisted that the maps in a restriction were injective, then one
-- could use Schröder-Bernstein for do this.

/-- The identity relabelling. -/
@[refl] def relabelling.refl : Π (x : pgame), x ≡r x
| ⟨xl, xr, xL, xR⟩ := ⟨equiv.refl _, equiv.refl _, λ i, relabelling.refl _, λ j, relabelling.refl _⟩
using_well_founded { dec_tac := pgame_wf_tac }

instance (x : pgame) : inhabited (x ≡r x) := ⟨relabelling.refl _⟩

/-- Flip a relabelling. -/
@[symm] def relabelling.symm : Π {x y : pgame}, x ≡r y → y ≡r x
| ⟨xl, xr, xL, xR⟩ ⟨yl, yr, yL, yR⟩ ⟨L, R, hL, hR⟩ :=
⟨L.symm, R.symm, λ i, by simpa using (hL (L.symm i)).symm, λ j, by simpa using (hR (R j)).symm⟩

theorem relabelling.le {x y : pgame} (r : x ≡r y) : x ≤ y := r.restricted.le
theorem relabelling.ge {x y : pgame} (r : x ≡r y) : y ≤ x := r.symm.restricted.le

/-- A relabelling lets us prove equivalence of games. -/
theorem relabelling.equiv {x y : pgame} (r : x ≡r y) : x ≈ y := ⟨r.le, r.ge⟩

/-- Transitivity of relabelling. -/
@[trans] def relabelling.trans : Π {x y z : pgame}, x ≡r y → y ≡r z → x ≡r z
| ⟨xl, xr, xL, xR⟩ ⟨yl, yr, yL, yR⟩ ⟨zl, zr, zL, zR⟩ ⟨L₁, R₁, hL₁, hR₁⟩ ⟨L₂, R₂, hL₂, hR₂⟩ :=
⟨L₁.trans L₂, R₁.trans R₂,
  λ i, by simpa using (hL₁ i).trans (hL₂ _), λ j, by simpa using (hR₁ _).trans (hR₂ j)⟩

/-- Any game without left or right moves is a relabelling of 0. -/
def relabelling.is_empty (x : pgame) [is_empty x.left_moves] [is_empty x.right_moves] : x ≡r 0 :=
⟨equiv.equiv_pempty _, equiv.equiv_pempty _, is_empty_elim, is_empty_elim⟩

theorem equiv.is_empty (x : pgame) [is_empty x.left_moves] [is_empty x.right_moves] : x ≈ 0 :=
(relabelling.is_empty x).equiv

instance {x y : pgame} : has_coe (x ≡r y) (x ≈ y) := ⟨relabelling.equiv⟩

/-- Replace the types indexing the next moves for Left and Right by equivalent types. -/
def relabel {x : pgame} {xl' xr'} (el : x.left_moves ≃ xl') (er : x.right_moves ≃ xr') : pgame :=
⟨xl', xr', λ i, x.move_left (el.symm i), λ j, x.move_right (er.symm j)⟩

@[simp] lemma relabel_move_left' {x : pgame} {xl' xr'}
  (el : x.left_moves ≃ xl') (er : x.right_moves ≃ xr') (i : xl') :
  move_left (relabel el er) i = x.move_left (el.symm i) :=
rfl
@[simp] lemma relabel_move_left {x : pgame} {xl' xr'}
  (el : x.left_moves ≃ xl') (er : x.right_moves ≃ xr') (i : x.left_moves) :
  move_left (relabel el er) (el i) = x.move_left i :=
by simp

@[simp] lemma relabel_move_right' {x : pgame} {xl' xr'}
  (el : x.left_moves ≃ xl') (er : x.right_moves ≃ xr') (j : xr') :
  move_right (relabel el er) j = x.move_right (er.symm j) :=
rfl
@[simp] lemma relabel_move_right {x : pgame} {xl' xr'}
  (el : x.left_moves ≃ xl') (er : x.right_moves ≃ xr') (j : x.right_moves) :
  move_right (relabel el er) (er j) = x.move_right j :=
by simp

/-- The game obtained by relabelling the next moves is a relabelling of the original game. -/
def relabel_relabelling {x : pgame} {xl' xr'} (el : x.left_moves ≃ xl') (er : x.right_moves ≃ xr') :
  x ≡r relabel el er :=
relabelling.mk el er (λ i, by simp) (λ j, by simp)

/-! ### Negation -/

/-- The negation of `{L | R}` is `{-R | -L}`. -/
def neg : pgame → pgame
| ⟨l, r, L, R⟩ := ⟨r, l, λ i, neg (R i), λ i, neg (L i)⟩

instance : has_neg pgame := ⟨neg⟩

@[simp] lemma neg_def {xl xr xL xR} : -(mk xl xr xL xR) = mk xr xl (λ j, -(xR j)) (λ i, -(xL i)) :=
rfl

instance : has_involutive_neg pgame :=
{ neg_neg := λ x, begin
    induction x with xl xr xL xR ihL ihR,
    simp_rw [neg_def, ihL, ihR],
    exact ⟨rfl, rfl, heq.rfl, heq.rfl⟩,
  end,
  ..pgame.has_neg }

@[simp] protected lemma neg_zero : -(0 : pgame) = 0 :=
begin
  dsimp [has_zero.zero, has_neg.neg, neg],
  congr; funext i; cases i
end

@[simp] lemma neg_of_lists (L R : list pgame) :
  -of_lists L R = of_lists (R.map (λ x, -x)) (L.map (λ x, -x)) :=
begin
  simp only [of_lists, neg_def, list.length_map, list.nth_le_map', eq_self_iff_true, true_and],
  split, all_goals
  { apply hfunext,
    { simp },
    { intros a a' ha,
      congr' 2,
      have : ∀ {m n} (h₁ : m = n) {b : ulift (fin m)} {c : ulift (fin n)} (h₂ : b == c),
        (b.down : ℕ) = ↑c.down,
      { rintros m n rfl b c rfl, refl },
      exact this (list.length_map _ _).symm ha } }
end

theorem left_moves_neg : ∀ x : pgame, (-x).left_moves = x.right_moves
| ⟨_, _, _, _⟩ := rfl

theorem right_moves_neg : ∀ x : pgame, (-x).right_moves = x.left_moves
| ⟨_, _, _, _⟩ := rfl

/-- Turns a right move for `x` into a left move for `-x` and vice versa.

Even though these types are the same (not definitionally so), this is the preferred way to convert
between them. -/
def to_left_moves_neg {x : pgame} : x.right_moves ≃ (-x).left_moves :=
equiv.cast (left_moves_neg x).symm

/-- Turns a left move for `x` into a right move for `-x` and vice versa.

Even though these types are the same (not definitionally so), this is the preferred way to convert
between them. -/
def to_right_moves_neg {x : pgame} : x.left_moves ≃ (-x).right_moves :=
equiv.cast (right_moves_neg x).symm

lemma move_left_neg {x : pgame} (i) :
  (-x).move_left (to_left_moves_neg i) = -x.move_right i :=
by { cases x, refl }

@[simp] lemma move_left_neg' {x : pgame} (i) :
  (-x).move_left i = -x.move_right (to_left_moves_neg.symm i) :=
by { cases x, refl }

lemma move_right_neg {x : pgame} (i) :
  (-x).move_right (to_right_moves_neg i) = -(x.move_left i) :=
by { cases x, refl }

@[simp] lemma move_right_neg' {x : pgame} (i) :
  (-x).move_right i = -x.move_left (to_right_moves_neg.symm i) :=
by { cases x, refl }

lemma move_left_neg_symm {x : pgame} (i) :
  x.move_left (to_right_moves_neg.symm i) = -(-x).move_right i :=
by simp

lemma move_left_neg_symm' {x : pgame} (i) :
  x.move_left i = -(-x).move_right (to_right_moves_neg i) :=
by simp

lemma move_right_neg_symm {x : pgame} (i) :
  x.move_right (to_left_moves_neg.symm i) = -(-x).move_left i :=
by simp

lemma move_right_neg_symm' {x : pgame} (i) :
  x.move_right i = -(-x).move_left (to_left_moves_neg i) :=
by simp

/-- If `x` has the same moves as `y`, then `-x` has the sames moves as `-y`. -/
def relabelling.neg_congr : ∀ {x y : pgame}, x ≡r y → -x ≡r -y
| ⟨xl, xr, xL, xR⟩ ⟨yl, yr, yL, yR⟩ ⟨L, R, hL, hR⟩ :=
  ⟨R, L,
    λ i, relabelling.neg_congr (by simpa using hR (R i)),
    λ i, relabelling.neg_congr (by simpa using hL (L.symm i))⟩

private theorem neg_le_lf_neg_iff :
  Π {x y : pgame.{u}}, (-y ≤ -x ↔ x ≤ y) ∧ (-y ⧏ -x ↔ x ⧏ y)
| (mk xl xr xL xR) (mk yl yr yL yR) :=
begin
  simp_rw [neg_def, mk_le_mk, mk_lf_mk, ← neg_def],
  split,
  { rw and_comm, apply and_congr; exact forall_congr (λ _, neg_le_lf_neg_iff.2) },
  { rw or_comm, apply or_congr; exact exists_congr (λ _, neg_le_lf_neg_iff.1) },
end
using_well_founded { dec_tac := pgame_wf_tac }

@[simp] theorem neg_le_neg_iff {x y : pgame} : -y ≤ -x ↔ x ≤ y :=
neg_le_lf_neg_iff.1

@[simp] theorem cmp_neg (x y : pgame) : cmp (-x) (-y) = cmp y x :=
by { rw cmp_eq_iff_le_iff_le, simp }

@[simp] theorem neg_lf_neg_iff {x y : pgame} : -y ⧏ -x ↔ x ⧏ y :=
neg_le_lf_neg_iff.2
@[simp] theorem neg_lt_neg_iff {x y : pgame} : -y < -x ↔ x < y :=
lt_iff_lt_of_cmp_eq (cmp_neg y x)
@[simp] theorem neg_equiv_neg_iff {x y : pgame} : -x ≈ -y ↔ x ≈ y :=
equiv_iff_equiv_of_cmp_eq' (cmp_neg x y)
@[simp] theorem neg_fuzzy_neg_iff {x y : pgame} : -x ∥ -y ↔ x ∥ y :=
fuzzy_iff_fuzzy_of_cmp_eq' (cmp_neg x y)

theorem cmp_neg_left (x y : pgame) : cmp (-x) y = cmp (-y) x :=
by rw [←cmp_neg, neg_neg]

theorem neg_le_iff {x y : pgame} : -x ≤ y ↔ -y ≤ x :=
le_iff_le_of_cmp_eq (cmp_neg_left x y)
theorem neg_lf_iff {x y : pgame} : -x ⧏ y ↔ -y ⧏ x :=
lf_iff_lf_of_cmp_eq (cmp_neg_left x y)
theorem neg_lt_iff {x y : pgame} : -x < y ↔ -y < x :=
lt_iff_lt_of_cmp_eq (cmp_neg_left x y)
theorem neg_equiv_iff {x y : pgame} : -x ≈ y ↔ x ≈ -y :=
equiv_iff_equiv_of_cmp_eq' (cmp_neg_left x y)
theorem neg_fuzzy_iff {x y : pgame} : -x ∥ y ↔ x ∥ -y :=
fuzzy_iff_fuzzy_of_cmp_eq' (cmp_neg_left x y)

theorem cmp_neg_right (x y : pgame) : cmp x (-y) = cmp y (-x) :=
by rw [←cmp_neg, neg_neg]

theorem le_neg_iff {x y : pgame} : x ≤ -y ↔ y ≤ -x :=
le_iff_le_of_cmp_eq (cmp_neg_right x y)
theorem lf_neg_iff {x y : pgame} : x ⧏ -y ↔ y ⧏ -x :=
lf_iff_lf_of_cmp_eq (cmp_neg_right x y)
theorem lt_neg_iff {x y : pgame} : x < -y ↔ y < -x :=
lt_iff_lt_of_cmp_eq (cmp_neg_right x y)

@[simp] theorem cmp_neg_zero (x) : cmp (-x) 0 = cmp 0 x :=
by rw [←cmp_neg x, pgame.neg_zero]

@[simp] theorem neg_le_zero_iff {x : pgame} : -x ≤ 0 ↔ 0 ≤ x :=
le_iff_le_of_cmp_eq (cmp_neg_zero x)
@[simp] theorem neg_lf_zero_iff {x : pgame} : -x ⧏ 0 ↔ 0 ⧏ x :=
lf_iff_lf_of_cmp_eq (cmp_neg_zero x)
@[simp] theorem neg_lt_zero_iff {x : pgame} : -x < 0 ↔ 0 < x :=
lt_iff_lt_of_cmp_eq (cmp_neg_zero x)
@[simp] theorem neg_equiv_zero_iff {x : pgame} : -x ≈ 0 ↔ x ≈ 0 :=
equiv_iff_equiv_of_cmp_eq' (cmp_neg_zero x)
@[simp] theorem neg_fuzzy_zero_iff {x : pgame} : -x ∥ 0 ↔ x ∥ 0 :=
fuzzy_iff_fuzzy_of_cmp_eq' (cmp_neg_zero x)

@[simp] theorem cmp_zero_neg (x) : cmp 0 (-x) = cmp x 0 :=
by rw [←cmp_neg 0, pgame.neg_zero]

@[simp] theorem zero_le_neg_iff {x : pgame} : 0 ≤ -x ↔ x ≤ 0 :=
le_iff_le_of_cmp_eq (cmp_zero_neg x)
@[simp] theorem zero_lf_neg_iff {x : pgame} : 0 ⧏ -x ↔ x ⧏ 0 :=
lf_iff_lf_of_cmp_eq (cmp_zero_neg x)
@[simp] theorem zero_lt_neg_iff {x : pgame} : 0 < -x ↔ x < 0 :=
lt_iff_lt_of_cmp_eq (cmp_zero_neg x)
@[simp] theorem zero_equiv_neg_iff {x : pgame} : 0 ≈ -x ↔ 0 ≈ x :=
equiv_iff_equiv_of_cmp_eq' (cmp_zero_neg x)
@[simp] theorem zero_fuzzy_neg_iff {x : pgame} : 0 ∥ -x ↔ 0 ∥ x :=
fuzzy_iff_fuzzy_of_cmp_eq' (cmp_zero_neg x)

/-! ### Addition and subtraction -/

/-- The sum of `x = {xL | xR}` and `y = {yL | yR}` is `{xL + y, x + yL | xR + y, x + yR}`. -/
instance : has_add pgame.{u} := ⟨λ x y, begin
  induction x with xl xr xL xR IHxl IHxr generalizing y,
  induction y with yl yr yL yR IHyl IHyr,
  have y := mk yl yr yL yR,
  refine ⟨xl ⊕ yl, xr ⊕ yr, sum.rec _ _, sum.rec _ _⟩,
  { exact λ i, IHxl i y },
  { exact IHyl },
  { exact λ i, IHxr i y },
  { exact IHyr }
end⟩

@[simp] theorem nat_one : ((1 : ℕ) : pgame) = 0 + 1 := rfl

instance is_empty_left_moves_add (x y : pgame.{u})
  [is_empty x.left_moves] [is_empty y.left_moves] : is_empty (x + y).left_moves :=
begin
  unfreezingI { cases x, cases y },
  apply is_empty_sum.2 ⟨_, _⟩,
  assumption'
end

instance is_empty_right_moves_add (x y : pgame.{u})
  [is_empty x.right_moves] [is_empty y.right_moves] : is_empty (x + y).right_moves :=
begin
  unfreezingI { cases x, cases y },
  apply is_empty_sum.2 ⟨_, _⟩,
  assumption'
end

/-- `x + 0` has exactly the same moves as `x`. -/
def add_zero_relabelling : Π (x : pgame.{u}), x + 0 ≡r x
| (mk xl xr xL xR) :=
begin
  refine ⟨equiv.sum_empty xl pempty, equiv.sum_empty xr pempty, _, _⟩,
  { rintro (⟨i⟩|⟨⟨⟩⟩),
    apply add_zero_relabelling, },
  { rintro j,
    apply add_zero_relabelling, }
end

/-- `x + 0` is equivalent to `x`. -/
lemma add_zero_equiv (x : pgame.{u}) : x + 0 ≈ x :=
(add_zero_relabelling x).equiv

/-- `0 + x` has exactly the same moves as `x`. -/
def zero_add_relabelling : Π (x : pgame.{u}), 0 + x ≡r x
| (mk xl xr xL xR) :=
begin
  refine ⟨equiv.empty_sum pempty xl, equiv.empty_sum pempty xr, _, _⟩,
  { rintro (⟨⟨⟩⟩|⟨i⟩),
    apply zero_add_relabelling, },
  { rintro j,
    apply zero_add_relabelling, }
end

/-- `0 + x` is equivalent to `x`. -/
lemma zero_add_equiv (x : pgame.{u}) : 0 + x ≈ x :=
(zero_add_relabelling x).equiv

theorem left_moves_add : ∀ (x y : pgame.{u}),
  (x + y).left_moves = (x.left_moves ⊕ y.left_moves)
| ⟨_, _, _, _⟩ ⟨_, _, _, _⟩ := rfl

theorem right_moves_add : ∀ (x y : pgame.{u}),
  (x + y).right_moves = (x.right_moves ⊕ y.right_moves)
| ⟨_, _, _, _⟩ ⟨_, _, _, _⟩ := rfl

/-- Converts a left move for `x` or `y` into a left move for `x + y` and vice versa.

Even though these types are the same (not definitionally so), this is the preferred way to convert
between them. -/
def to_left_moves_add {x y : pgame} :
  x.left_moves ⊕ y.left_moves ≃ (x + y).left_moves :=
equiv.cast (left_moves_add x y).symm

/-- Converts a right move for `x` or `y` into a right move for `x + y` and vice versa.

Even though these types are the same (not definitionally so), this is the preferred way to convert
between them. -/
def to_right_moves_add {x y : pgame} :
  x.right_moves ⊕ y.right_moves ≃ (x + y).right_moves :=
equiv.cast (right_moves_add x y).symm

@[simp] lemma mk_add_move_left_inl {xl xr yl yr} {xL xR yL yR} {i} :
  (mk xl xr xL xR + mk yl yr yL yR).move_left (sum.inl i) =
    (mk xl xr xL xR).move_left i + (mk yl yr yL yR) :=
rfl
@[simp] lemma add_move_left_inl {x : pgame} (y : pgame) (i) :
  (x + y).move_left (to_left_moves_add (sum.inl i)) = x.move_left i + y :=
by { cases x, cases y, refl }

@[simp] lemma mk_add_move_right_inl {xl xr yl yr} {xL xR yL yR} {i} :
  (mk xl xr xL xR + mk yl yr yL yR).move_right (sum.inl i) =
    (mk xl xr xL xR).move_right i + (mk yl yr yL yR) :=
rfl
@[simp] lemma add_move_right_inl {x : pgame} (y : pgame) (i) :
  (x + y).move_right (to_right_moves_add (sum.inl i)) = x.move_right i + y :=
by { cases x, cases y, refl }

@[simp] lemma mk_add_move_left_inr {xl xr yl yr} {xL xR yL yR} {i} :
  (mk xl xr xL xR + mk yl yr yL yR).move_left (sum.inr i) =
    (mk xl xr xL xR) + (mk yl yr yL yR).move_left i :=
rfl
@[simp] lemma add_move_left_inr (x : pgame) {y : pgame} (i) :
  (x + y).move_left (to_left_moves_add (sum.inr i)) = x + y.move_left i :=
by { cases x, cases y, refl }

@[simp] lemma mk_add_move_right_inr {xl xr yl yr} {xL xR yL yR} {i} :
  (mk xl xr xL xR + mk yl yr yL yR).move_right (sum.inr i) =
    (mk xl xr xL xR) + (mk yl yr yL yR).move_right i :=
rfl
@[simp] lemma add_move_right_inr (x : pgame) {y : pgame} (i) :
  (x + y).move_right (to_right_moves_add (sum.inr i)) = x + y.move_right i :=
by { cases x, cases y, refl }

lemma left_moves_add_cases {x y : pgame} (k) {P : (x + y).left_moves → Prop}
  (hl : ∀ i, P $ to_left_moves_add (sum.inl i))
  (hr : ∀ i, P $ to_left_moves_add (sum.inr i)) : P k :=
begin
  rw ←to_left_moves_add.apply_symm_apply k,
  cases to_left_moves_add.symm k with i i,
  { exact hl i },
  { exact hr i }
end

lemma right_moves_add_cases {x y : pgame} (k) {P : (x + y).right_moves → Prop}
  (hl : ∀ j, P $ to_right_moves_add (sum.inl j))
  (hr : ∀ j, P $ to_right_moves_add (sum.inr j)) : P k :=
begin
  rw ←to_right_moves_add.apply_symm_apply k,
  cases to_right_moves_add.symm k with i i,
  { exact hl i },
  { exact hr i }
end

instance is_empty_nat_right_moves : ∀ n : ℕ, is_empty (right_moves n)
| 0 := pempty.is_empty
| (n + 1) := begin
  haveI := is_empty_nat_right_moves n,
  rw [nat.cast_succ, right_moves_add],
  apply_instance
end

/-- If `w` has the same moves as `x` and `y` has the same moves as `z`,
then `w + y` has the same moves as `x + z`. -/
def relabelling.add_congr : ∀ {w x y z : pgame.{u}}, w ≡r x → y ≡r z → w + y ≡r x + z
| ⟨wl, wr, wL, wR⟩ ⟨xl, xr, xL, xR⟩ ⟨yl, yr, yL, yR⟩ ⟨zl, zr, zL, zR⟩
  ⟨L₁, R₁, hL₁, hR₁⟩ ⟨L₂, R₂, hL₂, hR₂⟩ :=
begin
  let Hwx : ⟨wl, wr, wL, wR⟩ ≡r ⟨xl, xr, xL, xR⟩ := ⟨L₁, R₁, hL₁, hR₁⟩,
  let Hyz : ⟨yl, yr, yL, yR⟩ ≡r ⟨zl, zr, zL, zR⟩ := ⟨L₂, R₂, hL₂, hR₂⟩,
  refine ⟨equiv.sum_congr L₁ L₂, equiv.sum_congr R₁ R₂, _, _⟩;
  rintro (i|j),
  { exact (hL₁ i).add_congr Hyz },
  { exact Hwx.add_congr (hL₂ j) },
  { exact (hR₁ i).add_congr Hyz },
  { exact Hwx.add_congr (hR₂ j) }
end
using_well_founded { dec_tac := pgame_wf_tac }

instance : has_sub pgame := ⟨λ x y, x + -y⟩

@[simp] theorem sub_zero (x : pgame) : x - 0 = x + 0 :=
show x + -0 = x + 0, by rw pgame.neg_zero

/-- If `w` has the same moves as `x` and `y` has the same moves as `z`,
then `w - y` has the same moves as `x - z`. -/
def relabelling.sub_congr {w x y z : pgame} (h₁ : w ≡r x) (h₂ : y ≡r z) : w - y ≡r x - z :=
h₁.add_congr h₂.neg_congr

/-- `-(x + y)` has exactly the same moves as `-x + -y`. -/
def neg_add_relabelling : Π (x y : pgame), -(x + y) ≡r -x + -y
| ⟨xl, xr, xL, xR⟩ ⟨yl, yr, yL, yR⟩ :=
begin
  refine ⟨equiv.refl _, equiv.refl _, _, _⟩,
  all_goals {
    exact λ j, sum.cases_on j
      (λ j, neg_add_relabelling _ _)
      (λ j, neg_add_relabelling ⟨xl, xr, xL, xR⟩ _) }
end
using_well_founded { dec_tac := pgame_wf_tac }

theorem neg_add_le {x y : pgame} : -(x + y) ≤ -x + -y :=
(neg_add_relabelling x y).le

/-- `x + y` has exactly the same moves as `y + x`. -/
def add_comm_relabelling : Π (x y : pgame.{u}), x + y ≡r y + x
| (mk xl xr xL xR) (mk yl yr yL yR) :=
begin
  refine ⟨equiv.sum_comm _ _, equiv.sum_comm _ _, _, _⟩;
  rintros (_|_);
  { dsimp [left_moves_add, right_moves_add], apply add_comm_relabelling }
end
using_well_founded { dec_tac := pgame_wf_tac }

theorem add_comm_le {x y : pgame} : x + y ≤ y + x :=
(add_comm_relabelling x y).le

theorem add_comm_equiv {x y : pgame} : x + y ≈ y + x :=
(add_comm_relabelling x y).equiv

/-- `(x + y) + z` has exactly the same moves as `x + (y + z)`. -/
def add_assoc_relabelling : Π (x y z : pgame.{u}), x + y + z ≡r x + (y + z)
| ⟨xl, xr, xL, xR⟩ ⟨yl, yr, yL, yR⟩ ⟨zl, zr, zL, zR⟩ :=
begin
  refine ⟨equiv.sum_assoc _ _ _, equiv.sum_assoc _ _ _, _, _⟩,
  all_goals
  { rintro (⟨i|i⟩|i) <|> rintro (j|⟨j|j⟩),
    { apply add_assoc_relabelling },
    { apply add_assoc_relabelling ⟨xl, xr, xL, xR⟩ },
    { apply add_assoc_relabelling ⟨xl, xr, xL, xR⟩ ⟨yl, yr, yL, yR⟩ } }
end
using_well_founded { dec_tac := pgame_wf_tac }

theorem add_assoc_equiv {x y z : pgame} : (x + y) + z ≈ x + (y + z) :=
(add_assoc_relabelling x y z).equiv

theorem add_left_neg_le_zero : ∀ (x : pgame), -x + x ≤ 0
| ⟨xl, xr, xL, xR⟩ :=
le_zero.2 $ λ i, begin
  cases i,
  { -- If Left played in -x, Right responds with the same move in x.
    refine ⟨@to_right_moves_add _ ⟨_, _, _, _⟩ (sum.inr i), _⟩,
    convert @add_left_neg_le_zero (xR i),
    apply add_move_right_inr },
  { -- If Left in x, Right responds with the same move in -x.
    dsimp,
    refine ⟨@to_right_moves_add ⟨_, _, _, _⟩ _ (sum.inl i), _⟩,
    convert @add_left_neg_le_zero (xL i),
    apply add_move_right_inl }
end

theorem zero_le_add_left_neg (x : pgame) : 0 ≤ -x + x :=
begin
  rw [←neg_le_neg_iff, pgame.neg_zero],
  exact neg_add_le.trans (add_left_neg_le_zero _)
end

theorem add_left_neg_equiv (x : pgame) : -x + x ≈ 0 :=
⟨add_left_neg_le_zero x, zero_le_add_left_neg x⟩

theorem add_right_neg_le_zero (x : pgame) : x + -x ≤ 0 :=
add_comm_le.trans (add_left_neg_le_zero x)

theorem zero_le_add_right_neg (x : pgame) : 0 ≤ x + -x :=
(zero_le_add_left_neg x).trans add_comm_le

theorem add_right_neg_equiv (x : pgame) : x + -x ≈ 0 :=
⟨add_right_neg_le_zero x, zero_le_add_right_neg x⟩

theorem sub_self_equiv : ∀ x, x - x ≈ 0 :=
add_right_neg_equiv

private lemma add_le_add_right' : ∀ {x y z : pgame} (h : x ≤ y), x + z ≤ y + z
| (mk xl xr xL xR) (mk yl yr yL yR) (mk zl zr zL zR) :=
λ h, begin
  refine le_def.2 ⟨λ i, _, λ i, _⟩;
  cases i,
  { rw le_def at h,
    cases h,
    rcases h_left i with ⟨i', ih⟩ | ⟨j, jh⟩,
    { exact or.inl ⟨to_left_moves_add (sum.inl i'), add_le_add_right' ih⟩ },
    { refine or.inr ⟨to_right_moves_add (sum.inl j), _⟩,
      convert add_le_add_right' jh,
      apply add_move_right_inl } },
  { exact or.inl ⟨@to_left_moves_add _ ⟨_, _, _, _⟩ (sum.inr i), add_le_add_right' h⟩ },
  { rw le_def at h,
    cases h,
    rcases h_right i with ⟨i, ih⟩ | ⟨j', jh⟩,
    { refine or.inl ⟨to_left_moves_add (sum.inl i), _⟩,
      convert add_le_add_right' ih,
      apply add_move_left_inl },
    { exact or.inr ⟨to_right_moves_add (sum.inl j'), add_le_add_right' jh⟩ } },
  { exact or.inr ⟨@to_right_moves_add _ ⟨_, _, _, _⟩ (sum.inr i), add_le_add_right' h⟩ }
end
using_well_founded { dec_tac := pgame_wf_tac }

instance covariant_class_swap_add_le : covariant_class pgame pgame (swap (+)) (≤) :=
⟨λ x y z, add_le_add_right'⟩

instance covariant_class_add_le : covariant_class pgame pgame (+) (≤) :=
⟨λ x y z h, (add_comm_le.trans (add_le_add_right h x)).trans add_comm_le⟩

instance contravariant_class_swap_add_le : contravariant_class pgame pgame (swap (+)) (≤) :=
⟨λ x y z h,
calc y ≤ y + 0        : (add_zero_relabelling _).symm.le
   ... ≤ y + (x + -x) : add_le_add_left (zero_le_add_right_neg x) _
   ... ≤ y + x + -x   : (add_assoc_relabelling _ _ _).symm.le
   ... ≤ z + x + -x   : add_le_add_right h _
   ... ≤ z + (x + -x) : (add_assoc_relabelling _ _ _).le
   ... ≤ z + 0        : add_le_add_left (add_right_neg_le_zero x) _
   ... ≤ z            : (add_zero_relabelling _).le⟩

@[simp] theorem cmp_add_right (x y z : pgame) : cmp (x + z) (y + z) = cmp x y :=
by { rw cmp_eq_iff_le_iff_le, simp }

@[simp] theorem add_lf_add_iff_right (x) {y z : pgame} : y + x ⧏ z + x ↔ y ⧏ z :=
lf_iff_lf_of_cmp_eq (cmp_add_right y z x)
private theorem add_lt_add_iff_right' (x) {y z : pgame} : y + x < z + x ↔ y < z :=
lt_iff_lt_of_cmp_eq (cmp_add_right y z x)
@[simp] theorem add_equiv_add_iff_right (x) {y z : pgame} : y + x ≈ z + x ↔ y ≈ z :=
equiv_iff_equiv_of_cmp_eq (cmp_add_right y z x)
@[simp] theorem add_fuzzy_add_iff_right (x) {y z : pgame} : y + x ∥ z + x ↔ y ∥ z :=
fuzzy_iff_fuzzy_of_cmp_eq (cmp_add_right y z x)

instance contravariant_class_swap_add_lt : contravariant_class pgame pgame (swap (+)) (<) :=
⟨λ x y z, (add_lt_add_iff_right' x).1⟩

instance covariant_class_swap_add_lt : covariant_class pgame pgame (swap (+)) (<) :=
⟨λ x y z, (add_lt_add_iff_right' x).2⟩

theorem add_lf_add_right {y z : pgame} (h : y ⧏ z) (x) : y + x ⧏ z + x :=
(add_lf_add_iff_right x).2 h
theorem add_equiv_add_right {y z : pgame} (h : y ≈ z) (x) : y + x ≈ z + x :=
(add_equiv_add_iff_right x).2 h
theorem add_fuzzy_add_right {y z : pgame} (h : y ∥ z) (x) : y + x ∥ z + x :=
(add_fuzzy_add_iff_right x).2 h

theorem lf_of_add_lf_add_right {x y z : pgame} : y + x ⧏ z + x → y ⧏ z :=
(add_lf_add_iff_right x).1
theorem equiv_of_add_equiv_add_right {x y z : pgame} : y + x ≈ z + x → y ≈ z :=
(add_equiv_add_iff_right x).1
theorem fuzzy_of_add_fuzzy_add_right {x y z : pgame} : y + x ∥ z + x → y ∥ z :=
(add_fuzzy_add_iff_right x).1

@[simp] theorem cmp_add_left (x y z : pgame) : cmp (x + y) (x + z) = cmp y z :=
by rw [cmp_congr add_comm_equiv add_comm_equiv, cmp_add_right]

private theorem add_le_add_iff_left' (x) {y z : pgame} : x + y ≤ x + z ↔ y ≤ z :=
le_iff_le_of_cmp_eq (cmp_add_left x y z)
@[simp] theorem add_lf_add_iff_left (x) {y z : pgame} : x + y ⧏ x + z ↔ y ⧏ z :=
lf_iff_lf_of_cmp_eq (cmp_add_left x y z)
private theorem add_lt_add_iff_left' (x) {y z : pgame} : x + y < x + z ↔ y < z :=
lt_iff_lt_of_cmp_eq (cmp_add_left x y z)
@[simp] theorem add_equiv_add_iff_left (x) {y z : pgame} : x + y ≈ x + z ↔ y ≈ z :=
equiv_iff_equiv_of_cmp_eq (cmp_add_left x y z)
@[simp] theorem add_fuzzy_add_iff_left (x) {y z : pgame} : x + y ∥ x + z ↔ y ∥ z :=
fuzzy_iff_fuzzy_of_cmp_eq (cmp_add_left x y z)

instance contravariant_class_add_le : contravariant_class pgame pgame (+) (≤) :=
⟨λ x y z, (add_le_add_iff_left' x).1⟩

instance contravariant_class_add_lt : contravariant_class pgame pgame (+) (<) :=
⟨λ x y z, (add_lt_add_iff_left' x).1⟩

instance covariant_class_add_lt : covariant_class pgame pgame (+) (<) :=
⟨λ x y z, (add_lt_add_iff_left' x).2⟩

theorem add_lf_add_left {y z : pgame} (h : y ⧏ z) (x) : x + y ⧏ x + z :=
(add_lf_add_iff_left x).2 h
theorem add_equiv_add_left {y z : pgame} (h : y ≈ z) (x) : x + y ≈ x + z :=
(add_equiv_add_iff_left x).2 h
theorem add_fuzzy_add_left {y z : pgame} (h : y ∥ z) (x) : x + y ∥ x + z :=
(add_fuzzy_add_iff_left x).2 h

theorem lf_of_add_lf_add_left {x y z : pgame} : x + y ⧏ x + z → y ⧏ z :=
(add_lf_add_iff_left x).1
theorem equiv_of_add_equiv_add_left {x y z : pgame} : x + y ≈ x + z → y ≈ z :=
(add_equiv_add_iff_left x).1
theorem fuzzy_of_add_fuzzy_add_left {x y z : pgame} : x + y ∥ x + z → y ∥ z :=
(add_fuzzy_add_iff_left x).1

theorem add_lf_add_of_lf_of_le {w x y z : pgame} (hwx : w ⧏ x) (hyz : y ≤ z) : w + y ⧏ x + z :=
lf_of_lf_of_le (add_lf_add_right hwx y) (add_le_add_left hyz x)

theorem add_lf_add_of_le_of_lf {w x y z : pgame} (hwx : w ≤ x) (hyz : y ⧏ z) : w + y ⧏ x + z :=
lf_of_le_of_lf (add_le_add_right hwx y) (add_lf_add_left hyz x)

theorem add_congr {w x y z : pgame} (h₁ : w ≈ x) (h₂ : y ≈ z) : w + y ≈ x + z :=
(add_equiv_add_right h₁ y).trans (add_equiv_add_left h₂ x)

theorem sub_congr {w x y z : pgame} (h₁ : w ≈ x) (h₂ : y ≈ z) : w - y ≈ x - z :=
add_congr h₁ (neg_equiv_neg_iff.2 h₂)

@[simp] theorem cmp_sub_right (x y z : pgame) : cmp (x - z) (y - z) = cmp x y :=
cmp_add_right x y _

@[simp] theorem sub_le_sub_iff_right (x) {y z : pgame} : y - x ≤ z - x ↔ y ≤ z :=
le_iff_le_of_cmp_eq (cmp_sub_right y z x)
@[simp] theorem sub_lf_sub_iff_right (x) {y z : pgame} : y - x ⧏ z - x ↔ y ⧏ z :=
lf_iff_lf_of_cmp_eq (cmp_sub_right y z x)
@[simp] theorem sub_lt_sub_iff_right (x) {y z : pgame} : y - x < z - x ↔ y < z :=
lt_iff_lt_of_cmp_eq (cmp_sub_right y z x)
@[simp] theorem sub_equiv_sub_iff_right (x) {y z : pgame} : y - x ≈ z - x ↔ y ≈ z :=
equiv_iff_equiv_of_cmp_eq (cmp_sub_right y z x)
@[simp] theorem sub_fuzzy_sub_iff_right (x) {y z : pgame} : y - x ∥ z - x ↔ y ∥ z :=
fuzzy_iff_fuzzy_of_cmp_eq (cmp_sub_right y z x)

theorem sub_le_sub_right {y z : pgame} (h : y ≤ z) (x) : y - x ≤ z - x :=
(sub_le_sub_iff_right x).2 h
theorem sub_lf_sub_right {y z : pgame} (h : y ⧏ z) (x) : y - x ⧏ z - x :=
(sub_lf_sub_iff_right x).2 h
theorem sub_lt_sub_right {y z : pgame} (h : y < z) (x) : y - x < z - x :=
(sub_lt_sub_iff_right x).2 h
theorem sub_equiv_sub_right {y z : pgame} (h : y ≈ z) (x) : y - x ≈ z - x :=
(sub_equiv_sub_iff_right x).2 h
theorem sub_fuzzy_sub_right {y z : pgame} (h : y ∥ z) (x) : y + x ∥ z + x :=
(add_fuzzy_add_iff_right x).2 h

@[simp] theorem cmp_sub_left (x y z : pgame) : cmp (x - y) (x - z) = cmp z y :=
(cmp_add_left x _ _).trans (cmp_neg y z)

@[simp] theorem sub_le_sub_iff_left (x) {y z : pgame} : x - y ≤ x - z ↔ z ≤ y :=
le_iff_le_of_cmp_eq (cmp_sub_left x y z)
@[simp] theorem sub_lf_sub_iff_left (x) {y z : pgame} : x - y ⧏ x - z ↔ z ⧏ y :=
lf_iff_lf_of_cmp_eq (cmp_sub_left x y z)
@[simp] theorem sub_lt_sub_iff_left (x) {y z : pgame} : x - y < x - z ↔ z < y :=
lt_iff_lt_of_cmp_eq (cmp_sub_left x y z)
@[simp] theorem sub_equiv_sub_iff_left (x) {y z : pgame} : x - y ≈ x - z ↔ y ≈ z :=
equiv_iff_equiv_of_cmp_eq' (cmp_sub_left x y z)
@[simp] theorem sub_fuzzy_sub_iff_left (x) {y z : pgame} : x - y ∥ x - z ↔ y ∥ z :=
fuzzy_iff_fuzzy_of_cmp_eq' (cmp_sub_left x y z)

theorem sub_le_sub_left {y z : pgame} (h : z ≤ y) (x) : x - y ≤ x - z :=
(sub_le_sub_iff_left x).2 h
theorem sub_lf_sub_left {y z : pgame} (h : z ⧏ y) (x) : x - y ⧏ x - z :=
(sub_lf_sub_iff_left x).2 h
theorem sub_lt_sub_left {y z : pgame} (h : z < y) (x) : x - y < x - z :=
(sub_lt_sub_iff_left x).2 h
theorem sub_equiv_sub_left {y z : pgame} (h : y ≈ z) (x) : x - y ≈ x - z :=
(sub_equiv_sub_iff_left x).2 h
theorem sub_fuzzy_sub_left {y z : pgame} (h : y ∥ z) (x) : x + y ∥ x + z :=
(add_fuzzy_add_iff_left x).2 h

theorem cmp_eq_cmp_zero_sub (x y : pgame) : cmp x y = cmp 0 (y - x) :=
by rw [cmp_congr (sub_self_equiv x).symm (equiv_refl _), cmp_sub_right]

theorem le_iff_zero_le_sub {x y : pgame} : x ≤ y ↔ 0 ≤ y - x :=
le_iff_le_of_cmp_eq (cmp_eq_cmp_zero_sub x y)
theorem lf_iff_zero_lf_sub {x y : pgame} : x ⧏ y ↔ 0 ⧏ y - x :=
lf_iff_lf_of_cmp_eq (cmp_eq_cmp_zero_sub x y)
theorem lt_iff_zero_lt_sub {x y : pgame} : x < y ↔ 0 < y - x :=
lt_iff_lt_of_cmp_eq (cmp_eq_cmp_zero_sub x y)
theorem equiv_iff_zero_equiv_sub {x y : pgame} : x ≈ y ↔ 0 ≈ y - x :=
equiv_iff_equiv_of_cmp_eq (cmp_eq_cmp_zero_sub x y)
theorem fuzzy_iff_zero_fuzzy_sub {x y : pgame} : x ∥ y ↔ 0 ∥ y - x :=
fuzzy_iff_fuzzy_of_cmp_eq (cmp_eq_cmp_zero_sub x y)

theorem cmp_eq_cmp_sub_zero (x y : pgame) : cmp x y = cmp (x - y) 0 :=
by rw [cmp_eq_cmp_iff_cmp_eq_cmp, cmp_eq_cmp_zero_sub]

theorem le_iff_sub_le_zero {x y : pgame} : x ≤ y ↔ x - y ≤ 0 :=
le_iff_le_of_cmp_eq (cmp_eq_cmp_sub_zero x y)
theorem lf_iff_sub_lf_zero {x y : pgame} : x ⧏ y ↔ x - y ⧏ 0 :=
lf_iff_lf_of_cmp_eq (cmp_eq_cmp_sub_zero x y)
theorem lt_iff_sub_lt_zero {x y : pgame} : x < y ↔ x - y < 0 :=
lt_iff_lt_of_cmp_eq (cmp_eq_cmp_sub_zero x y)
theorem equiv_iff_sub_equiv_zero {x y : pgame} : x ≈ y ↔ x - y ≈ 0 :=
equiv_iff_equiv_of_cmp_eq (cmp_eq_cmp_sub_zero x y)
theorem fuzzy_iff_sub_fuzzy_zero {x y : pgame} : x ∥ y ↔ x - y ∥ 0 :=
fuzzy_iff_fuzzy_of_cmp_eq (cmp_eq_cmp_sub_zero x y)

/-! ### Special pre-games -/

/-- The pre-game `star`, which is fuzzy with zero. -/
def star : pgame.{u} := ⟨punit, punit, λ _, 0, λ _, 0⟩

@[simp] theorem star_left_moves : star.left_moves = punit := rfl
@[simp] theorem star_right_moves : star.right_moves = punit := rfl

@[simp] theorem star_move_left (x) : star.move_left x = 0 := rfl
@[simp] theorem star_move_right (x) : star.move_right x = 0 := rfl

instance unique_star_left_moves : unique star.left_moves := punit.unique
instance unique_star_right_moves : unique star.right_moves := punit.unique

theorem star_fuzzy_zero : star ∥ 0 :=
⟨by { rw lf_zero, use default, rintros ⟨⟩ }, by { rw zero_lf, use default, rintros ⟨⟩ }⟩

@[simp] theorem neg_star : -star = star :=
by simp [star]

@[simp] theorem zero_lt_one : (0 : pgame) < 1 :=
lt_of_le_of_lf (zero_le_of_is_empty_right_moves 1) (zero_lf_le.2 ⟨default, le_rfl⟩)

instance : zero_le_one_class pgame := ⟨zero_lt_one.le⟩

@[simp] theorem zero_lf_one : (0 : pgame) ⧏ 1 :=
zero_lt_one.lf

end pgame
