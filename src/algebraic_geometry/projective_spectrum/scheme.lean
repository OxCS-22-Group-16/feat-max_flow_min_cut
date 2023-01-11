/-
Copyright (c) 2022 Jujian Zhang. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Jujian Zhang
-/
import algebraic_geometry.projective_spectrum.structure_sheaf
import algebraic_geometry.Spec
import ring_theory.graded_algebra.radical
import ring_theory.localization.cardinality

/-!
# Proj as a scheme

This file is to prove that `Proj` is a scheme.

## Notation

* `Proj`      : `Proj` as a locally ringed space
* `Proj.T`    : the underlying topological space of `Proj`
* `Proj| U`   : `Proj` restricted to some open set `U`
* `Proj.T| U` : the underlying topological space of `Proj` restricted to open set `U`
* `pbo f`     : basic open set at `f` in `Proj`
* `Spec`      : `Spec` as a locally ringed space
* `Spec.T`    : the underlying topological space of `Spec`
* `sbo g`     : basic open set at `g` in `Spec`
* `A⁰_x`      : the degree zero part of localized ring `Aₓ`

## Implementation

In `src/algebraic_geometry/projective_spectrum/structure_sheaf.lean`, we have given `Proj` a
structure sheaf so that `Proj` is a locally ringed space. In this file we will prove that `Proj`
equipped with this structure sheaf is a scheme. We achieve this by using an affine cover by basic
open sets in `Proj`, more specifically:

1. We prove that `Proj` can be covered by basic open sets at homogeneous element of positive degree.
2. We prove that for any homogeneous element `f : A` of positive degree `m`, `Proj.T | (pbo f)` is
    homeomorphic to `Spec.T A⁰_f`:
  - forward direction `to_Spec`:
    for any `x : pbo f`, i.e. a relevant homogeneous prime ideal `x`, send it to
    `A⁰_f ∩ span {g / 1 | g ∈ x}` (see `Proj_iso_Spec_Top_component.to_Spec.carrier`). This ideal is
    prime, the proof is in `Proj_iso_Spec_Top_component.to_Spec.to_fun`. The fact that this function
    is continuous is found in `Proj_iso_Spec_Top_component.to_Spec`
  - backward direction `from_Spec`:
    for any `q : Spec A⁰_f`, we send it to `{a | ∀ i, aᵢᵐ/fⁱ ∈ q}`; we need this to be a
    homogeneous prime ideal that is relevant.
    * This is in fact an ideal, the proof can be found in
      `Proj_iso_Spec_Top_component.from_Spec.carrier.as_ideal`;
    * This ideal is also homogeneous, the proof can be found in
      `Proj_iso_Spec_Top_component.from_Spec.carrier.as_ideal.homogeneous`;
    * This ideal is relevant, the proof can be found in
      `Proj_iso_Spec_Top_component.from_Spec.carrier.relevant`;
    * This ideal is prime, the proof can be found in
      `Proj_iso_Spec_Top_component.from_Spec.carrier.prime`.
    Hence we have a well defined function `Spec.T A⁰_f → Proj.T | (pbo f)`, this function is called
    `Proj_iso_Spec_Top_component.from_Spec.to_fun`. But to prove the continuity of this function,
    we need to prove `from_Spec ∘ to_Spec` and `to_Spec ∘ from_Spec` are both identities (TBC).

## Main Definitions and Statements

* `degree_zero_part`: the degree zero part of the localized ring `Aₓ` where `x` is a homogeneous
  element of degree `n` is the subring of elements of the form `a/f^m` where `a` has degree `mn`.

For a homogeneous element `f` of degree `n`
* `Proj_iso_Spec_Top_component.to_Spec`: `forward f` is the
  continuous map between `Proj.T| pbo f` and `Spec.T A⁰_f`
* `Proj_iso_Spec_Top_component.to_Spec.preimage_eq`: for any `a: A`, if `a/f^m` has degree zero,
  then the preimage of `sbo a/f^m` under `to_Spec f` is `pbo f ∩ pbo a`.

* [Robin Hartshorne, *Algebraic Geometry*][Har77]: Chapter II.2 Proposition 2.5
-/

noncomputable theory

namespace algebraic_geometry

open_locale direct_sum big_operators pointwise big_operators
open direct_sum set_like.graded_monoid localization finset (hiding mk_zero)

variables {R A : Type*}
variables [comm_ring R] [comm_ring A] [algebra R A]

variables (𝒜 : ℕ → submodule R A)
variables [graded_algebra 𝒜]

open Top topological_space
open category_theory opposite
open projective_spectrum.structure_sheaf
open _root_.homogeneous_localization localization is_localization (hiding away)

local notation `Proj` := Proj.to_LocallyRingedSpace 𝒜
-- `Proj` as a locally ringed space
local notation `Proj.T` := Proj .1.1.1
-- the underlying topological space of `Proj`
local notation `Proj| ` U := Proj .restrict (opens.open_embedding (U : opens Proj.T))
-- `Proj` restrict to some open set
local notation `Proj.T| ` U :=
  (Proj .restrict (opens.open_embedding (U : opens Proj.T))).to_SheafedSpace.to_PresheafedSpace.1
-- the underlying topological space of `Proj` restricted to some open set
local notation `pbo ` x := projective_spectrum.basic_open 𝒜 x
-- basic open sets in `Proj`
local notation `sbo ` f := prime_spectrum.basic_open f
-- basic open sets in `Spec`
local notation `Spec ` ring := Spec.LocallyRingedSpace_obj (CommRing.of ring)
-- `Spec` as a locally ringed space
local notation `Spec.T ` ring :=
  (Spec.LocallyRingedSpace_obj (CommRing.of ring)).to_SheafedSpace.to_PresheafedSpace.1
-- the underlying topological space of `Spec`
local notation `A⁰_ ` f := homogeneous_localization.away 𝒜 f

namespace Proj_iso_Spec_Top_component

/-
This section is to construct the homeomorphism between `Proj` restricted at basic open set at
a homogeneous element `x` and `Spec A⁰ₓ` where `A⁰ₓ` is the degree zero part of the localized
ring `Aₓ`.
-/

namespace to_Spec

open ideal

-- This section is to construct the forward direction :
-- So for any `x` in `Proj| (pbo f)`, we need some point in `Spec A⁰_f`, i.e. a prime ideal,
-- and we need this correspondence to be continuous in their Zariski topology.

variables {𝒜} {f : A} {m : ℕ} (f_deg : f ∈ 𝒜 m) (x : Proj| (pbo f))

/--For any `x` in `Proj| (pbo f)`, the corresponding ideal in `Spec A⁰_f`. This fact that this ideal
is prime is proven in `Top_component.forward.to_fun`-/
def carrier : ideal (A⁰_ f) :=
ideal.comap (algebra_map (A⁰_ f) (away f))
  (ideal.span $ algebra_map A (away f) '' x.val.as_homogeneous_ideal)

lemma mem_carrier_iff (z : A⁰_ f) :
  z ∈ carrier 𝒜 x ↔
  z.val ∈ ideal.span (algebra_map A (away f) '' x.1.as_homogeneous_ideal) :=
iff.rfl

lemma mem_carrier.clear_denominator' [decidable_eq (away f)]
  {z : localization.away f}
  (hz : z ∈ span ((algebra_map A (away f)) '' x.val.as_homogeneous_ideal)) :
  ∃ (c : algebra_map A (away f) '' x.1.as_homogeneous_ideal →₀ away f)
    (N : ℕ) (acd : Π y ∈ c.support.image c, A),
    f ^ N • z = algebra_map A (away f)
      (∑ i in c.support.attach, acd (c i) (finset.mem_image.mpr ⟨i, ⟨i.2, rfl⟩⟩) * i.1.2.some) :=
begin
  rw [←submodule_span_eq, finsupp.span_eq_range_total, linear_map.mem_range] at hz,
  rcases hz with ⟨c, eq1⟩,
  rw [finsupp.total_apply, finsupp.sum] at eq1,
  obtain ⟨⟨_, N, rfl⟩, hN⟩ := is_localization.exist_integer_multiples_of_finset (submonoid.powers f)
    (c.support.image c),
  choose acd hacd using hN,

  refine ⟨c, N, acd, _⟩,
  rw [← eq1, smul_sum, map_sum, ← sum_attach],
  congr' 1,
  ext i,
  rw [_root_.map_mul, hacd, (classical.some_spec i.1.2).2, smul_eq_mul, smul_mul_assoc],
  refl
end

lemma mem_carrier.clear_denominator [decidable_eq (away f)]
  {z : A⁰_ f} (hz : z ∈ carrier 𝒜 x) :
  ∃ (c : algebra_map A (away f) '' x.1.as_homogeneous_ideal →₀ away f)
    (N : ℕ) (acd : Π y ∈ c.support.image c, A),
    f ^ N • z.val = algebra_map A (away f)
      (∑ i in c.support.attach, acd (c i) (finset.mem_image.mpr ⟨i, ⟨i.2, rfl⟩⟩) * i.1.2.some) :=
mem_carrier.clear_denominator' x $ (mem_carrier_iff 𝒜 x z).mpr hz


section carrier'
/--
The underlying set of `to_Spec.carrier` is equal to the underlying set of ideal generated by
elements in `A_f` whose numerator is in `x` and has the same degree as the denominator.
-/
def carrier' : ideal (A⁰_ f) :=
ideal.span { z | ∃ ⦃s F : A⦄ (hs : s ∈ x.1.as_homogeneous_ideal) (n : ℕ)
  (s_mem : s ∈ 𝒜 n) (F_mem1 : F ∈ 𝒜 n) (F_mem2 : F ∈ submonoid.powers f),
  z = quotient.mk' ⟨_, ⟨s, s_mem⟩, ⟨F, F_mem1⟩, F_mem2⟩ }

lemma carrier_eq_carrier' :
  carrier 𝒜 x = carrier' 𝒜 x :=
begin
  classical, ext z, split; intros hz,
  { rw mem_carrier_iff at hz,
    change z ∈ ideal.span _,
    let k : ℕ := z.denom_mem.some, have hk : f^k = z.denom := z.denom_mem.some_spec,
    erw [←ideal.submodule_span_eq, finsupp.span_eq_range_total, set.mem_range] at hz,
    obtain ⟨c, eq1⟩ := hz, erw [finsupp.total_apply, finsupp.sum] at eq1,

    suffices mem1 : z.num ∈ x.1.as_homogeneous_ideal,
    { apply ideal.subset_span _,
      refine ⟨_, _, mem1, _, z.num_mem_deg, z.denom_mem_deg, z.denom_mem, _⟩,
      rw [ext_iff_val, val_mk', eq_num_div_denom], refl },

    obtain ⟨⟨_, N, rfl⟩, hN⟩ := exist_integer_multiples_of_finset (submonoid.powers f)
      (finset.image (λ i, c i * i.1) c.support),
    choose acd hacd using hN,
    change ∀ _ _, localization.mk (acd _ _) _ = _ at hacd,
    have prop1 : ∀ i, i ∈ c.support → c i * i.1 ∈ (finset.image (λ i, c i * i.1) c.support),
    { intros i hi, rw finset.mem_image, refine ⟨_, hi, rfl⟩, },
    have eq3 : (mk (num z * f ^ N) 1 : localization.away f) =
    mk (∑ i in c.support.attach,
       f ^ k * acd (c i.val * i.val.val) (prop1 i.1 i.2)) 1,
    { rw [mk_sum], rw [z.eq_num_div_denom] at eq1, simp_rw [←hk] at eq1,
      convert_to _ = ∑ i in c.support.attach, (localization.mk _ 1 : localization.away f) * mk _ 1,
      { refine finset.sum_congr rfl (λ i hi, _), work_on_goal 3
        { rw [mk_mul, show (1 * 1 : submonoid.powers f) = 1, from one_mul _], }, },
      simp_rw [←finset.mul_sum, hacd, subtype.coe_mk, ←finset.smul_sum],
      rw [algebra.smul_def, ←mul_assoc],
      have eq1' := congr_arg ((*) (mk (f^k * f^N) 1) :
        localization.away f → localization.away f) eq1,
      rw [mk_mul, one_mul] at eq1', convert eq1'.symm using 1,
      { rw [mk_eq_mk', is_localization.eq], refine ⟨1, _⟩,
        simp only [submonoid.coe_one, one_mul, mul_one, subtype.coe_mk], ring1, },
      { congr' 1, swap, { nth_rewrite 1 [←finset.sum_attach], refl, },
        change localization.mk _ _ * mk (f^N) 1 = _,
        rw [mk_mul, mk_eq_mk', is_localization.eq], refine ⟨1, _⟩,
        simp only [submonoid.coe_one, one_mul, mul_one, subtype.coe_mk], }, },
    simp only [localization.mk_eq_mk', is_localization.eq] at eq3,
    obtain ⟨⟨_, ⟨l, rfl⟩⟩, eq3⟩ := eq3,
    erw [mul_one, subtype.coe_mk, mul_one] at eq3,
    suffices : (∑ i in c.support.attach, (f^k * (acd (c i.1 * i.1.1) (prop1 i.1 i.2)))) * f^l ∈
      x.1.as_homogeneous_ideal,
    { erw ←eq3 at this,
      rcases x.1.is_prime.mem_or_mem this with H1 | H3,
      rcases x.1.is_prime.mem_or_mem H1 with H1 | H2,
      exacts [H1, false.elim ((projective_spectrum.mem_basic_open 𝒜 _ _).mp x.2
        (x.1.is_prime.mem_of_pow_mem _ H2)), false.elim
        ((projective_spectrum.mem_basic_open 𝒜 _ _).mp x.2 (x.1.is_prime.mem_of_pow_mem _ H3))], },

    refine ideal.mul_mem_right _ _ (ideal.sum_mem _ (λ j hj, ideal.mul_mem_left _ _ _)),
    set g := classical.some j.1.2 with g_eq,
    have mem3 : g ∈ x.1.as_homogeneous_ideal := (classical.some_spec j.1.2).1,
    have eq3 : j.1.1 = localization.mk g 1 := (classical.some_spec j.1.2).2.symm,
    have eq4 := (hacd (c j.1 * j.1.1) (prop1 j.1 j.2)),
    simp_rw [algebra.smul_def] at eq4,
    have eq5 : ∃ (a : A) (z : ℕ), c j.1 = mk a ⟨f^z, ⟨z, rfl⟩⟩,
    { induction (c j.1) using localization.induction_on with data,
      rcases data with ⟨a, ⟨_, ⟨z, rfl⟩⟩⟩,
      refine ⟨a, z, rfl⟩, },
    obtain ⟨α, z, hz⟩ := eq5,
    have eq6 : (mk (acd (c j.1 * j.1.1) (prop1 j.1 j.2)) 1 : localization.away f) =
      mk (α * g * f^N) ⟨f^z, ⟨z, rfl⟩⟩,
    { erw [eq4, subtype.coe_mk, hz, eq3, mk_mul, mk_mul, one_mul, mul_one], congr' 1,
      change (f^N) * _ = _, ring1, },
    simp only [localization.mk_eq_mk', is_localization.eq] at eq6,
    obtain ⟨⟨_, ⟨v, rfl⟩⟩, eq6⟩ := eq6,
    simp only [subtype.coe_mk, submonoid.coe_one, mul_one] at eq6,

    have mem4 : α * g * f ^ N * f ^ v ∈ x.1.as_homogeneous_ideal,
    { refine ideal.mul_mem_right _ _ (ideal.mul_mem_right _ _ (ideal.mul_mem_left _ _ mem3)) },
    erw ←eq6 at mem4,

    rcases x.1.is_prime.mem_or_mem mem4 with H1 | H3,
    rcases x.1.is_prime.mem_or_mem H1 with H1 | H2,
    exacts [H1, false.elim ((projective_spectrum.mem_basic_open 𝒜 _ _).mp x.2
      (x.1.is_prime.mem_of_pow_mem _ H2)), false.elim
      ((projective_spectrum.mem_basic_open 𝒜 _ _).mp x.2 (x.1.is_prime.mem_of_pow_mem _ H3))], },

  { change z ∈ ideal.span _ at hz, rw mem_carrier_iff,
    erw [←ideal.submodule_span_eq, finsupp.span_eq_range_total, set.mem_range] at hz,
    obtain ⟨c, eq1⟩ := hz, erw [finsupp.total_apply, finsupp.sum] at eq1,
    erw [←eq1, homogeneous_localization.sum_val],
    convert submodule.sum_mem _ (λ j hj, _),
    rw [smul_eq_mul, mul_val],
    obtain ⟨s, _, hs, n, s_mem, F_mem1, ⟨l, rfl⟩, hj2⟩ := j.2,
    convert ideal.mul_mem_left _ _ _,
    rw [←subtype.val_eq_coe, hj2, val_mk'],
    erw show (mk s ⟨f ^ l, ⟨_, rfl⟩⟩ : localization.away f) = mk 1 ⟨f^l, ⟨_, rfl⟩⟩ * mk s 1,
    { rw [mk_mul, one_mul, mul_one], },
    convert ideal.mul_mem_left _ _ _,
    apply ideal.subset_span, exact ⟨s, hs, rfl⟩, },
end

end carrier'

lemma disjoint :
  (disjoint (x.1.as_homogeneous_ideal.to_ideal : set A) (submonoid.powers f : set A)) :=
begin
  by_contra rid,
  rw [set.not_disjoint_iff] at rid,
  choose g hg using rid,
  obtain ⟨hg1, ⟨k, rfl⟩⟩ := hg,
  by_cases k_ineq : 0 < k,
  { erw x.1.is_prime.pow_mem_iff_mem _ k_ineq at hg1,
    exact x.2 hg1 },
  { erw [show k = 0, by linarith, pow_zero, ←ideal.eq_top_iff_one] at hg1,
    apply x.1.is_prime.1,
    exact hg1 },
end

lemma carrier_ne_top :
  carrier 𝒜 x ≠ ⊤ :=
begin
  have eq_top := disjoint x,
  classical,
  contrapose! eq_top,
  obtain ⟨c, N, acd, eq1⟩ := mem_carrier.clear_denominator _ x ((ideal.eq_top_iff_one _).mp eq_top),
  rw [algebra.smul_def, homogeneous_localization.one_val, mul_one] at eq1,
  change localization.mk (f ^ N) 1 = mk (∑ _, _) 1 at eq1,
  simp only [mk_eq_mk', is_localization.eq] at eq1,
  rcases eq1 with ⟨⟨_, ⟨M, rfl⟩⟩, eq1⟩,
  erw [mul_one, mul_one] at eq1,
  change f^_ * f^_ = _ * f^_ at eq1,
  rw set.not_disjoint_iff_nonempty_inter,
  refine ⟨f^N * f^M, eq1.symm ▸ mul_mem_right _ _
    (sum_mem _ (λ i hi, mul_mem_left _ _ _)), ⟨N+M, by rw pow_add⟩⟩,
  generalize_proofs h₁ h₂,
  exact (classical.some_spec h₂).1,
end

variable (f)
/--The function between the basic open set `D(f)` in `Proj` to the corresponding basic open set in
`Spec A⁰_f`. This is bundled into a continuous map in `Top_component.forward`.
-/
def to_fun (x : Proj.T| (pbo f)) : (Spec.T (A⁰_ f)) :=
⟨carrier 𝒜 x, carrier_ne_top x, λ x1 x2 hx12, begin
  classical, simp only [mem_carrier_iff] at hx12 ⊢,
  let J := span (⇑(algebra_map A (away f)) '' x.val.as_homogeneous_ideal),
  suffices h : ∀ (x y : localization.away f), x * y ∈ J → x ∈ J ∨ y ∈ J,
  { rw [homogeneous_localization.mul_val] at hx12, exact h x1.val x2.val hx12, },
  clear' x1 x2 hx12, intros x1 x2 hx12,
  induction x1 using localization.induction_on with data_x1,
  induction x2 using localization.induction_on with data_x2,
  rcases ⟨data_x1, data_x2⟩ with ⟨⟨a1, _, ⟨n1, rfl⟩⟩, ⟨a2, _, ⟨n2, rfl⟩⟩⟩,
  rcases mem_carrier.clear_denominator' x hx12 with ⟨c, N, acd, eq1⟩,
  simp only [algebra.smul_def] at eq1,
  change localization.mk (f ^ N) 1 * (mk _ _ * mk _ _) = mk (∑ _, _) _ at eq1,
  simp only [localization.mk_mul, one_mul] at eq1,
  simp only [mk_eq_mk', is_localization.eq] at eq1,
  rcases eq1 with ⟨⟨_, ⟨M, rfl⟩⟩, eq1⟩,
  rw [submonoid.coe_one, mul_one] at eq1,
  change _ * _ * f^_ = _ * (f^_ * f^_) * f^_ at eq1,

  rcases x.1.is_prime.mem_or_mem (show a1 * a2 * f ^ N * f ^ M ∈ _, from _) with h1|rid2,
  rcases x.1.is_prime.mem_or_mem h1 with h1|rid1,
  rcases x.1.is_prime.mem_or_mem h1 with h1|h2,
  { left, simp only [show (mk a1 ⟨f ^ n1, _⟩ : away f) = mk a1 1 * mk 1 ⟨f^n1, ⟨_, rfl⟩⟩,
      by rw [localization.mk_mul, mul_one, one_mul]],
    exact ideal.mul_mem_right _ _ (ideal.subset_span ⟨_, h1, rfl⟩), },
  { right, simp only [show (mk a2 ⟨f ^ n2, _⟩ : away f) = mk a2 1 * mk 1 ⟨f^n2, ⟨_, rfl⟩⟩,
      by rw [localization.mk_mul, mul_one, one_mul]],
    exact ideal.mul_mem_right _ _ (ideal.subset_span ⟨_, h2, rfl⟩), },
  { exact false.elim (x.2 (x.1.is_prime.mem_of_pow_mem N rid1)), },
  { exact false.elim (x.2 (x.1.is_prime.mem_of_pow_mem M rid2)), },
  { rw [mul_comm _ (f^N), eq1],
    refine mul_mem_right _ _ (mul_mem_right _ _ (sum_mem _ (λ i hi, mul_mem_left _ _ _))),
    generalize_proofs h₁ h₂, exact (classical.some_spec h₂).1 },
end⟩

/-
The preimage of basic open set `D(a/f^n)` in `Spec A⁰_f` under the forward map from `Proj A` to
`Spec A⁰_f` is the basic open set `D(a) ∩ D(f)` in  `Proj A`. This lemma is used to prove that the
forward map is continuous.
-/
lemma preimage_eq (a b : A) (k : ℕ) (a_mem : a ∈ 𝒜 k) (b_mem1 : b ∈ 𝒜 k)
  (b_mem2 : b ∈ submonoid.powers f) : to_fun 𝒜 f ⁻¹'
    ((@prime_spectrum.basic_open (A⁰_ f) _
      (quotient.mk' ⟨k, ⟨a, a_mem⟩, ⟨b, b_mem1⟩, b_mem2⟩)) :
        set (prime_spectrum (homogeneous_localization.away 𝒜 f)))
  = {x | x.1 ∈ (pbo f) ⊓ (pbo a)} :=
begin
  classical,
  ext1 y, split; intros hy,
  { refine ⟨y.2, _⟩,
    rw [set.mem_preimage, opens.mem_coe, prime_spectrum.mem_basic_open] at hy,
    rw projective_spectrum.mem_coe_basic_open,
    intro a_mem_y,
    apply hy,
    rw [to_fun, mem_carrier_iff, homogeneous_localization.val_mk', subtype.coe_mk],
    dsimp, rcases b_mem2 with ⟨k, hk⟩,
    simp only [show (mk a ⟨b, ⟨k, hk⟩⟩ : localization.away f) = mk 1 ⟨f^k, ⟨_, rfl⟩⟩ * mk a 1,
      by { rw [mk_mul, one_mul, mul_one], congr, rw hk }],
    exact ideal.mul_mem_left _ _ (ideal.subset_span ⟨_, a_mem_y, rfl⟩), },
  { change y.1 ∈ _ at hy,
    rcases hy with ⟨hy1, hy2⟩,
    rw projective_spectrum.mem_coe_basic_open at hy1 hy2,
    rw [set.mem_preimage, to_fun, opens.mem_coe, prime_spectrum.mem_basic_open],
    intro rid, dsimp at rid,
    rcases mem_carrier.clear_denominator 𝒜 _ rid with ⟨c, N, acd, eq1⟩,
    rw [algebra.smul_def] at eq1,
    change localization.mk (f^N) 1 * mk _ _ = mk (∑ _, _) _ at eq1,
    rw [mk_mul, one_mul, mk_eq_mk', is_localization.eq] at eq1,
    rcases eq1 with ⟨⟨_, ⟨M, rfl⟩⟩, eq1⟩,
    rw [submonoid.coe_one, mul_one] at eq1,
    simp only [subtype.coe_mk] at eq1,

    rcases y.1.is_prime.mem_or_mem (show a * f ^ N * f ^ M ∈ _, from _) with H1 | H3,
    rcases y.1.is_prime.mem_or_mem H1 with H1 | H2,
    { exact hy2 H1, },
    { exact y.2 (y.1.is_prime.mem_of_pow_mem N H2), },
    { exact y.2 (y.1.is_prime.mem_of_pow_mem M H3), },
    { rw [mul_comm _ (f^N), eq1],
      refine mul_mem_right _ _ (mul_mem_right _ _ (sum_mem _ (λ i hi, mul_mem_left _ _ _))),
      generalize_proofs h₁ h₂, exact (classical.some_spec h₂).1, }, },
end

end to_Spec

section

variable {𝒜}

/--The continuous function between the basic open set `D(f)` in `Proj` to the corresponding basic
open set in `Spec A⁰_f`.
-/
def to_Spec (f : A) : (Proj.T| (pbo f)) ⟶ (Spec.T (A⁰_ f)) :=
{ to_fun := to_Spec.to_fun 𝒜 f,
  continuous_to_fun := begin
    apply is_topological_basis.continuous (prime_spectrum.is_topological_basis_basic_opens),
    rintros _ ⟨⟨k, ⟨a, ha⟩, ⟨b, hb1⟩, ⟨k', hb2⟩⟩, rfl⟩, dsimp,
    erw to_Spec.preimage_eq f a b k ha hb1 ⟨k', hb2⟩,
    refine is_open_induced_iff.mpr ⟨(pbo f).1 ⊓ (pbo a).1, is_open.inter (pbo f).2 (pbo a).2, _⟩,
    ext z, split; intros hz; simpa [set.mem_preimage],
  end }

end

namespace from_Spec

open graded_algebra set_like finset (hiding mk_zero)
open _root_.homogeneous_localization (hiding away)

variables {𝒜} {f : A} {m : ℕ} (f_deg : f ∈ 𝒜 m)

private meta def mem_tac : tactic unit :=
let b : tactic unit :=
  `[exact pow_mem_graded _ (submodule.coe_mem _) <|> exact nat_cast_mem_graded _ _ <|>
    exact pow_mem_graded _ f_deg] in
b <|> `[by repeat { all_goals { apply graded_monoid.mul_mem } }; b]

include f_deg
/--The function from `Spec A⁰_f` to `Proj|D(f)` is defined by `q ↦ {a | aᵢᵐ/fⁱ ∈ q}`, i.e. sending
`q` a prime ideal in `A⁰_f` to the homogeneous prime relevant ideal containing only and all the
elements `a : A` such that for every `i`, the degree 0 element formed by dividing the `m`-th power
of the `i`-th projection of `a` by the `i`-th power of the degree-`m` homogeneous element `f`,
lies in `q`.

The set `{a | aᵢᵐ/fⁱ ∈ q}`
* is an ideal, as proved in `carrier.as_ideal`;
* is homogeneous, as proved in `carrier.as_homogeneous_ideal`;
* is prime, as proved in `carrier.as_ideal.prime`;
* is relevant, as proved in `carrier.relevant`.
-/
def carrier (q : Spec.T (A⁰_ f)) : set A :=
{a | ∀ i, (quotient.mk' ⟨m * i, ⟨proj 𝒜 i a ^ m, by mem_tac⟩,
  ⟨f^i, by rw mul_comm; mem_tac⟩, ⟨_, rfl⟩⟩ : A⁰_ f) ∈ q.1}

lemma mem_carrier_iff (q : Spec.T (A⁰_ f)) (a : A) :
  a ∈ carrier f_deg q ↔
  ∀ i, (quotient.mk' ⟨m * i, ⟨proj 𝒜 i a ^ m, by mem_tac⟩, ⟨f^i, by rw mul_comm; mem_tac⟩, ⟨_, rfl⟩⟩
    : A⁰_ f) ∈ q.1 :=
iff.rfl

lemma mem_carrier_iff' (q : Spec.T (A⁰_ f)) (a : A) :
  a ∈ carrier f_deg q ↔
  ∀ i, (localization.mk (proj 𝒜 i a ^ m) ⟨f^i, ⟨i, rfl⟩⟩ : localization.away f) ∈
    (algebra_map (homogeneous_localization.away 𝒜 f) (localization.away f)) '' q.1.1 :=
(mem_carrier_iff f_deg q a).trans begin
  split; intros h i; specialize h i,
  { rw set.mem_image, refine ⟨_, h, rfl⟩, },
  { rw set.mem_image at h, rcases h with ⟨x, h, hx⟩,
    convert h, rw [ext_iff_val, val_mk'], dsimp only [subtype.coe_mk], rw ←hx, refl, },
end

lemma carrier.add_mem (q : Spec.T (A⁰_ f)) {a b : A} (ha : a ∈ carrier f_deg q)
  (hb : b ∈ carrier f_deg q) :
  a + b ∈ carrier f_deg q :=
begin
  refine λ i, (q.2.mem_or_mem _).elim id id,
  change (quotient.mk' ⟨_, _, _, _⟩ : A⁰_ f) ∈ q.1, dsimp only [subtype.coe_mk],
  simp_rw [←pow_add, map_add, add_pow, mul_comm, ← nsmul_eq_mul],
  let g : ℕ → A⁰_ f := λ j, (m + m).choose j • if h2 : m + m < j then 0 else if h1 : j ≤ m
    then quotient.mk' ⟨m * i, ⟨proj 𝒜 i a^j * proj 𝒜 i b ^ (m - j), _⟩,
      ⟨_, by rw mul_comm; mem_tac⟩, ⟨i, rfl⟩⟩ *
      quotient.mk' ⟨m * i, ⟨proj 𝒜 i b ^ m, by mem_tac⟩, ⟨_, by rw mul_comm; mem_tac⟩, ⟨i, rfl⟩⟩
    else quotient.mk' ⟨m * i, ⟨proj 𝒜 i a ^ m, by mem_tac⟩,
      ⟨_, by rw mul_comm; mem_tac⟩, ⟨i, rfl⟩⟩ * quotient.mk' ⟨m * i, ⟨proj 𝒜 i a ^ (j - m) *
        proj 𝒜 i b ^ (m + m - j), _⟩, ⟨_, by rw mul_comm; mem_tac⟩, ⟨i, rfl⟩⟩,
  rotate,
  { rw (_ : m*i = _), mem_tac, rw [← add_smul, nat.add_sub_of_le h1], refl },
  { rw (_ : m*i = _), mem_tac, rw ←add_smul, congr, zify [le_of_not_lt h2, le_of_not_le h1], abel },
  convert_to ∑ i in range (m + m + 1), g i ∈ q.1, swap,
  { refine q.1.sum_mem (λ j hj, nsmul_mem _ _), split_ifs,
    exacts [q.1.zero_mem, q.1.mul_mem_left _ (hb i), q.1.mul_mem_right _ (ha i)] },
  rw [ext_iff_val, val_mk'],
  change _ = (algebra_map (homogeneous_localization.away 𝒜 f) (localization.away f)) _,
  dsimp only [subtype.coe_mk], rw [map_sum, mk_sum],
  apply finset.sum_congr rfl (λ j hj, _),
  change _ = homogeneous_localization.val _,
  rw [homogeneous_localization.smul_val],
  split_ifs with h2 h1,
  { exact ((finset.mem_range.1 hj).not_le h2).elim },
  all_goals { simp only [mul_val, zero_val, val_mk', subtype.coe_mk, mk_mul, ←smul_mk], congr' 2 },
  { rw [mul_assoc, ←pow_add, add_comm (m-j), nat.add_sub_assoc h1] }, { simp_rw [pow_add], refl },
  { rw [← mul_assoc, ←pow_add, nat.add_sub_of_le (le_of_not_le h1)] }, { simp_rw [pow_add], refl },
end

variables (hm : 0 < m) (q : Spec.T (A⁰_ f))
include hm

lemma carrier.zero_mem : (0 : A) ∈ carrier f_deg q := λ i, begin
  convert submodule.zero_mem q.1 using 1,
  rw [ext_iff_val, val_mk', zero_val], simp_rw [map_zero, zero_pow hm],
  convert localization.mk_zero _ using 1,
end

lemma carrier.smul_mem (c x : A) (hx : x ∈ carrier f_deg q) : c • x ∈ carrier f_deg q :=
begin
  revert c,
  refine direct_sum.decomposition.induction_on 𝒜 _ _ _,
  { rw zero_smul, exact carrier.zero_mem f_deg hm _ },
  { rintros n ⟨a, ha⟩ i,
    simp_rw [subtype.coe_mk, proj_apply, smul_eq_mul, coe_decompose_mul_of_left_mem 𝒜 i ha],
    split_ifs,
    { convert_to (quotient.mk' ⟨_, ⟨a^m, pow_mem_graded m ha⟩, ⟨_, _⟩, ⟨n, rfl⟩⟩ * quotient.mk'
         ⟨_, ⟨proj 𝒜 (i - n) x ^ m, by mem_tac⟩, ⟨_, _⟩, ⟨i - n, rfl⟩⟩ : A⁰_ f) ∈ q.1,
      { erw [ext_iff_val, val_mk', mul_val, val_mk', val_mk', subtype.coe_mk],
        simp_rw [mul_pow, subtype.coe_mk], rw [localization.mk_mul],
        congr, erw [← pow_add, nat.add_sub_of_le h] },
      { exact ideal.mul_mem_left _ _ (hx _), rw [smul_eq_mul, mul_comm], mem_tac, } },
    { simp_rw [zero_pow hm], convert carrier.zero_mem f_deg hm q i, rw [map_zero, zero_pow hm] } },
  { simp_rw add_smul, exact λ _ _, carrier.add_mem f_deg q },
end

/--
For a prime ideal `q` in `A⁰_f`, the set `{a | aᵢᵐ/fⁱ ∈ q}` as an ideal.
-/
def carrier.as_ideal : ideal A :=
{ carrier := carrier f_deg q,
  zero_mem' := carrier.zero_mem f_deg hm q,
  add_mem' := λ a b, carrier.add_mem f_deg q,
  smul_mem' := carrier.smul_mem f_deg hm q }

lemma carrier.as_ideal.homogeneous : (carrier.as_ideal f_deg hm q).is_homogeneous 𝒜 :=
λ i a ha j, (em (i = j)).elim
  (λ h, h ▸ by simpa only [proj_apply, decompose_coe, of_eq_same] using ha _)
  (λ h, begin
    simp only [proj_apply, decompose_of_mem_ne 𝒜 (submodule.coe_mem (decompose 𝒜 a i)) h,
      zero_pow hm], convert carrier.zero_mem f_deg hm q j, rw [map_zero, zero_pow hm],
  end)

/--
For a prime ideal `q` in `A⁰_f`, the set `{a | aᵢᵐ/fⁱ ∈ q}` as a homogeneous ideal.
-/
def carrier.as_homogeneous_ideal : homogeneous_ideal 𝒜 :=
⟨carrier.as_ideal f_deg hm q, carrier.as_ideal.homogeneous f_deg hm q⟩

lemma carrier.denom_not_mem : f ∉ carrier.as_ideal f_deg hm q :=
λ rid, q.is_prime.ne_top $ (ideal.eq_top_iff_one _).mpr
begin
  convert rid m,
  simpa only [ext_iff_val, one_val, proj_apply, decompose_of_mem_same _ f_deg, val_mk'] using
    (mk_self (⟨_, m, rfl⟩ : submonoid.powers f)).symm,
end

lemma carrier.relevant :
  ¬homogeneous_ideal.irrelevant 𝒜 ≤ carrier.as_homogeneous_ideal f_deg hm q :=
λ rid, carrier.denom_not_mem f_deg hm q $ rid $ direct_sum.decompose_of_mem_ne 𝒜 f_deg hm.ne'

lemma carrier.as_ideal.ne_top : (carrier.as_ideal f_deg hm q) ≠ ⊤ :=
λ rid, carrier.denom_not_mem f_deg hm q (rid.symm ▸ submodule.mem_top)

lemma carrier.as_ideal.prime : (carrier.as_ideal f_deg hm q).is_prime :=
(carrier.as_ideal.homogeneous f_deg hm q).is_prime_of_homogeneous_mem_or_mem
  (carrier.as_ideal.ne_top f_deg hm q) $ λ x y ⟨nx, hnx⟩ ⟨ny, hny⟩ hxy,
show (∀ i, _ ∈ _) ∨ ∀ i, _ ∈ _, begin
  rw [← and_forall_ne nx, and_iff_left, ← and_forall_ne ny, and_iff_left],
  { apply q.2.mem_or_mem, convert hxy (nx + ny) using 1,
    simp_rw [proj_apply, decompose_of_mem_same 𝒜 hnx, decompose_of_mem_same 𝒜 hny,
      decompose_of_mem_same 𝒜 (mul_mem hnx hny), mul_pow, pow_add],
    simpa only [ext_iff_val, val_mk', mul_val, mk_mul], },
  all_goals { intros n hn, convert q.1.zero_mem using 1,
    rw [ext_iff_val, val_mk', zero_val], simp_rw [proj_apply, subtype.coe_mk],
    convert mk_zero _, rw [decompose_of_mem_ne 𝒜 _ hn.symm, zero_pow hm],
    { exact hnx <|> exact hny } },
end

variable (f_deg)
/--
The function `Spec A⁰_f → Proj|D(f)` by sending `q` to `{a | aᵢᵐ/fⁱ ∈ q}`.
-/
def to_fun : (Spec.T (A⁰_ f)) → (Proj.T| (pbo f)) :=
λ q, ⟨⟨carrier.as_homogeneous_ideal f_deg hm q, carrier.as_ideal.prime f_deg hm q,
  carrier.relevant f_deg hm q⟩,
  (projective_spectrum.mem_basic_open _ f _).mp $ carrier.denom_not_mem f_deg hm q⟩

end from_Spec

section to_Spec_from_Spec

lemma to_Spec_from_Spec {f : A} {m : ℕ}
  (hm : 0 < m)
  (f_deg : f ∈ 𝒜 m)
  (x : Spec.T (A⁰_ f)) :
  to_Spec.to_fun 𝒜 f (from_Spec.to_fun f_deg hm x) = x :=
begin
ext z, split,
{ intros hz,
  change z ∈ (to_Spec.to_fun _ f (⟨⟨⟨from_Spec.carrier.as_ideal f_deg hm x, _⟩, _, _⟩, _⟩)).1 at hz,
  unfold to_Spec.to_fun at hz,
  dsimp only at hz,
  erw to_Spec.carrier_eq_carrier' at hz,
  unfold to_Spec.carrier' at hz,
  erw [←ideal.submodule_span_eq, finsupp.span_eq_range_total, set.mem_range] at hz,
  obtain ⟨c, eq1⟩ := hz,
  erw [finsupp.total_apply, finsupp.sum] at eq1,
  erw ←eq1,
  apply ideal.sum_mem,
  rintros ⟨j, j_mem⟩ hj,
  change ∃ _, _ at j_mem,

  obtain ⟨s, F, hs, n, s_mem, F_mem1, ⟨k, rfl⟩, rfl⟩ := j_mem,
  apply ideal.mul_mem_left,
  erw [←subtype.val_eq_coe],
  dsimp only,
  dsimp only at hs,
  change ∀ _, _ at hs,
  specialize hs n,
  simp only [graded_algebra.proj_apply, direct_sum.decompose_of_mem_same 𝒜 s_mem] at hs,
  have eq4 : ((quotient.mk' ⟨_, ⟨s, s_mem⟩, ⟨_, F_mem1⟩, ⟨_, rfl⟩⟩ : A⁰_ f) ^ m : A⁰_ f) =
    (quotient.mk' ⟨_, ⟨s^m, set_like.pow_mem_graded _ s_mem⟩, ⟨f^n,
    begin
      rw [smul_eq_mul, mul_comm],
      refine set_like.pow_mem_graded _ f_deg,
    end⟩, ⟨_, rfl⟩⟩ : A⁰_ f),
  { change (quotient.mk' ⟨m * n, ⟨s ^ m, _⟩, _, _⟩ : A⁰_ f) = _, dsimp,
    rw homogeneous_localization.ext_iff_val,
    erw homogeneous_localization.val_mk',
    rw homogeneous_localization.val_mk',
    dsimp,
    -- if `f^k ≠ 0`, then `n = m * k` hence the equality holds
    -- if `f^k = 0`, then `A⁰_ f` is the zero ring, then they are equal as well.
    by_cases h : f^k = 0,
    { haveI : subsingleton (localization.away f),
      { refine is_localization.subsingleton_of_zero_mem (submonoid.powers f) _ ⟨k, h⟩, },
      exact subsingleton.elim _ _, },
    { have mem1 : (f ^ k) ∈ 𝒜 (k * m) := set_like.pow_mem_graded _ f_deg,
      simp_rw ←pow_mul,
      simp_rw decomposition.degree_uniq_of_nonzero 𝒜 (f^k) mem1 F_mem1 h,
      refl, } },
  erw ←eq4 at hs,
  exact ideal.is_prime.mem_of_pow_mem (x.is_prime) _ hs,
   },
  { intros hz,
    unfold to_Spec.to_fun,
    erw to_Spec.mem_carrier_iff,
    let k : ℕ := z.denom_mem.some,
    have eq1 : val z = localization.mk z.num ⟨f^k, ⟨k, rfl⟩⟩,
    { rw z.eq_num_div_denom, simp_rw z.denom_mem.some_spec, },
    rw eq1,
    have mem1 : z.num ∈ from_Spec.carrier f_deg x,
    { intros j,
      by_cases ineq1 : j = z.deg,
      { simp only [ineq1, graded_algebra.proj_apply],
        dsimp only,
        simp only [direct_sum.decompose_of_mem_same 𝒜 z.num_mem_deg],
        have mem2 := (ideal.is_prime.pow_mem_iff_mem x.is_prime m hm).mpr hz,
        convert mem2 using 1,
        rw [homogeneous_localization.ext_iff_val, homogeneous_localization.pow_val, eq1,
          homogeneous_localization.val_mk'],
        dsimp only [subtype.coe_mk],
        rw mk_pow,
        change localization.mk _ _ = mk _ ⟨(f^k)^m, _⟩,
        by_cases h : f^k = 0,
        { haveI : subsingleton (localization.away f),
          { refine is_localization.subsingleton_of_zero_mem (submonoid.powers f) _ ⟨k, h⟩, },
          exact subsingleton.elim _ _, },
        { have eq2 : f^k = z.denom := z.denom_mem.some_spec,
          have mem1 : z.denom ∈ _ := z.denom_mem_deg,
          rw ←eq2 at mem1,
          have mem2 : f^k ∈ _ := set_like.pow_mem_graded _ f_deg,
          simp_rw decomposition.degree_uniq_of_nonzero _ _ mem1 mem2 h,
          simp_rw [←pow_mul],
          refl, }, },
    {
      simp only [graded_algebra.proj_apply, direct_sum.decompose_of_mem_ne 𝒜 z.num_mem_deg (ne.symm ineq1), zero_pow hm],
      convert submodule.zero_mem x.as_ideal using 1,
      rw homogeneous_localization.ext_iff_val,
      rw homogeneous_localization.val_mk',
      dsimp only [subtype.coe_mk],
      rw localization.mk_zero,
      rw homogeneous_localization.zero_val, }, },
    have eq3 : (mk z.num ⟨f^k, ⟨_, rfl⟩⟩ : away f) =
      mk 1 ⟨f^k, ⟨_, rfl⟩⟩ * mk z.num 1,
    { rw [mk_mul, one_mul, mul_one], },
    erw eq3,
    convert ideal.mul_mem_left _ _ _,
    apply ideal.subset_span,
    refine ⟨z.num, mem1, rfl⟩, },
end

end to_Spec_from_Spec

section from_Spec_to_Spec

lemma from_Spec_to_Spec {f : A} {m : ℕ}
  (hm : 0 < m)
  (f_deg : f ∈ 𝒜 m)
  (x) :
  from_Spec.to_fun f_deg hm
    (to_Spec.to_fun 𝒜 f x) = x :=
begin
  classical,
  ext z, split; intros hz,
  { change ∀ i, _ at hz,
    erw ←direct_sum.sum_support_decompose 𝒜 z,
    apply ideal.sum_mem,
    intros i hi,
    specialize hz i,
    erw to_Spec.mem_carrier_iff at hz,
    dsimp only at hz,
    rw ←graded_algebra.proj_apply,
    erw [←ideal.submodule_span_eq, finsupp.span_eq_range_total, set.mem_range] at hz,
    obtain ⟨c, eq1⟩ := hz,
    erw [finsupp.total_apply, finsupp.sum, homogeneous_localization.val_mk'] at eq1,
    dsimp only [subtype.coe_mk] at eq1,
    obtain ⟨N, hN⟩ := localization.away.clear_denominator (finset.image (λ i, c i * i.1) c.support),
    -- N is the common denom
    choose after_clear_denominator hacd using hN,
    have prop1 : ∀ i, i ∈ c.support → c i * i.1 ∈ (finset.image (λ i, c i * i.1) c.support),
    { intros i hi, rw finset.mem_image, refine ⟨_, hi, rfl⟩, },
    have eq2 := calc (localization.mk (f^(i + N)) 1) * (localization.mk ((graded_algebra.proj 𝒜 i z)^m) ⟨f^i, ⟨_, rfl⟩⟩ : localization.away f)
                  = (localization.mk (f^(i + N)) 1) * ∑ i in c.support, c i • i.1 : by { erw eq1, refl, }
              ... = (localization.mk (f^(i + N)) 1) * ∑ i in c.support.attach, c i.1 • i.1.1
                  : begin
                    congr' 1,
                    symmetry,
                    convert finset.sum_attach,
                    refl,
                  end
              ... = localization.mk (f^i) 1 * ((localization.mk (f^N) 1) * ∑ i in c.support.attach, c i.1 • i.1.1)
                  : begin
                    rw [←mul_assoc, localization.mk_mul, mul_one, pow_add],
                  end
              ... = localization.mk (f^i) 1 * (localization.mk (f^N) 1 * ∑ i in c.support.attach, c i.1 * i.1.1) : rfl
              ... = localization.mk (f^i) 1 * ∑ i in c.support.attach, (localization.mk (f^N) 1) * (c i.1 * i.1.1)
                  : by rw finset.mul_sum
              ... = localization.mk (f^i) 1 * ∑ i in c.support.attach, localization.mk (after_clear_denominator (c i.1 * i.1.1) (prop1 i.1 i.2)) 1
                  : begin
                    congr' 1,
                    rw finset.sum_congr rfl (λ j hj, _),
                    have := (hacd (c j.1 * j.1.1) (prop1 j.1 j.2)).2,
                    dsimp only at this,
                      erw [this, mul_comm],
                    end
              ... = localization.mk (f^i) 1 * localization.mk (∑ i in c.support.attach, after_clear_denominator (c i.1 * i.1.1) (prop1 i.1 i.2)) 1
                  : begin
                    congr' 1,
                    induction c.support.attach using finset.induction_on with a s ha ih,
                    { rw [finset.sum_empty, finset.sum_empty, localization.mk_zero], },
                    { erw [finset.sum_insert ha, finset.sum_insert ha, ih, localization.add_mk, mul_one, one_mul, one_mul, add_comm], },
                  end
              ... = localization.mk (f^i * ∑ i in c.support.attach, after_clear_denominator (c i.1 * i.1.1) (prop1 i.1 i.2)) 1
                  : begin
                    rw [localization.mk_mul, one_mul],
                  end,
    have eq3 := calc
                (localization.mk (f^(i + N)) 1) * (localization.mk ((graded_algebra.proj 𝒜 i z)^m) ⟨f^i, ⟨_, rfl⟩⟩ : localization.away f)
              = (localization.mk (f^N) 1) * (localization.mk ((graded_algebra.proj 𝒜 i z)^m) 1)
              : begin
                rw [localization.mk_mul, localization.mk_mul, one_mul, one_mul, localization.mk_eq_mk', is_localization.eq],
                refine ⟨1, _⟩,
                erw [mul_one, mul_one, mul_one, pow_add, ←subtype.val_eq_coe],
                dsimp only,
                ring,
              end
          ... = (localization.mk (f^N * (graded_algebra.proj 𝒜 i z)^m) 1)
              : begin
                rw [localization.mk_mul, one_mul],
              end,
    have eq4 : ∃ (C : submonoid.powers f),
      (f^i * ∑ i in c.support.attach, after_clear_denominator (c i.1 * i.1.1) (prop1 i.1 i.2)) * C.1 =
      (f^N * (graded_algebra.proj 𝒜 i z)^m) * C.1,
    { rw [eq2] at eq3,
      simp only [localization.mk_eq_mk', is_localization.eq] at eq3,
      obtain ⟨C, hC⟩ := eq3,
      erw [mul_one, mul_one] at hC,
      refine ⟨C, hC⟩, },
    obtain ⟨C, hC⟩ := eq4,
    have mem1 :
      (f^i * ∑ i in c.support.attach, after_clear_denominator (c i.1 * i.1.1) (prop1 i.1 i.2)) * C.1 ∈ x.1.as_homogeneous_ideal,
    { apply ideal.mul_mem_right,
      apply ideal.mul_mem_left,
      apply ideal.sum_mem,
      rintros ⟨j, hj⟩ _,
      have eq5 := (hacd (c j * j.1) (prop1 j hj)).2,
      dsimp only at eq5 ⊢,
      have mem2 := j.2,
      change ∃ g, _ at mem2,
      obtain ⟨g, hg1, hg2⟩ := mem2,
      have eq6 : ∃ (k : ℕ) (z : A), c j = localization.mk z ⟨f^k, ⟨_, rfl⟩⟩,
      { induction (c j) using localization.induction_on with data,
        obtain ⟨z, ⟨_, k, rfl⟩⟩ := data,
        refine ⟨_, _, rfl⟩,},
      obtain ⟨k, z, eq6⟩ := eq6,
      change localization.mk g 1 = _ at hg2,
      have eq7 := calc localization.mk (after_clear_denominator (c j * j.1) (prop1 j hj)) 1
                = c j * j.1 * localization.mk (f^N) 1 : eq5
            ... = (localization.mk z ⟨f^k, ⟨_, rfl⟩⟩ : localization.away f) * j.1 * localization.mk (f^N) 1 : by rw eq6
            ... = (localization.mk z ⟨f^k, ⟨_, rfl⟩⟩ : localization.away f) * localization.mk g 1 * localization.mk (f^N) 1 : by rw hg2
            ... = localization.mk (z*g*f^N) ⟨f^k, ⟨_, rfl⟩⟩
                : begin
                  rw [localization.mk_mul, localization.mk_mul, mul_one, mul_one],
                end,
      simp only [localization.mk_eq_mk', is_localization.eq] at eq7,
      obtain ⟨⟨_, ⟨l, rfl⟩⟩, eq7⟩ := eq7,
      erw [←subtype.val_eq_coe, ←subtype.val_eq_coe, ←subtype.val_eq_coe, mul_one] at eq7,
      dsimp only at eq7,
      have mem3 : z * g * f ^ N * f ^ l ∈ x.1.as_homogeneous_ideal,
      { apply ideal.mul_mem_right,
        apply ideal.mul_mem_right,
        apply ideal.mul_mem_left,
        exact hg1, },
      erw [←eq7, mul_assoc, ←pow_add] at mem3,
      rcases ideal.is_prime.mem_or_mem (x.1.is_prime) mem3 with H | RID,
      { exact H, },
      { exfalso,
        have mem4 := x.2,
        erw projective_spectrum.mem_basic_open at mem4,
        apply mem4,
        replace RID := ideal.is_prime.mem_of_pow_mem (x.1.is_prime) _ RID,
        exact RID,
        } },

    erw hC at mem1,
    rcases ideal.is_prime.mem_or_mem (x.1.is_prime) mem1 with S | RID2,
    rcases ideal.is_prime.mem_or_mem (x.1.is_prime) S with RID1 | H,
    { exfalso,
      replace RID1 := ideal.is_prime.mem_of_pow_mem (x.1.is_prime) _ RID1,
      have mem2 := x.2,
      erw projective_spectrum.mem_basic_open at mem2,
      apply mem2,
      apply RID1, },
    { replace H := ideal.is_prime.mem_of_pow_mem (x.1.is_prime) _ H,
      exact H, },
    { exfalso,
      rcases C with ⟨_, ⟨k, rfl⟩⟩,
      replace RID2 := ideal.is_prime.mem_of_pow_mem (x.1.is_prime) _ RID2,
      have mem2 := x.2,
      erw projective_spectrum.mem_basic_open at mem2,
      apply mem2,
      exact RID2, }, },
  { erw from_Spec.mem_carrier_iff,
    intros i,
    dsimp only,
    have mem2 := x.1.as_homogeneous_ideal.2 i hz,
    rw ←graded_algebra.proj_apply at mem2,
    have eq1 : (localization.mk ((graded_algebra.proj 𝒜 i z)^m) ⟨f^i, ⟨_, rfl⟩⟩ : localization.away f)
          = localization.mk 1 ⟨f^i, ⟨_, rfl⟩⟩ * localization.mk ((graded_algebra.proj 𝒜 i z)^m) 1,
    { erw [localization.mk_mul, one_mul, mul_one] },
    erw [to_Spec.mem_carrier_iff],
    simp only [eq1],
    convert ideal.mul_mem_left _ _ _,
    apply ideal.subset_span,
    refine ⟨(graded_algebra.proj 𝒜 i z)^m, _, rfl⟩,
    erw ideal.is_prime.pow_mem_iff_mem (x.1.is_prime),
    exact mem2,
    exact hm, },
end

lemma to_Spec.to_fun_inj {f : A} {m : ℕ}
  (hm : 0 < m) (f_deg : f ∈ 𝒜 m) : function.injective (to_Spec.to_fun 𝒜 f) := λ x1 x2 hx12,
begin
  convert congr_arg (from_Spec.to_fun f_deg hm) hx12; symmetry;
  apply from_Spec_to_Spec,
end

lemma to_Spec.to_fun_surj {f : A} {m : ℕ}
  (hm : 0 < m) (f_deg : f ∈ 𝒜 m) : function.surjective (to_Spec.to_fun 𝒜 f) :=
begin
  erw function.surjective_iff_has_right_inverse,
  refine ⟨from_Spec.to_fun f_deg hm, λ x, _⟩,
  rw to_Spec_from_Spec,
end

end from_Spec_to_Spec

section

variables {𝒜}

def from_Spec {f : A} {m : ℕ} (hm : 0 < m) (f_deg : f ∈ 𝒜 m) :
  (Spec.T (A⁰_ f)) ⟶ (Proj.T| (pbo f)) :=
{ to_fun := from_Spec.to_fun f_deg hm,
  continuous_to_fun := begin
    apply is_topological_basis.continuous,
    exact @is_topological_basis.inducing (Proj.T| (pbo f)) _ Proj _ (λ x, x.1) _ ⟨rfl⟩ (projective_spectrum.is_topological_basis_basic_opens 𝒜),

    intros s hs,
    erw set.mem_preimage at hs,
    obtain ⟨t, ht1, ht2⟩ := hs,
    rw set.mem_range at ht1,
    obtain ⟨a, rfl⟩ := ht1,
    dsimp only at ht2,
    have set_eq1 : s =
      {x | x.1 ∈ (pbo f) ⊓ (pbo a) },
    { ext x, split; intros hx,
      erw [←ht2, set.mem_preimage] at hx,
      refine ⟨x.2, hx⟩,

      rcases hx with ⟨hx1, hx2⟩,
      erw [←ht2, set.mem_preimage],
      exact hx2, },

    -- we want to use preimage = forward s,
    set set1 := to_Spec.to_fun 𝒜 f '' s with set1_eq,
    have o1 : is_open set1,
    {
      suffices : is_open (to_Spec.to_fun 𝒜 f '' {x | x.1 ∈ (pbo f).1 ⊓ (pbo a).1}),
      erw [set1_eq, set_eq1], exact this,

      have set_eq2 := calc to_Spec.to_fun 𝒜 f ''
            {x | x.1 ∈ (pbo f) ⊓ (pbo a)}
          = to_Spec.to_fun 𝒜 f ''
            {x | x.1 ∈ (pbo f) ⊓ (⨆ (i : ℕ), (pbo (graded_algebra.proj 𝒜 i a)))}
          : begin
            congr',
            ext x,
            erw projective_spectrum.basic_open_eq_union_of_projection 𝒜 a,
          end
      ... = to_Spec.to_fun 𝒜 f ''
            {x | x.1 ∈
              (⨆ (i : ℕ), (pbo f) ⊓ (pbo (graded_algebra.proj 𝒜 i a)) : opens Proj.T)}
          : begin
            congr',
            ext x,
            split; intros hx,
            { rcases hx with ⟨hx1, hx2⟩,
              erw opens.mem_Sup at hx2 ⊢,
              obtain ⟨_, ⟨j, rfl⟩, hx2⟩ := hx2,
              refine ⟨(pbo f) ⊓ (pbo (graded_algebra.proj 𝒜 j a)), ⟨j, rfl⟩, ⟨hx1, hx2⟩⟩, },
            { erw opens.mem_Sup at hx,
              obtain ⟨_, ⟨j, rfl⟩, ⟨hx1, hx2⟩⟩ := hx,
              refine ⟨hx1, _⟩,
              erw opens.mem_Sup,
              refine ⟨pbo (graded_algebra.proj 𝒜 j a), ⟨j, rfl⟩, hx2⟩, },
          end
      ... = to_Spec.to_fun 𝒜 f '' ⋃ (i : ℕ), {x | x.1 ∈ ((pbo f) ⊓ (pbo (graded_algebra.proj 𝒜 i a)))}
          : begin
            congr',
            ext x,
            split; intros hx; dsimp only at hx ⊢,
            { change ∃ _, _ at hx,
              obtain ⟨s, hs1, hs2⟩ := hx,
              erw set.mem_range at hs1,
              obtain ⟨s, rfl⟩ := hs1,
              rw set.mem_Union at hs2,
              obtain ⟨⟨i, rfl⟩, hs2⟩ := hs2,
              change ∃ _, _,
              refine ⟨_, ⟨i, rfl⟩, _⟩,
              exact hs2, },
            { change ∃ _, _ at hx,
              obtain ⟨_, ⟨j, rfl⟩, hx⟩ := hx,
              change x.val ∈ _ at hx,
              simp only [opens.mem_supr],
              refine ⟨j, hx⟩, },
          end
      ... = ⋃ (i : ℕ), to_Spec.to_fun 𝒜 f ''
              {x | x.1 ∈ ((pbo f) ⊓ (pbo (graded_algebra.proj 𝒜 i a)))}
          : begin
            erw set.image_Union,
          end,


    erw set_eq2,
    apply is_open_Union,
    intros i,
    suffices : to_Spec.to_fun 𝒜 f '' {x | x.1 ∈ ((pbo f) ⊓ (pbo (graded_algebra.proj 𝒜 i a)))}
        = (sbo (quotient.mk' ⟨m * i, ⟨(graded_algebra.proj 𝒜 i a)^m, set_like.pow_mem_graded _ (submodule.coe_mem _)⟩,
            ⟨f^i, by simpa only [nat.mul_comm m i] using set_like.pow_mem_graded _ f_deg⟩,
            ⟨i, rfl⟩⟩ : A⁰_ f)).1,
    { erw this,
      exact (prime_spectrum.basic_open _).2, },

    suffices : to_Spec.to_fun 𝒜 f ⁻¹' (sbo _).1 =
      {x | x.1 ∈ (pbo f) ⊓ (pbo (graded_algebra.proj 𝒜 i a))},
    { erw ←this,
      apply function.surjective.image_preimage,
      exact to_Spec.to_fun_surj 𝒜 hm f_deg, },

    { rw subtype.val_eq_coe,
      rw to_Spec.preimage_eq,
      erw projective_spectrum.basic_open_pow,
      exact hm } },

    suffices : set1 = from_Spec.to_fun f_deg hm ⁻¹' _,
    erw ←this,
    exact o1,

    { erw set1_eq,
      ext z, split; intros hz,
      { erw set.mem_preimage,
        erw set.mem_image at hz,
        obtain ⟨α, α_mem, rfl⟩ := hz,
        erw from_Spec_to_Spec,
        exact α_mem, },
      { erw set.mem_preimage at hz,
        erw set.mem_image,
        refine ⟨from_Spec.to_fun f_deg hm z, hz, _⟩,
        erw to_Spec_from_Spec, }, },
  end }

end

end Proj_iso_Spec_Top_component

section

variables {𝒜}
def Proj_iso_Spec_Top_component {f : A} {m : ℕ} (hm : 0 < m) (f_deg : f ∈ 𝒜 m) :
  (Proj.T| (pbo f)) ≅ (Spec.T (A⁰_ f)) :=
{ hom := Proj_iso_Spec_Top_component.to_Spec 𝒜 f,
  inv := Proj_iso_Spec_Top_component.from_Spec hm f_deg,
  hom_inv_id' := begin
    ext1 x,
    simp only [id_app, comp_app],
    apply Proj_iso_Spec_Top_component.from_Spec_to_Spec,
  end,
  inv_hom_id' := begin
    ext1 x,
    simp only [id_app, comp_app],
    apply Proj_iso_Spec_Top_component.to_Spec_from_Spec,
  end }

end

namespace Proj_iso_Spec_Sheaf_component

namespace from_Spec

open algebraic_geometry

variables {𝒜} {m : ℕ} {f : A} (hm : 0 < m) (f_deg : f ∈ 𝒜 m) (V : (opens (Spec (A⁰_ f)))ᵒᵖ)
variables (hh : (Spec (A⁰_ f)).presheaf.obj V)
variables (y : ((@opens.open_embedding Proj.T (pbo f)).is_open_map.functor.op.obj
  ((opens.map (Proj_iso_Spec_Top_component hm f_deg).hom).op.obj V)).unop)

lemma data_prop1 : y.1 ∈ (pbo f) :=
begin
  obtain ⟨⟨a, ha1⟩, -, ha2⟩ := y.2,
  rw ← ha2,
  exact ha1,
end

lemma data_prop2 :
  (Proj_iso_Spec_Top_component hm f_deg).hom ⟨y.1, data_prop1 hm f_deg V y⟩ ∈ unop V :=
begin
  obtain ⟨⟨a, ha1⟩, ha2, ha3⟩ := y.2,
  erw set.mem_preimage at ha2,
  convert ha2,
  rw ← ha3,
  refl,
end

variable {V}
-- hh(φ(y)) = a / b
def data : structure_sheaf.localizations (A⁰_ f)
  ((Proj_iso_Spec_Top_component hm f_deg).hom ⟨y.1, data_prop1 _ _ _ _⟩) :=
hh.1 ⟨_, data_prop2 _ _ _ _⟩

lemma data.one :
  data 𝒜 hm f_deg (1 : (Spec (A⁰_ f)).presheaf.obj V) = 1 := rfl

lemma data.zero :
  data 𝒜 hm f_deg (0 : (Spec (A⁰_ f)).presheaf.obj V) = 0 := rfl

lemma data.add_apply (x y : (Spec (A⁰_ f)).presheaf.obj V) (z):
  data 𝒜 hm f_deg (x + y) z = data 𝒜 hm f_deg x z + data 𝒜 hm f_deg y z := rfl

lemma data.mul_apply (x y : (Spec (A⁰_ f)).presheaf.obj V) (z):
  data 𝒜 hm f_deg (x * y) z = data 𝒜 hm f_deg x z * data 𝒜 hm f_deg y z := rfl

private lemma data.exist_rep
  (data : structure_sheaf.localizations (A⁰_ f) ((Proj_iso_Spec_Top_component hm f_deg).hom ⟨y.1, data_prop1 _ _ _ _⟩)) :
  ∃ (a : A⁰_ f) (b : ((Proj_iso_Spec_Top_component hm f_deg).hom ⟨y.1, data_prop1 _ _ _ _⟩).as_ideal.prime_compl),
  data = mk a b :=
begin
  induction data using localization.induction_on with d,
  rcases d with ⟨a, b⟩,
  refine ⟨a, b, rfl⟩,
end

-- a
def data.num : A⁰_ f :=
classical.some $ data.exist_rep _ hm f_deg y (data _ hm f_deg hh y)

-- b
def data.denom : A⁰_ f :=
(classical.some $ classical.some_spec $ data.exist_rep _ hm f_deg y
  (data _ hm f_deg hh y)).1

lemma data.denom_not_mem :
  (data.denom _ hm f_deg hh y) ∉
  ((Proj_iso_Spec_Top_component hm f_deg).hom ⟨y.1, data_prop1 _ _ _ _⟩).as_ideal :=
(classical.some $ classical.some_spec $ data.exist_rep _ hm f_deg y
  (data _ hm f_deg hh y)).2

lemma data.eq_num_div_denom :
  (data _ hm f_deg hh y) =
  localization.mk (data.num _ hm f_deg hh y) ⟨data.denom _ hm f_deg hh y, data.denom_not_mem hm f_deg hh y⟩ :=
begin
  rw classical.some_spec (classical.some_spec (data.exist_rep _ hm f_deg y (data _ hm f_deg hh y))),
  congr,
  rw subtype.ext_iff,
  refl,
end

-- a = n_a / f^i_a
def num : A :=
  (data.num _ hm f_deg hh y).num * (data.denom _ hm f_deg hh y).denom

lemma num.mem :
    (num hm f_deg hh y)
  ∈ 𝒜 ((data.num _ hm f_deg hh y).deg + (data.denom _ hm f_deg hh y).deg) :=
mul_mem (homogeneous_localization.num_mem_deg _)
  (homogeneous_localization.denom_mem_deg _)
-- (homogeneous_localization.num_mem_deg _) $ begin
--   convert (set_like.graded_monoid.pow_mem (degree_zero_part.deg (data.denom hm f_deg hh y)) f_deg) using 1,
--   rw mul_comm,
--   refl,
-- end

def denom : A :=
  (data.denom _ hm f_deg hh y).num * (data.num _ hm f_deg hh y).denom

lemma denom.mem :
  (denom hm f_deg hh y) ∈
  𝒜 ((data.num _ hm f_deg hh y).deg + (data.denom _ hm f_deg hh y).deg) :=
-- mul_mem (homogeneous_localization.num_mem_deg _) _
begin
  change _ * _ ∈ _,
  rw add_comm,
  refine mul_mem _ _,
  { exact homogeneous_localization.num_mem_deg _, },
  { exact homogeneous_localization.denom_mem_deg _, },
end

lemma denom_not_mem :
  denom hm f_deg hh y ∉ y.1.as_homogeneous_ideal := λ rid,
begin
  rcases y.1.is_prime.mem_or_mem rid with H1 | H2,
  { have mem1 := data.denom_not_mem hm f_deg hh y,
    have eq1 := (data.denom _ hm f_deg hh y).eq_num_div_denom,
    dsimp only at mem1,
    change _ ∉ _ at mem1,
    apply mem1,
    erw Proj_iso_Spec_Top_component.to_Spec.mem_carrier_iff,
    rw eq1,
    convert ideal.mul_mem_left _ _ _,
    work_on_goal 2
    { exact mk 1 ⟨(data.denom _ hm f_deg hh y).denom, homogeneous_localization.denom_mem _⟩ },
    work_on_goal 2
    { exact mk (data.denom _ hm f_deg hh y).num 1 },
    { rw [mk_mul, one_mul, mul_one], },
    { apply ideal.subset_span,
      exact ⟨_, H1, rfl⟩ }, },
  { let k : ℕ := (data.num _ hm f_deg hh y).denom_mem.some,
    have k_eq : f^k = (data.num _ hm f_deg hh y).denom := (data.num _ hm f_deg hh y).denom_mem.some_spec,
    rw ←k_eq at H2,
    replace H2 := y.1.is_prime.mem_of_pow_mem _ H2,
    obtain ⟨⟨a, ha1⟩, ha2, ha3⟩ := y.2,
    erw projective_spectrum.mem_basic_open at ha1,
    apply ha1,
    convert H2, }
end

variable (V)
def bmk : homogeneous_localization.at_prime 𝒜 y.1.as_homogeneous_ideal.to_ideal :=
quotient.mk'
{ deg := (data.num _ hm f_deg hh y).deg + (data.denom _ hm f_deg hh y).deg,
  num := ⟨num hm f_deg hh y, num.mem hm f_deg hh y⟩,
  denom := ⟨denom hm f_deg hh y, denom.mem hm f_deg hh y⟩,
  denom_mem := denom_not_mem hm f_deg hh y }

lemma bmk_one :
  bmk hm f_deg V 1 = 1 :=
begin
  ext1 y,
  have y_mem : y.val ∈ (pbo f).val,
  { erw projective_spectrum.mem_basic_open,
    intro rid,
    have mem1 := y.2,
    erw set.mem_preimage at mem1,
    obtain ⟨⟨a, ha1⟩, ha, ha2⟩ := mem1,
    change a = y.1 at ha2,
    erw set.mem_preimage at ha,
    erw ←ha2 at rid,
    apply ha1,
    exact rid },

  rw pi.one_apply,
  unfold bmk,
  rw [homogeneous_localization.ext_iff_val, homogeneous_localization.val_mk', homogeneous_localization.one_val],
  simp only [← subtype.val_eq_coe],
  unfold num denom,

  have eq1 := data.eq_num_div_denom hm f_deg 1 y,
  rw [data.one, pi.one_apply] at eq1,
  replace eq1 := eq1.symm,
  rw [show (1 : structure_sheaf.localizations (A⁰_ f)
    (((Proj_iso_Spec_Top_component hm f_deg).hom) ⟨y.val, y_mem⟩)) = localization.mk 1 1,
    by erw localization.mk_self 1, localization.mk_eq_mk'] at eq1,
  replace eq1 := (@@is_localization.eq _ _ _ _).mp eq1,
  obtain ⟨⟨C, hC⟩, eq1⟩ := eq1,
  simp only [mul_one, one_mul, submonoid.coe_one, subtype.coe_mk] at eq1,
  simp only [localization.mk_eq_mk', is_localization.eq],
  change _ ∉ _ at hC,
  erw Proj_iso_Spec_Top_component.to_Spec.mem_carrier_iff at hC,
  rw [homogeneous_localization.eq_num_div_denom] at hC,
  dsimp only at hC,

  have eq_num := (data.num _ hm f_deg 1 y).eq_num_div_denom,
  have eq_denom := (data.denom _ hm f_deg 1 y).eq_num_div_denom,

  rw homogeneous_localization.ext_iff_val at eq1,
  simp only [homogeneous_localization.mul_val, C.eq_num_div_denom] at eq1,
  erw [eq_num, eq_denom, localization.mk_mul, localization.mk_mul] at eq1,
  simp only [localization.mk_eq_mk', is_localization.eq, subtype.coe_mk, submonoid.coe_mul] at eq1,
  obtain ⟨⟨_, ⟨n1, rfl⟩⟩, eq1⟩ := eq1,
  simp only [submonoid.coe_mul, subtype.coe_mk] at eq1,

  have C_not_mem : C.num ∉ y.1.as_homogeneous_ideal,
  { intro rid,
    have eq1 : (localization.mk C.num ⟨C.denom, C.denom_mem⟩ : localization.away f) =
      (localization.mk 1 ⟨C.denom, C.denom_mem⟩ : localization.away f) * localization.mk C.num 1,
    { rw [localization.mk_mul, one_mul, mul_one], },
    erw eq1 at hC,
    apply hC,
    convert ideal.mul_mem_left _ _ _,
    apply ideal.subset_span,
    refine ⟨_, rid, rfl⟩, },

  rw [show (1 : localization.at_prime y.1.as_homogeneous_ideal.to_ideal) = mk (1 : _) 1, by erw mk_self 1, mk_eq_mk', is_localization.eq],
  use C.num * (C.denom * f^n1),
  { intros rid,
    rcases y.1.is_prime.mem_or_mem rid with H1 | H3,
    exact C_not_mem H1,
    let l : ℕ := C.denom_mem.some,
    let l_eq : f^l = C.denom := C.denom_mem.some_spec,
    rw [←l_eq, ←pow_add] at H3,
    replace H3 := y.1.is_prime.mem_of_pow_mem _ H3,
    apply y_mem,
    exact H3, },

  simp only [submonoid.coe_one, one_mul, mul_one],
  simp only [subtype.coe_mk],
  rw calc (data.num _ hm f_deg 1 y).num
        * (data.denom _ hm f_deg 1 y).denom
        * (C.num * (C.denom * f ^ n1))
      = (data.num _ hm f_deg 1 y).num * C.num
        * ((data.denom _ hm f_deg 1 y).denom * C.denom)
        * f^n1 : by ring_exp,
  rw [eq1],
  ring,
end

lemma bmk_zero :
  bmk hm f_deg V 0 = 0 :=
begin
  ext1 y,
  have y_mem : y.val ∈ (pbo f).val,
  { erw projective_spectrum.mem_basic_open,
    intro rid,
    have mem1 := y.2,
    erw set.mem_preimage at mem1,
    obtain ⟨⟨a, ha1⟩, ha, ha2⟩ := mem1,
    change a = y.1 at ha2,
    erw set.mem_preimage at ha,
    erw ←ha2 at rid,
    apply ha1,
    exact rid },

  rw pi.zero_apply,
  unfold bmk,
  rw [homogeneous_localization.ext_iff_val, homogeneous_localization.val_mk', homogeneous_localization.zero_val],
  simp only [← subtype.val_eq_coe],
  rw [show (0 : localization.at_prime y.1.as_homogeneous_ideal.to_ideal) = localization.mk 0 1,
    by erw localization.mk_zero],
  dsimp only,
  unfold num denom,

  have eq1 := data.eq_num_div_denom hm f_deg 0 y,
  rw [data.zero, pi.zero_apply] at eq1,
  replace eq1 := eq1.symm,
  erw [show (0 : structure_sheaf.localizations (A⁰_ f)
    (((Proj_iso_Spec_Top_component hm f_deg).hom) ⟨y.val, y_mem⟩)) = localization.mk 0 1,
    by erw localization.mk_zero, localization.mk_eq_mk', is_localization.eq] at eq1,

  obtain ⟨⟨C, hC⟩, eq1⟩ := eq1,
  simp only [submonoid.coe_one, mul_one, one_mul, subtype.coe_mk] at eq1,
  simp only [zero_mul] at eq1,
  simp only [localization.mk_eq_mk', is_localization.eq],
  change _ ∉ _ at hC,
  erw Proj_iso_Spec_Top_component.to_Spec.mem_carrier_iff at hC,
  rw [homogeneous_localization.eq_num_div_denom] at hC,
  dsimp only at hC,

  have eq_num := (data.num _ hm f_deg 0 y).eq_num_div_denom,
  have eq_denom := (data.denom _ hm f_deg 0 y).eq_num_div_denom,

  rw homogeneous_localization.ext_iff_val at eq1,
  simp only [homogeneous_localization.mul_val, homogeneous_localization.zero_val] at eq1,
  rw [eq_num,
    show (0 : localization.away f) = localization.mk 0 1, by rw localization.mk_zero,
    C.eq_num_div_denom, localization.mk_mul] at eq1,
  simp only [localization.mk_eq_mk', is_localization.eq] at eq1,
  obtain ⟨⟨_, ⟨n1, rfl⟩⟩, eq1⟩ := eq1,
  simp only [submonoid.coe_mul, ←pow_add,
    submonoid.coe_one, mul_one, zero_mul, subtype.coe_mk] at eq1,

  have C_not_mem : C.num ∉ y.1.as_homogeneous_ideal,
  { intro rid,
    have eq1 : (localization.mk C.num ⟨C.denom, C.denom_mem⟩ : localization.away f) =
      (mk 1 ⟨C.denom, C.denom_mem⟩ : localization.away f) * localization.mk C.num 1,
      rw [localization.mk_mul, one_mul, mul_one],
    erw eq1 at hC,
    apply hC,
    convert ideal.mul_mem_left _ _ _,
    apply ideal.subset_span,
    refine ⟨C.num, rid, rfl⟩, },

  use C.num * f^n1,
  { intro rid,
    rcases y.1.is_prime.mem_or_mem rid with H1 | H2,
    apply C_not_mem H1,
    replace H2 := y.1.is_prime.mem_of_pow_mem _ H2,
    apply y_mem,
    exact H2, },

  simp only [submonoid.coe_one, zero_mul, mul_one],
  simp only [← subtype.val_eq_coe],

  rw calc (data.num _ hm f_deg 0 y).num
        * (data.denom _ hm f_deg 0 y).denom
        * (C.num * f ^ n1)
      = (data.num _ hm f_deg 0 y).num
        * C.num * f ^ n1
        * (data.denom _ hm f_deg 0 y).denom
      : by ring,
  rw [eq1, zero_mul],
end

lemma bmk_add (x y : (Spec (A⁰_ f)).presheaf.obj V) :
  bmk hm f_deg V (x + y) = bmk hm f_deg V x + bmk hm f_deg V y :=
begin
  ext1 z,
  have z_mem : z.val ∈ (projective_spectrum.basic_open 𝒜 f).val,
  { erw projective_spectrum.mem_basic_open,
    intro rid,
    have mem1 := z.2,
    erw set.mem_preimage at mem1,
    obtain ⟨⟨a, ha1⟩, ha, ha2⟩ := mem1,
    change a = z.1 at ha2,
    erw set.mem_preimage at ha,
    erw ←ha2 at rid,
    apply ha1,
    exact rid },

  rw pi.add_apply,
  unfold bmk,
  simp only [homogeneous_localization.ext_iff_val, homogeneous_localization.val_mk', homogeneous_localization.add_val, ←subtype.val_eq_coe],
  unfold num denom,
  dsimp only,

  have add_eq := data.eq_num_div_denom hm f_deg (x + y) z,
  rw [data.add_apply, data.eq_num_div_denom, data.eq_num_div_denom, add_mk] at add_eq,
  simp only [localization.mk_eq_mk'] at add_eq,
  erw is_localization.eq at add_eq,
  obtain ⟨⟨C, hC⟩, add_eq⟩ := add_eq,

  change _ ∉ _ at hC,
  erw Proj_iso_Spec_Top_component.to_Spec.mem_carrier_iff at hC,
  rw [C.eq_num_div_denom] at hC,
  simp only [submonoid.coe_mul, subtype.coe_mk] at add_eq,
  rw homogeneous_localization.ext_iff_val at add_eq,
  simp only [homogeneous_localization.add_val, homogeneous_localization.mul_val] at add_eq,

  have C_not_mem : C.num ∉ z.1.as_homogeneous_ideal,
  { intro rid,
    have eq1 : (mk C.num ⟨C.denom, C.denom_mem⟩ : localization.away f) =
      (mk 1 ⟨C.denom, C.denom_mem⟩ : localization.away f) * localization.mk C.num 1,
      rw [localization.mk_mul, one_mul, mul_one],
    erw eq1 at hC,
    apply hC,
    convert ideal.mul_mem_left _ _ _,
    apply ideal.subset_span,
    exact ⟨C.num, rid, rfl⟩, },

  simp only [homogeneous_localization.eq_num_div_denom, localization.mk_mul, localization.add_mk,
    submonoid.coe_mul] at add_eq,
  rw [localization.mk_eq_mk', is_localization.eq] at add_eq,
  obtain ⟨⟨_, ⟨n1, rfl⟩⟩, add_eq⟩ := add_eq,
  simp only [←subtype.val_eq_coe, submonoid.coe_mul] at add_eq,

  set a_xy : A := (data.num _ hm f_deg (x + y) z).num with a_xy_eq,
  set i_xy : ℕ := (data.num _ hm f_deg (x + y) z).denom_mem.some with i_xy_eq,
  have i_xy_eq' : _ = f^i_xy := (data.num _ hm f_deg (x + y) z).denom_mem.some_spec.symm,

  set b_xy : A := (data.denom _ hm f_deg (x + y) z).num with b_xy_eq,
  set j_xy : ℕ := (data.denom _ hm f_deg (x + y) z).denom_mem.some with j_xy_eq,
  have j_xy_eq' : _ = f^j_xy := (data.denom _ hm f_deg (x + y) z).denom_mem.some_spec.symm,

  set a_x : A := (data.num _ hm f_deg x z).num with a_x_eq,
  set i_x : ℕ := (data.num _ hm f_deg x z).denom_mem.some with i_x_eq,
  have i_x_eq' : _ = f^i_x := (data.num _ hm f_deg x z).denom_mem.some_spec.symm,

  set b_x : A := (data.denom _ hm f_deg x z).num with b_x_eq,
  set j_x : ℕ := (data.denom _ hm f_deg x z).denom_mem.some with j_x_eq,
  have j_x_eq' : _ = f^j_x := (data.denom _ hm f_deg x z).denom_mem.some_spec.symm,

  set a_y : A := (data.num _ hm f_deg y z).num with a_y_eq,
  set i_y : ℕ := (data.num _ hm f_deg y z).denom_mem.some with i_y_eq,
  have i_y_eq' : _ = f^i_y := (data.num _ hm f_deg y z).denom_mem.some_spec.symm,
  set b_y : A := (data.denom _ hm f_deg y z).num with b_y_eq,
  set j_y : ℕ := (data.denom _ hm f_deg y z).denom_mem.some with j_y_eq,
  set j_y_eq' : _ = f^j_y := (data.denom _ hm f_deg y z).denom_mem.some_spec.symm,

  set l := C.denom_mem.some with l_eq,
  set l_eq' : _ = f^l := C.denom_mem.some_spec.symm,

  rw [j_x_eq', i_y_eq', ←b_y_eq, ←a_x_eq, j_y_eq', i_x_eq', ←b_x_eq, ←a_y_eq, ←b_xy_eq,
      i_xy_eq', l_eq', ←a_xy_eq, j_xy_eq'] at add_eq,

  suffices : (mk (a_xy * f ^ j_xy) ⟨b_xy * f ^ i_xy, _⟩ : localization.at_prime _) =
  mk (a_x * f ^ j_x) ⟨b_x * f ^ i_x, _⟩ + mk (a_y * f ^ j_y) ⟨b_y * f ^ i_y, _⟩,
  { convert this using 1,
    { rw [←a_xy_eq, j_xy_eq'], simp_rw [←b_xy_eq],
      congr' 1, rw subtype.ext_iff_val, dsimp only, congr' 1, },
    { rw [←a_x_eq, j_x_eq', ←a_y_eq, j_y_eq'],
      simp_rw [←b_x_eq, ←b_y_eq],
      congr' 1,
      { congr' 1, rw subtype.ext_iff_val, dsimp only, congr' 1, },
      { congr' 1, rw subtype.ext_iff_val, dsimp only, congr' 1, }, }, },
  swap,
  { rw [←i_xy_eq', b_xy_eq],
    exact denom_not_mem hm f_deg (x + y) z, },
  swap,
  { rw [←i_x_eq', b_x_eq],
    exact denom_not_mem hm f_deg x z, },
  swap,
  { rw [←i_y_eq', b_y_eq],
    exact denom_not_mem hm f_deg y z },

  rw localization.add_mk,
  simp only [←subtype.val_eq_coe,
    show ∀ (α β : z.1.as_homogeneous_ideal.to_ideal.prime_compl), α * β = ⟨α.1 * β.1, begin
      intro rid,
      rcases z.1.is_prime.mem_or_mem rid,
      apply α.2 h,
      apply β.2 h,
    end⟩,
    begin
      intros α β,
      simp only [subtype.ext_iff],
      refl,
    end,
    show b_x * f ^ i_x * (a_y * f ^ j_y) = a_y * b_x * f ^ (i_x + j_y),
    begin
      rw pow_add, ring,
    end,
    show b_y * f ^ i_y * (a_x * f ^ j_x) = a_x * b_y * f ^ (i_y + j_x),
    begin
      rw pow_add, ring
    end,
    show b_x * f ^ i_x * (b_y * f ^ i_y) = b_x * b_y * f ^ (i_x + i_y),
    begin
      rw pow_add, ring
    end],
  rw [calc (f ^ j_x * f ^ i_y * (b_y * a_x) + f ^ j_y * f ^ i_x * (b_x * a_y)) * b_xy * C.num
          * (f ^ i_xy * (f ^ j_x * f ^ j_y) * f ^ l) * f ^ n1
        = ((f ^ j_x * f ^ i_y) * (b_y * a_x) + (f ^ j_y * f ^ i_x) * (b_x * a_y)) * b_xy * C.num
          * ((f ^ i_xy * (f ^ j_x * f ^ j_y) * f ^ l) * f ^ n1) : by ring
    ... = ((f ^ (j_x + i_y)) * (b_y * a_x) + (f ^ (j_y + i_x)) * (b_x * a_y)) * b_xy * C.num
          * f ^ ((((i_xy + (j_x + j_y))) + l) + n1)
        : begin
          congr',
          all_goals { repeat { rw pow_add } },
        end,
      calc a_xy * (b_x * b_y) * C.num * (f ^ j_x * f ^ i_y * (f ^ j_y * f ^ i_x) * f ^ j_xy * f ^ l) * f ^ n1
        = a_xy * (b_x * b_y) * C.num * ((f ^ j_x * f ^ i_y * (f ^ j_y * f ^ i_x) * f ^ j_xy * f ^ l) * f ^ n1) : by ring
    ... = a_xy * (b_x * b_y) * C.num * f ^ (((((j_x + i_y) + (j_y + i_x)) + j_xy) + l) + n1) : by simp only [pow_add]] at add_eq,

  simp only [localization.mk_eq_mk', is_localization.eq],
  refine ⟨⟨C.num * f ^ ((j_x + j_y) + l + n1), begin
    intro rid,
    rcases z.1.is_prime.mem_or_mem rid with H1 | H2,
    apply C_not_mem H1,
    replace H2 := z.1.is_prime.mem_of_pow_mem _ H2,
    apply z_mem H2,
  end⟩, _⟩,
  simp only [←subtype.val_eq_coe],

  rw [calc (a_y * b_x * f ^ (i_x + j_y) + a_x * b_y * f ^ (i_y + j_x)) * (b_xy * f ^ i_xy)
          * (C.num * f ^ ((j_x + j_y) + l + n1))
        = (f ^ (i_y + j_x) * (b_y * a_x) +  f ^ (i_x + j_y) * (b_x * a_y)) * b_xy * C.num
          * (f ^ i_xy * f ^ ((j_x + j_y) + l + n1)) : by ring
    ... = (f ^ (i_y + j_x) * (b_y * a_x) +  f ^ (i_x + j_y) * (b_x * a_y)) * b_xy * C.num
          * (f ^ (i_xy + ((j_x + j_y) + l + n1))) : by simp only [pow_add]
    ... = (f ^ (j_x + i_y) * (b_y * a_x) +  f ^ (j_y + i_x) * (b_x * a_y)) * b_xy * C.num
          * (f ^ (i_xy + (j_x + j_y) + l + n1))
        : begin
          congr' 1,
          congr' 5,
          all_goals { simp only [add_comm, add_assoc], },
        end, add_eq],
  simp only [pow_add],
  ring,
end

lemma bmk_mul (x y : (Spec (A⁰_ f)).presheaf.obj V) :
  bmk hm f_deg V (x * y) = bmk hm f_deg V x * bmk hm f_deg V y :=
begin
  ext1 z,
  have z_mem : z.val ∈ (projective_spectrum.basic_open 𝒜 f).val,
  { erw projective_spectrum.mem_basic_open,
    intro rid,
    have mem1 := z.2,
    erw set.mem_preimage at mem1,
    obtain ⟨⟨a, ha1⟩, ha, ha2⟩ := mem1,
    change a = z.1 at ha2,
    erw set.mem_preimage at ha,
    erw ←ha2 at rid,
    apply ha1,
    exact rid, },

  rw pi.mul_apply,
  unfold bmk,
  simp only [homogeneous_localization.ext_iff_val, homogeneous_localization.val_mk', homogeneous_localization.mul_val, ← subtype.val_eq_coe],
  unfold num denom,

  have mul_eq := data.eq_num_div_denom hm f_deg (x * y) z,
  rw [data.mul_apply, data.eq_num_div_denom, data.eq_num_div_denom, localization.mk_mul] at mul_eq,
  simp only [localization.mk_eq_mk'] at mul_eq,
  erw is_localization.eq at mul_eq,
  obtain ⟨⟨C, hC⟩, mul_eq⟩ := mul_eq,
  change _ ∉ _ at hC,
  erw Proj_iso_Spec_Top_component.to_Spec.mem_carrier_iff at hC,
  simp only [subtype.coe_mk, C.eq_num_div_denom] at hC,
  rw homogeneous_localization.ext_iff_val at mul_eq,
  simp only [homogeneous_localization.mul_val, submonoid.coe_mul,
    subtype.coe_mk, C.eq_num_div_denom] at mul_eq,


  have C_not_mem : C.num ∉ z.1.as_homogeneous_ideal,
  { intro rid,
    have eq1 : (mk C.num ⟨C.denom, C.denom_mem⟩ : localization.away f) =
      (mk 1 ⟨C.denom, C.denom_mem⟩ : localization.away f) * mk C.num 1,
      rw [localization.mk_mul, one_mul, mul_one],
    erw eq1 at hC,
    apply hC,
    convert ideal.mul_mem_left _ _ _,
    apply ideal.subset_span,
    exact ⟨C.num, rid, rfl⟩, },

  simp only [←subtype.val_eq_coe, subring.coe_mul, coe_add, subtype.coe_mk, homogeneous_localization.eq_num_div_denom,
    show ∀ (α β : (prime_spectrum.as_ideal (((Proj_iso_Spec_Top_component hm f_deg).hom)
      ⟨z.val, z_mem⟩)).prime_compl),
      (α * β).1 = α.1 * β.1, from λ _ _, rfl] at mul_eq,
  simp only [localization.mk_mul, localization.add_mk] at mul_eq,
  rw [localization.mk_eq_mk', is_localization.eq] at mul_eq,
  obtain ⟨⟨_, ⟨n1, rfl⟩⟩, mul_eq⟩ := mul_eq,
  simp only [←subtype.val_eq_coe, submonoid.coe_mul] at mul_eq,

  set a_xy : A := (data.num _ hm f_deg (x * y) z).num with a_xy_eq,
  set i_xy : ℕ := (data.num _ hm f_deg (x * y) z).denom_mem.some with i_xy_eq,
  have i_xy_eq' : _ = f^i_xy := (data.num _ hm f_deg (x * y) z).denom_mem.some_spec.symm,
  set b_xy : A := (data.denom _ hm f_deg (x * y) z).num with b_xy_eq,
  set j_xy : ℕ := (data.denom _ hm f_deg (x * y) z).denom_mem.some with j_xy_eq,
  have j_xy_eq' : _ = f^j_xy := (data.denom _ hm f_deg (x * y) z).denom_mem.some_spec.symm,

  set a_x : A := (data.num _ hm f_deg x z).num with a_x_eq,
  set i_x : ℕ := (data.num _ hm f_deg x z).denom_mem.some with i_x_eq,
  have i_x_eq' : _ = f ^ i_x := (data.num _ hm f_deg x z).denom_mem.some_spec.symm,
  set b_x : A := (data.denom _ hm f_deg x z).num with b_x_eq,
  set j_x : ℕ := (data.denom _ hm f_deg x z).denom_mem.some with j_x_eq,
  have j_x_eq' : _ = f ^ j_x := (data.denom _ hm f_deg x z).denom_mem.some_spec.symm,

  set a_y : A := (data.num _ hm f_deg y z).num with a_y_eq,
  set i_y : ℕ := (data.num _ hm f_deg y z).denom_mem.some with i_y_eq,
  have i_y_eq' : _ = f ^ i_y := (data.num _ hm f_deg y z).denom_mem.some_spec.symm,
  set b_y : A := (data.denom _ hm f_deg y z).num with b_y_eq,
  set j_y : ℕ := (data.denom _ hm f_deg y z).denom_mem.some with j_y_eq,
  set j_y_eq' : _ = f ^ j_y := (data.denom _ hm f_deg y z).denom_mem.some_spec.symm,

  set l : ℕ := C.denom_mem.some with l_eq,
  have l_eq' : _ = f^l := C.denom_mem.some_spec.symm,

  simp only [←a_xy_eq, ←b_xy_eq, ←a_x_eq, ←b_x_eq, ←a_y_eq, ←b_y_eq] at mul_eq ⊢,
  rw [i_xy_eq', j_x_eq', j_y_eq', l_eq', i_x_eq', i_y_eq', j_xy_eq'] at mul_eq,
  -- rw [j_xy_eq'], simp_rw [i_xy_eq'],
  suffices : (mk (a_xy * f ^ j_xy) ⟨b_xy * f ^ i_xy, _⟩ : localization.at_prime _) =
    mk (a_x * f ^ j_x) ⟨b_x * f ^ i_x, _⟩ * mk (a_y * f ^ j_y) ⟨b_y * f ^ i_y, _⟩,
  { convert this using 1,
    { congr' 1, rw j_xy_eq', rw subtype.ext_iff_val, dsimp only, congr' 1, },
    { congr' 1,
      { rw j_x_eq', congr' 1, rw subtype.ext_iff_val, dsimp only, congr' 1 },
      { rw j_y_eq', congr' 1, rw subtype.ext_iff_val, dsimp only, congr' 1 }, }, },
  swap,
  { rw [←i_xy_eq', b_xy_eq],
    exact denom_not_mem hm f_deg (x * y) z, },
  swap,
  { rw [←i_x_eq', b_x_eq],
    exact denom_not_mem hm f_deg x z, },
  swap,
  { rw [←i_y_eq', b_y_eq],
    exact denom_not_mem hm f_deg y z, },
  rw [localization.mk_mul, localization.mk_eq_mk', is_localization.eq],
  refine ⟨⟨C.num * f^(l + n1), begin
    intro rid,
    rcases z.1.is_prime.mem_or_mem rid with H1 | H2,
    apply C_not_mem H1,
    replace H2 := z.1.is_prime.mem_of_pow_mem _ H2,
    apply z_mem H2,
  end⟩, _⟩,
  simp only [←subtype.val_eq_coe,
    show ∀ (α β : z.1.as_homogeneous_ideal.to_ideal.prime_compl), (α * β).1 = α.1 * β.1,
    from λ _ _, rfl],
  simp only [pow_add],
  ring_nf at mul_eq ⊢,
  rw mul_eq,
end

namespace is_locally_quotient

variable {V}
lemma mem_pbo : y.1 ∈ pbo f :=
begin
  rw projective_spectrum.mem_basic_open,
  intro rid,
  have mem1 := y.2,
  erw set.mem_preimage at mem1,
  obtain ⟨⟨a, ha1⟩, ha, ha2⟩ := mem1,
  erw set.mem_preimage at ha,
  erw ←ha2 at rid,
  apply ha1,
  exact rid,
end

lemma hom_apply_mem :
  (Proj_iso_Spec_Top_component hm f_deg).hom ⟨y.1, mem_pbo hm f_deg y⟩ ∈ unop V :=
begin
  obtain ⟨a, ha1, ha2⟩ := y.2,
  erw set.mem_preimage at ha1,
  change ((Proj_iso_Spec_Top_component hm f_deg).hom ⟨y.1, _⟩) ∈ (unop V).1,
  convert ha1,
  rw subtype.ext_iff,
  exact ha2.symm,
end

def Uo (VV : opens (Spec.T (A⁰_ f))) :
  opens (projective_spectrum.Top 𝒜) :=
⟨{x | ∃ x' : homeo_of_iso (Proj_iso_Spec_Top_component hm f_deg) ⁻¹' VV.1, x = x'.1.1}, begin
  have O1 := (homeomorph.is_open_preimage (homeo_of_iso (Proj_iso_Spec_Top_component hm f_deg))).2 VV.2,
  rw is_open_induced_iff at O1,
  obtain ⟨s, Os, set_eq1⟩ := O1,
  have O2 : is_open (s ∩ (projective_spectrum.basic_open 𝒜 f).1),
  apply is_open.inter Os (projective_spectrum.basic_open 𝒜 f).2,
  convert O2,
  ext γ, split; intros hγ,
  { obtain ⟨x', rfl⟩ := hγ,
    have mem1 := x'.2,
    simp only [←set_eq1] at mem1,
    erw set.mem_preimage at mem1,
    refine ⟨mem1, _⟩,
    have mem2 := x'.2,
    rw set.mem_preimage at mem2,
    intro rid,
    have mem3 : (quotient.mk' ⟨m, ⟨f, f_deg⟩, ⟨f^1, by rwa [pow_one]⟩, ⟨1, rfl⟩⟩ : A⁰_ f) ∈ ((Proj_iso_Spec_Top_component hm f_deg).hom x'.1).as_ideal,
    { erw Proj_iso_Spec_Top_component.to_Spec.mem_carrier_iff,
      change (localization.mk f ⟨f^1, ⟨_, rfl⟩⟩ : localization.away f) ∈ ideal.span _,
      convert ideal.mul_mem_left _ _ _,
      work_on_goal 2
      { exact mk 1 ⟨f^1, ⟨_, rfl⟩⟩ },
      work_on_goal 2
      { exact mk f 1 },
      { rw [mk_mul, one_mul, mul_one], },
      { apply ideal.subset_span,
        refine ⟨f, rid, rfl⟩, } },
    have mem4 : (1 : A⁰_ f) ∈ ((Proj_iso_Spec_Top_component hm f_deg).hom x'.1).as_ideal,
    { convert mem3,
      rw [homogeneous_localization.ext_iff_val, homogeneous_localization.one_val, homogeneous_localization.val_mk'],
      dsimp only [subtype.coe_mk],
      simp_rw [pow_one],
      convert (localization.mk_self _).symm,
      refl, },
    apply ((Proj_iso_Spec_Top_component hm f_deg).hom x'.1).is_prime.1,
    rw ideal.eq_top_iff_one,
    exact mem4, },

  { rcases hγ with ⟨hγ1, hγ2⟩,
    use ⟨γ, hγ2⟩,
    rw [←set_eq1, set.mem_preimage],
        convert hγ1, }
end⟩

lemma subset2 (VV : opens (Spec.T (A⁰_ f)))
  (subset1 : VV ⟶ unop V) :
  Uo 𝒜 hm f_deg VV ⟶
  (((@opens.open_embedding Proj.T (pbo f)).is_open_map.functor.op.obj
        ((opens.map (Proj_iso_Spec_Top_component hm f_deg).hom).op.obj V)).unop) :=
begin
  apply hom_of_le,
  intros γ γ_mem,
  change γ ∈ _ at γ_mem,
  replace subset3 := le_of_hom subset1,
  obtain ⟨⟨γ, γ_mem⟩, rfl⟩ := γ_mem,
  erw set.mem_preimage at γ_mem,
  refine ⟨γ, _, rfl⟩,
  erw set.mem_preimage,
  apply subset3,
  exact γ_mem
end

end is_locally_quotient

lemma is_locally_quotient :
  ∃ (U : opens _) (mem : y.val ∈ U)
    (subset1 : U ⟶
      (((@opens.open_embedding (projective_spectrum.Top 𝒜) (projective_spectrum.basic_open 𝒜 f)).is_open_map.functor.op.obj
        ((opens.map (Proj_iso_Spec_Top_component hm f_deg).hom).op.obj V)).unop))
    (a b : A) (degree : ℕ) (a_hom : a ∈ 𝒜 degree) (b_hom : b ∈ 𝒜 degree),
    ∀ (x : U),
      ∃ (s_nin : b ∉ projective_spectrum.as_homogeneous_ideal x.val),
        (bmk hm f_deg V hh ⟨x.1, (subset1 x).2⟩).val = mk a ⟨b, s_nin⟩ :=
begin
  have y_mem : y.val ∈ projective_spectrum.basic_open 𝒜 f,
  { convert is_locally_quotient.mem_pbo hm f_deg y, },

  have hom_y_mem : (Proj_iso_Spec_Top_component hm f_deg).hom ⟨y.1, y_mem⟩ ∈ unop V,
  { convert is_locally_quotient.hom_apply_mem hm f_deg y, },
  have is_local := hh.2,
  rw structure_sheaf.is_locally_fraction_pred' at is_local,
  specialize is_local ⟨(Proj_iso_Spec_Top_component hm f_deg).hom ⟨y.1, y_mem⟩, hom_y_mem⟩,
  obtain ⟨VV, hom_y_mem_VV, subset1, α, β, is_local⟩ := is_local,

  set U := is_locally_quotient.Uo 𝒜 hm f_deg VV with U_eq,

  have y_mem_U : y.1 ∈ U,
  { use ⟨y.1, y_mem⟩,
    rw set.mem_preimage,
    exact hom_y_mem_VV, },

  set α' : A := α.num with α'_eq,
  set l1 : ℕ := α.denom_mem.some with l1_eq,
  have l1_eq' : _ = f^l1 := α.denom_mem.some_spec.symm,
  have α_eq : α.val = mk α' ⟨f^l1, ⟨_, rfl⟩⟩,
  { rw [α.eq_num_div_denom], congr' 1, rw subtype.ext_iff_val, congr' 1, },

  set β' : A := β.num with β'_eq,
  set l2 : ℕ := β.denom_mem.some with l2_eq,
  have l2_eq' : _ = f^l2 := β.denom_mem.some_spec.symm,
  have β_eq : β.val = mk β' ⟨f^l2, ⟨_, rfl⟩⟩,
  { rw [β.eq_num_div_denom], congr' 1, rw subtype.ext_iff_val, congr' 1, },

  set subset2 : U ⟶ _ := is_locally_quotient.subset2 𝒜 hm f_deg VV subset1,
  refine ⟨U, y_mem_U, subset2, α' * f^l2, β' * f^l1, α.deg + β.deg,
    set_like.graded_monoid.mul_mem α.num_mem_deg (by { rw [←l2_eq'], exact β.denom_mem_deg }),
    by { rw add_comm, exact set_like.graded_monoid.mul_mem β.num_mem_deg (by { rw [←l1_eq'], exact α.denom_mem_deg }) }, _⟩,


  rintros ⟨z, z_mem_U⟩,
  have z_mem_bo : z ∈ pbo f,
  { obtain ⟨⟨z, hz⟩, rfl⟩ := z_mem_U,
    rw set.mem_preimage at hz,
    apply z.2, },

  have hom_z_mem_VV : ((Proj_iso_Spec_Top_component hm f_deg).hom) ⟨z, z_mem_bo⟩ ∈ VV,
  { obtain ⟨γ, h1, h2⟩ := z_mem_U,
    have mem1 := γ.2,
    erw set.mem_preimage at mem1,
    exact mem1, },

  specialize is_local ⟨((Proj_iso_Spec_Top_component hm f_deg).hom ⟨z, z_mem_bo⟩), hom_z_mem_VV⟩,
  obtain ⟨not_mem1, eq1⟩ := is_local,

  have not_mem2 : β' * f ^ l1 ∉ z.as_homogeneous_ideal,
  { intro rid,
    rcases z.is_prime.mem_or_mem rid with H1 | H2,
    { apply not_mem1,
      have eq2 : (localization.mk β' ⟨f^l2, ⟨_, rfl⟩⟩ : localization.away f) =
        localization.mk 1 ⟨f^l2, ⟨_, rfl⟩⟩ * localization.mk β' 1,
      { rw [localization.mk_mul, one_mul, mul_one], },
      erw Proj_iso_Spec_Top_component.to_Spec.mem_carrier_iff,
      rw [β.eq_num_div_denom, ←β'_eq],
      suffices : (mk β' ⟨f^l2, ⟨l2, rfl⟩⟩ : localization.away f) ∈ _,
      { convert this, },
      rw [eq2],
      convert ideal.mul_mem_left _ _ _,
      apply ideal.subset_span,
      refine ⟨β', H1, rfl⟩, },
    { replace H2 := z.is_prime.mem_of_pow_mem _ H2,
      exact z_mem_bo H2, } },
  refine ⟨not_mem2, _⟩,
  have data_eq : data 𝒜 hm f_deg hh (subset2 ⟨z, z_mem_U⟩) =
    hh.val (subset1 ⟨((Proj_iso_Spec_Top_component hm f_deg).hom) ⟨z, z_mem_bo⟩, hom_z_mem_VV⟩),
  { congr', },
  rw ←data_eq at eq1,

  have z_mem2 : z ∈ (((@opens.open_embedding Proj.T (pbo f)).is_open_map.functor.op.obj
        ((opens.map (Proj_iso_Spec_Top_component hm f_deg).hom).op.obj V)).unop),
  { use z,
    refine ⟨_, rfl⟩,
    erw set.mem_preimage,
    apply (le_of_hom subset1),
    exact hom_z_mem_VV, },

  have data_eq2 : data 𝒜 hm f_deg hh (subset2 ⟨z, z_mem_U⟩) = data 𝒜 hm f_deg hh ⟨z, z_mem2⟩,
  { congr', },
  rw [data_eq2, data.eq_num_div_denom, localization.mk_eq_mk'] at eq1,
  erw is_localization.eq at eq1,

  obtain ⟨⟨C, hC⟩, eq1⟩ := eq1,
  set L : ℕ := C.denom_mem.some with L_eq,
  set L_eq' : _ = f^L := C.denom_mem.some_spec.symm with L_eq',
  have C_eq : C.val = mk C.num ⟨f^L, ⟨_, rfl⟩⟩,
  { rw [C.eq_num_div_denom], congr' 1, rw subtype.ext_iff_val, congr' 1 },
  rw [homogeneous_localization.ext_iff_val] at eq1,
  simp only [homogeneous_localization.mul_val, localization.mk_mul, subtype.coe_mk, β_eq, α_eq, C_eq] at eq1,
  simp only [homogeneous_localization.eq_num_div_denom] at eq1,
  simp only [localization.mk_mul, submonoid.coe_mul, subtype.coe_mk] at eq1,
  erw [localization.mk_eq_mk', is_localization.eq] at eq1,
  obtain ⟨⟨_, ⟨M, rfl⟩⟩, eq1⟩ := eq1,
  simp only [←subtype.val_eq_coe,
    submonoid.coe_mul, ←pow_add] at eq1,

  unfold bmk,
  rw [homogeneous_localization.val_mk'],
  simp only [← subtype.val_eq_coe],
  unfold num denom,

  set p := (data.num _ hm f_deg hh ⟨z, z_mem2⟩).num with p_eq,
  set q := (data.denom _ hm f_deg hh ⟨z, z_mem2⟩).num with q_eq,
  set ii := (data.num _ hm f_deg hh ⟨z, z_mem2⟩).denom_mem.some with ii_eq,
  have ii_eq' : _ = f^ii := (data.num _ hm f_deg hh ⟨z, z_mem2⟩).denom_mem.some_spec.symm,
  set jj := (data.denom _ hm f_deg hh ⟨z, z_mem2⟩).denom_mem.some with jj_eq,
  have jj_eq' : _ = f^jj := (data.denom _ hm f_deg hh ⟨z, z_mem2⟩).denom_mem.some_spec.symm,
  simp only [←p_eq, ←q_eq] at eq1,
  rw [ii_eq', jj_eq', ←pow_add, ←pow_add, ←pow_add, ←pow_add] at eq1,

  simp only [localization.mk_eq_mk', is_localization.eq],

  have C_not_mem : C.num ∉ z.as_homogeneous_ideal,
  { intro rid,
    have eq1 : (mk C.num ⟨f ^ L, ⟨_, rfl⟩⟩ : localization.away f) =
      (mk 1 ⟨f^L, ⟨_, rfl⟩⟩ : localization.away f) * mk C.num 1,
      rw [localization.mk_mul, one_mul, mul_one],
    apply hC,
    erw Proj_iso_Spec_Top_component.to_Spec.mem_carrier_iff,
    rw [C_eq, eq1],
    convert ideal.mul_mem_left _ _ _,
    apply ideal.subset_span,
    refine ⟨C.num, rid, rfl⟩ },

  refine ⟨⟨C.num * f^(L+M), begin
    intro rid,
    rcases z.is_prime.mem_or_mem rid with H1 | H2,
    apply C_not_mem H1,
    replace H2 := z.is_prime.mem_of_pow_mem _ H2,
    apply z_mem_bo,
    exact H2,
  end⟩, _⟩,

  simp only [←subtype.val_eq_coe, submonoid.coe_mul],

  suffices EQ : p * f^jj * (β' * f^l1) * (C.num * f^(L+M)) = α' * f^l2 * (q * f^ii) * (C.num * f^(L + M)),
  convert EQ,
  rw calc p * f^jj * (β' * f^l1) * (C.num * f^(L+M))
        = p * f^jj * (β' * f^l1) * (C.num * (f^L * f^M)) : by simp only [pow_add]
    ... = p * β' * C.num * (f^l1 * f^jj * f^L) * f^M : by ring
    ... = p * β' * C.num * f^(l1 + jj + L) * f^M : by simp only [pow_add]
    ... = α' * q * C.num * f ^ (ii + l2 + L) * f ^ M : by rw eq1,
  ring_exp,
end

def to_fun.aux (hh : (Spec (A⁰_ f)).presheaf.obj V) : ((Proj_iso_Spec_Top_component hm f_deg).hom _* (Proj| (pbo f)).presheaf).obj V :=
⟨bmk hm f_deg V hh, λ y, begin
  rcases is_locally_quotient hm f_deg V hh y with ⟨VV, mem1, subset1, a, b, degree, a_mem, b_mem, l⟩,
  refine ⟨VV, mem1, subset1, degree, ⟨a, a_mem⟩, ⟨b, b_mem⟩, λ x, _⟩,
  rcases l x with ⟨s_nin, l⟩,
  refine ⟨s_nin, _⟩,
  dsimp only,
  rw [homogeneous_localization.ext_iff_val, homogeneous_localization.val_mk'],
  simp only [← subtype.val_eq_coe],
  erw ← l,
  rw ← homogeneous_localization.ext_iff_val,
  congr' 1
end⟩

def to_fun : (Spec (A⁰_ f)).presheaf.obj V ⟶ ((Proj_iso_Spec_Top_component hm f_deg).hom _* (Proj| (pbo f)).presheaf).obj V :=
{ to_fun := λ hh, to_fun.aux 𝒜 hm f_deg V hh,
  map_one' := begin
    rw subtype.ext_iff,
    convert bmk_one hm f_deg V,
  end,
  map_mul' := λ x y, begin
    rw subtype.ext_iff,
    convert bmk_mul 𝒜 hm f_deg V x y,
  end,
  map_zero' := begin
    rw subtype.ext_iff,
    convert bmk_zero hm f_deg V,
  end,
  map_add' := λ x y, begin
    rw subtype.ext_iff,
    convert bmk_add 𝒜 hm f_deg V x y,
  end }

end from_Spec

def from_Spec {f : A} {m : ℕ} (hm : 0 < m) (f_deg : f ∈ 𝒜 m) :
  (Spec (A⁰_ f)).presheaf ⟶ (Proj_iso_Spec_Top_component hm f_deg).hom _* (Proj| (pbo f)).presheaf :=
{ app := λ V, from_Spec.to_fun 𝒜 hm f_deg V,
  naturality' := λ U V subset1, begin
    ext1 z,
    simp only [comp_apply, ring_hom.coe_mk, functor.op_map, presheaf.pushforward_obj_map],
    refl,
  end }

namespace to_Spec

variables {𝒜} {f : A} {m : ℕ} (hm : 0 < m) (f_deg : f ∈ 𝒜 m)
variable (U : (opens (Spec.T (A⁰_ f)))ᵒᵖ)

local notation `pf_sheaf` x := (Proj_iso_Spec_Top_component hm f_deg).hom _* x.presheaf -- pushforward a sheaf

variable (hh : (pf_sheaf (Proj| (pbo f))).obj U)

lemma pf_sheaf.one_val :
  (1 : (pf_sheaf (Proj| (pbo f))).obj U).1 = 1 := rfl

lemma pf_sheaf.zero_val :
  (0 : (pf_sheaf (Proj| (pbo f))).obj U).1 = 0 := rfl

lemma pf_sheaf.add_val (x y : (pf_sheaf (Proj| (pbo f))).obj U) :
  (x + y).1 = x.1 + y.1 := rfl

lemma pf_sheaf.mul_val (x y : (pf_sheaf (Proj| (pbo f))).obj U) :
  (x * y).1 = x.1 * y.1 := rfl

variables {f_deg hm U}
lemma inv_mem (y : unop U) :
  ((Proj_iso_Spec_Top_component hm f_deg).inv y.1).1 ∈
    ((@opens.open_embedding Proj.T (pbo f)).is_open_map.functor.op.obj
      ((opens.map (Proj_iso_Spec_Top_component hm f_deg).hom).op.obj U)).unop :=
begin
  refine ⟨⟨((Proj_iso_Spec_Top_component hm f_deg).inv y.1).1, ((Proj_iso_Spec_Top_component hm f_deg).inv y.1).2⟩, _, rfl⟩,
  change _ ∈ _ ⁻¹' _,
  erw set.mem_preimage,
  change (Proj_iso_Spec_Top_component.to_Spec.to_fun 𝒜 f (Proj_iso_Spec_Top_component.from_Spec.to_fun f_deg hm y.1)) ∈ _,
  erw Proj_iso_Spec_Top_component.to_Spec_from_Spec 𝒜 hm f_deg y.1,
  exact y.2,
end

variables (f_deg hm)
def hl (y : unop U) : homogeneous_localization 𝒜 _ :=
hh.1 ⟨((Proj_iso_Spec_Top_component hm f_deg).inv y.1).1, inv_mem y⟩

lemma hl.one (y : unop U) :
  hl hm f_deg 1 y = 1 :=
by rw [hl, pf_sheaf.one_val, pi.one_apply]

lemma hl.zero (y : unop U) :
  hl hm f_deg 0 y = 0 :=
by rw [hl, pf_sheaf.zero_val, pi.zero_apply]

lemma hl.add (x y : (pf_sheaf (Proj| (pbo f))).obj U) (z : unop U) :
  hl hm f_deg (x + y) z = hl hm f_deg x z + hl hm f_deg y z :=
by rw [hl, pf_sheaf.add_val, pi.add_apply, hl, hl]

lemma hl.mul (x y : (pf_sheaf (Proj| (pbo f))).obj U) (z : unop U) :
  hl hm f_deg (x * y) z = hl hm f_deg x z * hl hm f_deg y z :=
by rw [hl, hl, hl, pf_sheaf.mul_val, pi.mul_apply]


def num (y : unop U) : A⁰_ f :=
quotient.mk'
{ deg := m * (hl hm f_deg hh y).deg,
  num := ⟨(hl hm f_deg hh y).num * (hl hm f_deg hh y).denom ^ m.pred,
  begin
    rw calc m * (hl hm f_deg hh y).deg = (m.pred + 1) * (hl hm f_deg hh y).deg : _
    ... = m.pred * (hl hm f_deg hh y).deg + (hl hm f_deg hh y).deg : by rw [add_mul, one_mul]
    ... = (hl hm f_deg hh y).deg + m.pred * (hl hm f_deg hh y).deg : by rw add_comm,
    exact mul_mem (hl hm f_deg hh y).num_mem_deg (set_like.pow_mem_graded _ (hl hm f_deg hh y).denom_mem_deg),
    congr, rw ←nat.succ_pred_eq_of_pos hm, refl,
  end⟩,
  denom := ⟨f^(hl hm f_deg hh y).deg, by rw [mul_comm]; exact set_like.pow_mem_graded _ f_deg⟩,
  denom_mem := ⟨_, rfl⟩ }
-- ⟨mk ((hl hm f_deg hh y).num * (hl hm f_deg hh y).denom ^ m.pred) ⟨f^(hl hm hh y).deg, ⟨_, rfl⟩⟩,
--   ⟨(hl hm hh y).deg, ⟨(hl hm hh y).num * (hl hm hh y).denom ^ m.pred, begin
--     convert mul_mem (hl hm hh y).num_mem (set_like.graded_monoid.pow_mem m.pred (hl hm hh y).denom_mem),
--     exact calc m * (hl hm hh y).deg
--             = (m.pred + 1) * (hl hm hh y).deg
--             : begin
--               congr,
--               conv_lhs { rw ←nat.succ_pred_eq_of_pos hm },
--             end
--         ... = m.pred * (hl hm hh y).deg +
--               1 * (hl hm hh y).deg
--             : by rw add_mul
--         ... = _ : begin
--           rw [add_comm, one_mul],
--           congr,
--         end,
--   end⟩, rfl⟩⟩

def denom (y : unop U) : A⁰_ f :=
quotient.mk'
{ deg := m * (hl hm f_deg hh y).deg,
  num := ⟨(hl hm f_deg hh y).denom ^ m, set_like.pow_mem_graded _ (hl hm f_deg hh y).denom_mem_deg⟩,
  denom := ⟨f ^ (hl hm f_deg hh y).deg, by rw [mul_comm]; exact set_like.pow_mem_graded _ f_deg⟩,
  denom_mem := ⟨_, rfl⟩ }
-- ⟨mk ((hl hm hh y).denom ^ m) ⟨f^(hl hm hh y).deg, ⟨_, rfl⟩⟩,
--   ⟨(hl hm hh y).deg, ⟨_, set_like.graded_monoid.pow_mem m (hl hm hh y).denom_mem⟩, rfl⟩⟩

lemma denom.not_mem (y : unop U) : denom hm f_deg hh y ∉ y.1.as_ideal := λ r,
begin
  have prop1 := (hl hm f_deg hh y).denom_mem,
  change _ ∉ (Proj_iso_Spec_Top_component.from_Spec.to_fun f_deg hm y.1).1.as_homogeneous_ideal at prop1,
  contrapose! prop1,
  change ∀ _, _,

  contrapose! prop1,
  obtain ⟨n, hn⟩ := prop1,

  have eq1 : (hl hm f_deg hh y).deg = n,
  { -- n ≠ i, contradiction,
    by_contra ineq,
    simp only [graded_algebra.proj_apply, direct_sum.decompose_of_mem_ne 𝒜 ((hl hm f_deg hh y).denom_mem_deg) ineq, zero_pow hm, mk_zero] at hn,
    apply hn,
    rw homogeneous_localization.mk'_zero,
    convert submodule.zero_mem _ using 1, },
  apply hn,
  rw ←eq1,
  convert r,
  rw [graded_algebra.proj_apply, direct_sum.decompose_of_mem_same],
  exact (hl hm f_deg hh y).denom_mem_deg,
end

def fmk (y : unop U) : localization.at_prime y.1.as_ideal :=
mk (num hm f_deg hh y) ⟨denom hm f_deg hh y, denom.not_mem hm f_deg hh y⟩

lemma fmk.one (y : unop U) : fmk hm f_deg 1 y = 1 :=
begin
  unfold fmk,
  dsimp only,
  rw [show (1 : structure_sheaf.localizations (A⁰_ f) y.val) =
    localization.mk 1 1, begin
      erw localization.mk_self 1,
    end, localization.mk_eq_mk', is_localization.eq],

  have eq1 := (hl hm f_deg 1 y).eq_num_div_denom,
  rw [hl.one, homogeneous_localization.one_val] at eq1,
  erw [show (1 : localization.at_prime ((Proj_iso_Spec_Top_component hm f_deg).inv y.1).1.as_homogeneous_ideal.to_ideal) =
    mk 1 1,
      begin
        symmetry,
        convert localization.mk_self _,
        refl,
      end, localization.mk_eq_mk', is_localization.eq] at eq1,
  obtain ⟨⟨c, hc1⟩, eq1⟩ := eq1,

  change ¬(∀ i : ℕ, _ ∈ _) at hc1,
  rw not_forall at hc1,
  obtain ⟨j, hc1⟩ := hc1,
  rw [one_mul, submonoid.coe_one, mul_one] at eq1,
  simp only [←subtype.val_eq_coe] at eq1,
  rw [← hl.one] at eq1,
  have eq2 : graded_algebra.proj 𝒜 ((hl hm f_deg 1 y).deg + j) ((hl hm f_deg 1 y).denom * c)
    = graded_algebra.proj 𝒜 ((hl hm f_deg 1 y).deg + j) ((hl hm f_deg 1 y).num * c),
  { exact congr_arg _ eq1, },

  have eq3 : graded_algebra.proj 𝒜 ((hl hm f_deg 1 y).deg + j) ((hl hm f_deg 1 y).denom * c)
    = (hl hm f_deg 1 y).denom * (graded_algebra.proj 𝒜 j c),
  { apply graded_algebra.proj_hom_mul,
    exact (hl hm f_deg 1 y).denom_mem_deg,
    intro rid,
    apply hc1,
    simp only [rid, zero_pow hm, localization.mk_zero],
    rw homogeneous_localization.mk'_zero,
    convert submodule.zero_mem _ using 1, },

  have eq4 : graded_algebra.proj 𝒜 ((hl hm f_deg 1 y).deg + j)
    ((hl hm f_deg 1 y).num * c)
    = (hl hm f_deg 1 y).num * (graded_algebra.proj 𝒜 j c),
  { apply graded_algebra.proj_hom_mul,
    exact (hl hm f_deg 1 y).num_mem_deg,
    intro rid,
    apply hc1,
    simp only [rid, zero_pow hm, localization.mk_zero],
    rw homogeneous_localization.mk'_zero,
    exact submodule.zero_mem _, },

  erw [eq3, eq4] at eq2,

  refine ⟨⟨quotient.mk'
    ⟨m * j,
     ⟨(graded_algebra.proj 𝒜 j c)^m, set_like.pow_mem_graded _ (submodule.coe_mem _)⟩,
     ⟨f^j, by rw [mul_comm]; exact set_like.pow_mem_graded _ f_deg⟩, ⟨_, rfl⟩⟩, hc1⟩, _⟩,
  rw [submonoid.coe_one, one_mul, mul_one],
  dsimp only [subtype.coe_mk],

  unfold num denom,
  rw [homogeneous_localization.ext_iff_val],
  simp only [homogeneous_localization.mul_val, homogeneous_localization.val_mk',
    subtype.coe_mk],
  rw [mk_mul, mk_mul],
  congr' 1,
  exact calc (hl hm f_deg 1 y).num * (hl hm f_deg 1 y).denom ^ m.pred * (graded_algebra.proj 𝒜 j) c ^ m
          = (hl hm f_deg 1 y).num * (hl hm f_deg 1 y).denom ^ m.pred * (graded_algebra.proj 𝒜 j) c ^ (m.pred + 1)
          : begin
            congr',
            symmetry,
            apply nat.succ_pred_eq_of_pos,
            exact hm
          end
      ... = (hl hm f_deg 1 y).num * (hl hm f_deg 1 y).denom ^ m.pred * ((graded_algebra.proj 𝒜 j) c ^ m.pred * graded_algebra.proj 𝒜 j c)
          : by ring_exp
      ... = ((hl hm f_deg 1 y).num * graded_algebra.proj 𝒜 j c) * ((hl hm f_deg 1 y).denom ^ m.pred * (graded_algebra.proj 𝒜 j) c ^ m.pred)
          : by ring
      ... = ((hl hm f_deg 1 y).denom * graded_algebra.proj 𝒜 j c) * ((hl hm f_deg 1 y).denom ^ m.pred * (graded_algebra.proj 𝒜 j) c ^ m.pred)
          : by rw eq2
      ... = ((hl hm f_deg 1 y).denom * graded_algebra.proj 𝒜 j c) ^ (1 + m.pred)
          : by ring_exp
      ... = ((hl hm f_deg 1 y).denom * graded_algebra.proj 𝒜 j c) ^ m
          : begin
            congr' 1,
            rw [add_comm],
            convert nat.succ_pred_eq_of_pos hm,
          end
      ... = _ : by rw mul_pow,
end

lemma fmk.zero (y : unop U) : fmk hm f_deg 0 y = 0 :=
begin
  unfold fmk,
  rw [show (0 : structure_sheaf.localizations (A⁰_ f) y.val) =
    localization.mk 0 1, begin
      rw localization.mk_zero,
    end, localization.mk_eq_mk', is_localization.eq],
  dsimp only,

  have eq1 := (hl hm f_deg 0 y).eq_num_div_denom,
  rw [hl.zero, homogeneous_localization.zero_val] at eq1,
  erw [show (0 : localization.at_prime ((Proj_iso_Spec_Top_component hm f_deg).inv y.1).1.as_homogeneous_ideal.to_ideal) =
    localization.mk 0 1,
      begin
        rw localization.mk_zero,
      end, localization.mk_eq_mk', is_localization.eq] at eq1,
  obtain ⟨⟨c, hc1⟩, eq1⟩ := eq1,
  rw [zero_mul, zero_mul, submonoid.coe_one, mul_one] at eq1,
  simp only [subtype.coe_mk] at eq1,
  dsimp only at eq1,

  change c ∉ Proj_iso_Spec_Top_component.from_Spec.carrier _ _ at hc1,
  change ¬(∀ i : ℕ, _ ∈ _) at hc1,
  rw not_forall at hc1,
  obtain ⟨j, hc1⟩ := hc1,
  replace eq1 := eq1.symm,
  have eq2 : graded_algebra.proj 𝒜 ((hl hm f_deg 0 y).deg + j) ((hl hm f_deg 0 y).num * c) = 0,
  { erw [eq1, linear_map.map_zero], },
  have eq3 : graded_algebra.proj 𝒜 ((hl hm f_deg 0 y).deg + j) ((hl hm f_deg 0 y).num * c)
    = (hl hm f_deg 0 y).num * graded_algebra.proj 𝒜 j c,
  { apply graded_algebra.proj_hom_mul,
    exact (hl hm f_deg 0 y).num_mem_deg,
    intro rid,
    apply hc1,
    simp only [rid, zero_pow hm, mk_zero],
    rw homogeneous_localization.mk'_zero,
    exact submodule.zero_mem _, },
    erw eq3 at eq2,

  refine ⟨⟨quotient.mk' ⟨m * j, ⟨(graded_algebra.proj 𝒜 j c)^m, set_like.pow_mem_graded _ (submodule.coe_mem _)⟩,
    ⟨f^j, by rw [mul_comm]; exact set_like.pow_mem_graded _ f_deg⟩, ⟨_, rfl⟩⟩, hc1⟩, _⟩,
  unfold num,
  simp only [homogeneous_localization.ext_iff_val, homogeneous_localization.mul_val, submonoid.coe_one,
    homogeneous_localization.zero_val, homogeneous_localization.one_val, mul_one, one_mul, mul_zero, zero_mul,
    homogeneous_localization.val_mk', subtype.coe_mk],
  rw [mk_mul],
  convert mk_zero _,
  exact calc (hl hm f_deg 0 y).num * (hl hm f_deg 0 y).denom ^ m.pred * (graded_algebra.proj 𝒜 j) c ^ m
          = (hl hm f_deg 0 y).num * (hl hm f_deg 0 y).denom ^ m.pred * (graded_algebra.proj 𝒜 j) c ^ (m.pred + 1)
          : begin
            congr',
            symmetry,
            apply nat.succ_pred_eq_of_pos,
            exact hm
          end
      ... = (hl hm f_deg 0 y).num * (hl hm f_deg 0 y).denom ^ m.pred * ((graded_algebra.proj 𝒜 j) c ^ m.pred * graded_algebra.proj 𝒜 j c)
          : by rw [pow_add, pow_one]
      ... = ((hl hm f_deg 0 y).num * graded_algebra.proj 𝒜 j c)
            * ((hl hm f_deg 0 y).denom ^ m.pred * (graded_algebra.proj 𝒜 j) c ^ m.pred) : by ring
      ... = 0 * ((hl hm f_deg 0 y).denom ^ m.pred * (graded_algebra.proj 𝒜 j) c ^ m.pred) : by rw eq2
      ... = 0 : by rw zero_mul,
end

lemma fmk.add (x y : (pf_sheaf (Proj| (pbo f))).obj U) (z : unop U) :
  fmk hm f_deg (x + y) z = fmk hm f_deg x z + fmk hm f_deg y z :=
begin
  unfold fmk,
  rw [localization.add_mk],

  have eq_xz := (hl hm f_deg x z).eq_num_div_denom,
  have eq_yz := (hl hm f_deg y z).eq_num_div_denom,
  have eq_addz := (hl hm f_deg (x + y) z).eq_num_div_denom,
  rw [hl.add, homogeneous_localization.add_val, eq_xz, eq_yz, localization.add_mk, localization.mk_eq_mk', is_localization.eq] at eq_addz,
  obtain ⟨⟨c, hc⟩, eq_addz⟩ := eq_addz,
  simp only [submonoid.coe_mul, subtype.coe_mk] at eq_addz ⊢,

  set d_x := (hl hm f_deg x z).denom with dx_eq,
  set n_x := (hl hm f_deg x z).num with nx_eq,
  set d_y := (hl hm f_deg y z).denom with dy_eq,
  set n_y := (hl hm f_deg y z).num with ny_eq,
  set d_xy := (hl hm f_deg (x + y) z).denom with dxy_eq,
  set n_xy := (hl hm f_deg (x + y) z).num with nxy_eq,
  set i_x := (hl hm f_deg x z).deg with ix_eq,
  set i_y := (hl hm f_deg y z).deg with iy_eq,
  set i_xy := (hl hm f_deg (x + y) z).deg with ixy_eq,

  unfold num denom,
  simp only [←dx_eq, ←nx_eq, ←dy_eq, ←ny_eq, ←dxy_eq, ←nxy_eq, ←i_x, ←i_y, ←i_xy] at eq_addz ⊢,
  rw [localization.mk_eq_mk', is_localization.eq],

  change ¬(∀ i : ℕ, _ ∈ _) at hc,
  rw not_forall at hc,
  obtain ⟨j, hc⟩ := hc,

  refine ⟨⟨_, hc⟩, _⟩,
  rw [submonoid.coe_mul],
  simp only [subtype.coe_mk, homogeneous_localization.ext_iff_val, homogeneous_localization.mul_val,
    homogeneous_localization.add_val, homogeneous_localization.val_mk', mk_mul, add_mk, submonoid.coe_mul],
  rw [localization.mk_eq_mk', is_localization.eq],
  use 1,
  simp only [submonoid.coe_one, submonoid.mk_mul_mk, set_like.coe_mk, mul_one, ← pow_add],

  rw calc (f ^ (i_x + i_y) * (d_y ^ m * (n_x * d_x ^ m.pred))
          + f ^ (i_y + i_x) * (d_x ^ m * (n_y * d_y ^ m.pred)))
          * d_xy ^ m
          * (graded_algebra.proj 𝒜 j) c ^ m
          * f ^ (i_xy + (i_x + i_y) + j)
        = (f ^ (i_x + i_y) * (d_y ^ m * (n_x * d_x ^ m.pred))
            + f ^ (i_x + i_y) * (d_x ^ m * (n_y * d_y ^ m.pred)))
          * d_xy ^ m
          * (graded_algebra.proj 𝒜 j) c ^ m
          * f ^ (i_xy + (i_x + i_y) + j)
        : begin
          congr' 4,
          rw add_comm,
        end
    ... = (f ^ (i_x + i_y) * (d_y ^ m * (n_x * d_x ^ m.pred) + d_x ^ m * (n_y * d_y ^ m.pred)))
          * d_xy ^ m
          * (graded_algebra.proj 𝒜 j) c ^ m
          * f ^ (i_xy + (i_x + i_y) + j)
        : begin
          congr' 3,
          rw mul_add,
        end
    ... = (d_y ^ m * (n_x * d_x ^ m.pred) + d_x ^ m * (n_y * d_y ^ m.pred))
          * d_xy ^ m
          * (graded_algebra.proj 𝒜 j) c ^ m
          * (f ^ (i_x + i_y) * f ^ (i_xy + (i_x + i_y) + j)) : by ring
    ... = (d_y ^ m * (n_x * d_x ^ m.pred) + d_x ^ m * (n_y * d_y ^ m.pred))
          * d_xy ^ m
          * (graded_algebra.proj 𝒜 j) c ^ m
          * (f ^ (i_x + i_y + (i_xy + (i_x + i_y) + j)))
        : begin
          congr' 1,
          rw [←pow_add],
        end
    ... = (d_y ^ m * (n_x * d_x ^ m.pred) + d_x ^ m * (n_y * d_y ^ m.pred))
          * d_xy ^ m
          * (graded_algebra.proj 𝒜 j) c ^ m
          * (f ^ (i_x + i_y + (i_y + i_x) + i_xy + j))
        : begin
          congr' 2,
          ring,
        end,
  congr' 1,
  suffices EQ : (d_x * n_y + d_y * n_x) * d_xy * graded_algebra.proj 𝒜 j c = n_xy * (d_x * d_y) * graded_algebra.proj 𝒜 j c,
  { rw calc n_xy * d_xy ^ m.pred * (d_x ^ m * d_y ^ m) * (graded_algebra.proj 𝒜 j) c ^ m
          = n_xy * d_xy ^ m.pred * (d_x ^ m * d_y ^ m) * (graded_algebra.proj 𝒜 j) c ^ (m.pred + 1)
          : begin
            congr',
            symmetry,
            apply nat.succ_pred_eq_of_pos hm,
          end
      ... = n_xy * d_xy ^ m.pred * (d_x ^ (m.pred + 1) * d_y ^ m) * (graded_algebra.proj 𝒜 j) c ^ (m.pred + 1)
          : begin
            congr',
            symmetry,
            apply nat.succ_pred_eq_of_pos hm,
          end
      ... = n_xy * d_xy ^ m.pred * (d_x ^ (m.pred + 1) * d_y ^ (m.pred + 1)) * (graded_algebra.proj 𝒜 j) c ^ (m.pred + 1)
          : begin
            congr',
            symmetry,
            apply nat.succ_pred_eq_of_pos hm,
          end
      ... = n_xy * d_xy ^ m.pred * (d_x ^ m.pred * d_x * (d_y ^ m.pred * d_y))
            * ((graded_algebra.proj 𝒜 j) c ^ m.pred * (graded_algebra.proj 𝒜 j) c)
          : begin
            simp only [pow_add, pow_one],
          end
      ... = (n_xy * (d_x * d_y) * graded_algebra.proj 𝒜 j c)
            * (d_xy ^ m.pred * d_x ^ m.pred * d_y ^ m.pred * (graded_algebra.proj 𝒜 j c) ^ m.pred)
          : by ring
      ... = ((d_x * n_y + d_y * n_x) * d_xy * (graded_algebra.proj 𝒜 j) c)
            * (d_xy ^ m.pred * d_x ^ m.pred * d_y ^ m.pred * (graded_algebra.proj 𝒜 j c) ^ m.pred)
          : by rw EQ
      ... = (d_x * n_y + d_y * n_x)
            * ((d_xy ^ m.pred * d_xy) * d_x ^ m.pred * d_y ^ m.pred
              * ((graded_algebra.proj 𝒜 j c) ^ m.pred * (graded_algebra.proj 𝒜 j c)))
          : by ring
      ... = (d_x * n_y + d_y * n_x)
            * (d_xy ^ m * d_x ^ m.pred * d_y ^ m.pred
              * (graded_algebra.proj 𝒜 j c) ^ m)
          : begin
            congr';
            conv_rhs { rw [show m = m.pred + 1, from (nat.succ_pred_eq_of_pos hm).symm] };
            rw [pow_add, pow_one],
          end
      ... = (d_x * n_y + d_y * n_x)
            * d_x ^ m.pred * d_y ^ m.pred * d_xy ^ m
            * (graded_algebra.proj 𝒜 j c) ^ m : by ring,
    congr',

    exact calc (d_x * n_y + d_y * n_x) * d_x ^ m.pred * d_y ^ m.pred
          = (d_y ^ m.pred * d_y) * (n_x * d_x ^ m.pred) + (d_x ^ m.pred * d_x) * (n_y * d_y ^ m.pred)
          : by ring
      ... = (d_y ^ m.pred * d_y^1) * (n_x * d_x ^ m.pred) + (d_x ^ m.pred * d_x ^ 1) * (n_y * d_y ^ m.pred)
          : by simp only [pow_one]
      ... = (d_y ^ (m.pred + 1)) * (n_x * d_x ^ m.pred) + (d_x ^ (m.pred + 1)) * (n_y * d_y ^ m.pred)
          : by simp only [pow_add]
      ... = d_y ^ m * (n_x * d_x ^ m.pred) + d_x ^ m * (n_y * d_y ^ m.pred)
          : begin
            congr';
            apply nat.succ_pred_eq_of_pos hm,
          end, },

  replace eq_addz := congr_arg (graded_algebra.proj 𝒜 ((i_x + i_y) + i_xy + j)) eq_addz,
  have eq1 : (graded_algebra.proj 𝒜 (i_x + i_y + i_xy + j)) ((d_x * n_y + d_y * n_x) * d_xy * c)
    = (d_x * n_y + d_y * n_x) * d_xy * graded_algebra.proj 𝒜 j c,
  { apply graded_algebra.proj_hom_mul,
    { apply set_like.graded_monoid.mul_mem,
      apply submodule.add_mem _ _ _,
      apply set_like.graded_monoid.mul_mem,
      exact (hl hm f_deg x z).denom_mem_deg,
      exact (hl hm f_deg y z).num_mem_deg,
      rw add_comm,
      apply set_like.graded_monoid.mul_mem,
      exact (hl hm f_deg y z).denom_mem_deg,
      exact (hl hm f_deg x z).num_mem_deg,
      exact (hl hm f_deg (x + y) z).denom_mem_deg, },
    intro rid,
    apply hc,
    simp only [rid, zero_pow hm, localization.mk_zero],
    rw homogeneous_localization.mk'_zero,
    exact submodule.zero_mem _, },
  erw eq1 at eq_addz,
  clear eq1,

  have eq2 : (graded_algebra.proj 𝒜 (i_x + i_y + i_xy + j)) (n_xy * (d_x * d_y) * c)
    = n_xy * (d_x * d_y) * graded_algebra.proj 𝒜 j c,
  { apply graded_algebra.proj_hom_mul,
    { rw show i_x + i_y + i_xy = i_xy + (i_x + i_y), by ring,
      apply set_like.graded_monoid.mul_mem,
      exact (hl hm f_deg (x + y) z).num_mem_deg,
      apply set_like.graded_monoid.mul_mem,
      exact (hl hm f_deg _ z).denom_mem_deg,
      exact (hl hm f_deg _ z).denom_mem_deg, },
    intro rid,
    apply hc,
    simp only [rid, zero_pow hm, localization.mk_zero],
    rw homogeneous_localization.mk'_zero,
    exact submodule.zero_mem _, },
  erw eq2 at eq_addz,
  exact eq_addz,
end

lemma fmk.mul (x y : (pf_sheaf (Proj| (pbo f))).obj U) (z : unop U) :
  fmk hm f_deg (x * y) z = fmk hm f_deg x z * fmk hm f_deg y z :=
begin
  unfold fmk,
  rw [mk_mul],

  have eq_xz := (hl hm f_deg x z).eq_num_div_denom,
  have eq_yz := (hl hm f_deg y z).eq_num_div_denom,
  have eq_mulz := (hl hm f_deg (x * y) z).eq_num_div_denom,
  rw [hl.mul, homogeneous_localization.mul_val, eq_xz, eq_yz, mk_mul, mk_eq_mk', is_localization.eq] at eq_mulz,
  obtain ⟨⟨c, hc⟩, eq_mulz⟩ := eq_mulz,
  simp only [submonoid.coe_mul] at eq_mulz,
  simp only [← subtype.val_eq_coe] at eq_mulz,

  set d_x := (hl hm f_deg x z).denom with dx_eq,
  set n_x := (hl hm f_deg x z).num with nx_eq,
  set d_y := (hl hm f_deg y z).denom with dy_eq,
  set n_y := (hl hm f_deg y z).num with ny_eq,
  set d_xy := (hl hm f_deg (x * y) z).denom with dxy_eq,
  set n_xy := (hl hm f_deg (x * y) z).num with nxy_eq,
  set i_x := (hl hm f_deg x z).deg with ix_eq,
  set i_y := (hl hm f_deg y z).deg with iy_eq,
  set i_xy := (hl hm f_deg (x * y) z).deg with ixy_eq,

  unfold num denom,
  simp only [←dx_eq, ←nx_eq, ←dy_eq, ←ny_eq, ←dxy_eq, ←nxy_eq, ←i_x, ←i_y, ←i_xy] at eq_mulz ⊢,
  rw [localization.mk_eq_mk', is_localization.eq],

  change ¬(∀ i : ℕ, _ ∈ _) at hc,
  erw not_forall at hc,
  obtain ⟨j, hc⟩ := hc,

  refine ⟨⟨_, hc⟩, _⟩,
  simp only [submonoid.coe_mul, subtype.coe_mk, homogeneous_localization.ext_iff_val,
    submonoid.coe_mul, homogeneous_localization.mul_val, homogeneous_localization.val_mk',
    mk_mul],
  simp only [mk_eq_mk', is_localization.eq],

  use 1,
  simp only [submonoid.coe_one, submonoid.coe_mul, mul_one],
  simp only [← subtype.val_eq_coe, ← pow_add],

  suffices EQ : n_x * n_y * d_xy * graded_algebra.proj 𝒜 j c = n_xy * (d_x * d_y) * graded_algebra.proj 𝒜 j c,

  rw calc n_xy * d_xy ^ m.pred * (d_x ^ m * d_y ^ m)
          * (graded_algebra.proj 𝒜 j) c ^ m
          * f ^ (i_x + i_y + i_xy + j)
        = n_xy * d_xy ^ m.pred * (d_x ^ m * d_y ^ m)
          * (graded_algebra.proj 𝒜 j) c ^ (m.pred + 1)
          * f ^ (i_x + i_y + i_xy + j)
        : begin
          congr',
          symmetry,
          apply nat.succ_pred_eq_of_pos hm,
        end
    ... = n_xy * d_xy ^ m.pred * (d_x ^ m * d_y ^ m)
          * ((graded_algebra.proj 𝒜 j) c ^ m.pred * (graded_algebra.proj 𝒜 j) c)
          * f ^ (i_x + i_y + i_xy + j)
        : by ring_exp
    ... = n_xy * d_xy ^ m.pred * (d_x ^ (m.pred + 1) * d_y ^ (m.pred + 1))
          * ((graded_algebra.proj 𝒜 j) c ^ m.pred * (graded_algebra.proj 𝒜 j) c)
          * f ^ (i_x + i_y + i_xy + j)
        : begin
          congr',
          all_goals { symmetry, apply nat.succ_pred_eq_of_pos hm, },
        end
    ... = (n_xy * (d_x * d_y) * graded_algebra.proj 𝒜 j c) * (d_xy^m.pred * d_x^m.pred * d_y^m.pred * (graded_algebra.proj 𝒜 j c)^m.pred)
          * f ^ (i_x + i_y + i_xy + j)
        : by ring_exp
    ... = (n_x * n_y * d_xy * graded_algebra.proj 𝒜 j c) * (d_xy^m.pred * d_x^m.pred * d_y^m.pred * (graded_algebra.proj 𝒜 j c)^m.pred)
          * f ^ (i_x + i_y + i_xy + j)
        : by rw EQ
    ... = (n_x * n_y * d_xy) * (d_xy^m.pred * d_x^m.pred * d_y^m.pred * ((graded_algebra.proj 𝒜 j c)^m.pred * graded_algebra.proj 𝒜 j c))
          * f ^ (i_x + i_y + i_xy + j) : by ring
    ... = (n_x * n_y * d_xy) * (d_xy^m.pred * d_x^m.pred * d_y^m.pred * ((graded_algebra.proj 𝒜 j c)^m.pred * (graded_algebra.proj 𝒜 j c)^1))
          * f ^ (i_x + i_y + i_xy + j) : by rw pow_one
    ... = (n_x * n_y * d_xy) * (d_xy^m.pred * d_x^m.pred * d_y^m.pred * ((graded_algebra.proj 𝒜 j c)^(m.pred + 1)))
          * f ^ (i_x + i_y + i_xy + j)
        : by ring_exp
    ... = (n_x * n_y * d_xy) * (d_xy^m.pred * d_x^m.pred * d_y^m.pred * ((graded_algebra.proj 𝒜 j c)^m))
          * f ^ (i_x + i_y + i_xy + j)
        : begin
          congr',
          exact nat.succ_pred_eq_of_pos hm,
        end
    ... = (n_x * n_y) * ((d_xy^m.pred * d_xy) * d_x^m.pred * d_y^m.pred * ((graded_algebra.proj 𝒜 j c)^m))
          * f ^ (i_x + i_y + i_xy + j) : by ring
    ... = (n_x * n_y) * ((d_xy^m.pred * d_xy^1) * d_x^m.pred * d_y^m.pred * ((graded_algebra.proj 𝒜 j c)^m))
          * f ^ (i_x + i_y + i_xy + j) : by rw pow_one
    ... = (n_x * n_y) * ((d_xy^(m.pred + 1)) * d_x^m.pred * d_y^m.pred * ((graded_algebra.proj 𝒜 j c)^m))
          * f ^ (i_x + i_y + i_xy + j)
        : by ring_exp
    ... = (n_x * n_y) * (d_xy^m * d_x^m.pred * d_y^m.pred * ((graded_algebra.proj 𝒜 j c)^m))
          * f ^ (i_x + i_y + i_xy + j)
        : begin
          congr',
          exact nat.succ_pred_eq_of_pos hm,
        end,
  ring_nf,

  have INEQ : graded_algebra.proj 𝒜 j c ≠ 0,
  { intro rid,
    apply hc,
    simp only [rid, zero_pow hm, localization.mk_zero],
    rw homogeneous_localization.mk'_zero,
    exact submodule.zero_mem _, },
  replace eq_mulz := congr_arg (graded_algebra.proj 𝒜 (i_x + i_y + i_xy + j)) eq_mulz,
  rw [graded_algebra.proj_hom_mul, graded_algebra.proj_hom_mul] at eq_mulz,
  exact eq_mulz,

  have : (hl hm f_deg x z * hl hm f_deg y z).num * (d_x * d_y) ∈ 𝒜 (i_xy + (i_x + i_y)),
  { apply set_like.graded_monoid.mul_mem,
    rw [← hl.mul],
    exact (hl hm f_deg (x * y) z).num_mem_deg,
    apply set_like.graded_monoid.mul_mem,
    exact (hl hm f_deg x z).denom_mem_deg,
    exact (hl hm f_deg y z).denom_mem_deg, },
  convert this using 2,
  ring,

  exact INEQ,

  apply set_like.graded_monoid.mul_mem,
  apply set_like.graded_monoid.mul_mem,
  exact (hl hm f_deg x z).num_mem_deg,
  exact (hl hm f_deg y z).num_mem_deg,
  rw [← hl.mul],
  exact (hl hm f_deg (x * y) z).denom_mem_deg,

  exact INEQ,
end

namespace is_locally_quotient

variables {α : Type*} (p : α → Prop)

variable (f_deg)
def open_set (V : opens Proj.T) : opens (Spec.T (A⁰_ f)) :=
⟨homeo_of_iso (Proj_iso_Spec_Top_component hm f_deg) ''
  {z | @coe (subtype _) ↥((Proj.to_LocallyRingedSpace (λ {m : ℕ}, 𝒜 m)).to_Top) _ z ∈ V.1}, begin
  have := Proj.T,
  rw [homeomorph.is_open_image, is_open_induced_iff],
  refine ⟨V.1, V.2, _⟩,
  ext z, split; intro hz,
  { rw set.mem_preimage at hz,
    exact hz, },
  { rw set.mem_preimage,
    exact hz, }
end⟩

lemma open_set_is_subset
  (V : opens Proj.T) (y : unop U)
  (subset1 : V ⟶ ((@opens.open_embedding Proj.T (pbo f)).is_open_map.functor.op.obj
            ((opens.map (Proj_iso_Spec_Top_component hm f_deg).hom).op.obj U)).unop) :
  (open_set 𝒜 hm f_deg V) ⟶ unop U := hom_of_le
begin
  have subset2 := le_of_hom subset1,
  rintros z z_mem,
  obtain ⟨z, z_mem, rfl⟩ := z_mem,
  dsimp only [set.mem_set_of] at z_mem,
  specialize subset2 z_mem,
  obtain ⟨a, a_mem, eq2⟩ := subset2,
  erw set.mem_preimage at a_mem,
  rw homeo_of_iso_apply,
  change _ ∈ (unop U).val,
  convert a_mem,
  rw subtype.ext_iff,
  rw ←eq2,
  refl,
end

lemma mem_open_subset_of_inv_mem (V : opens Proj.T) (y : unop U)
  (mem1 : (((Proj_iso_Spec_Top_component hm f_deg).inv) y.val).val ∈ V) :
  y.1 ∈ open_set 𝒜 hm f_deg V  :=
begin
  refine ⟨(Proj_iso_Spec_Top_component hm f_deg).inv y.1, mem1, _⟩,
  rw [homeo_of_iso_apply],
  convert Proj_iso_Spec_Top_component.to_Spec_from_Spec _ _ _ _,
end

/--
For b ∈ 𝒜 i
z ∈ V and b ∉ z, then b^m / f^i ∉ forward f
-/
lemma not_mem
  (V : opens Proj.T)
  -- (subset1 : V ⟶ ((@opens.open_embedding Proj.T (pbo f)).is_open_map.functor.op.obj
  --           ((opens.map (Top_component hm f_deg).hom).op.obj U)).unop)
  (b : A) (degree : ℕ) (b_mem : b ∈ 𝒜 degree)
  (z : Proj.T| (pbo f))
  (z_mem : z.1 ∈ V.1)
  (b_not_mem : b ∉ z.1.as_homogeneous_ideal) :
  (quotient.mk' ⟨m * degree, ⟨b ^ m, set_like.pow_mem_graded _ b_mem⟩,
    ⟨f^degree, by rw [mul_comm]; exact set_like.pow_mem_graded _ f_deg⟩, ⟨_, rfl⟩⟩ : A⁰_ f)
  ∉ ((homeo_of_iso (Proj_iso_Spec_Top_component hm f_deg)) z).as_ideal := λ rid,
begin
  classical,

  rw homeo_of_iso_apply at rid,
  erw Proj_iso_Spec_Top_component.to_Spec.mem_carrier_iff at rid,
  dsimp only at rid,

  erw [←ideal.submodule_span_eq, finsupp.span_eq_range_total, set.mem_range] at rid,
  obtain ⟨c, eq1⟩ := rid,
  erw [finsupp.total_apply, finsupp.sum] at eq1,
  dsimp only [subtype.coe_mk] at eq1,
  obtain ⟨N, hN⟩ := localization.away.clear_denominator (finset.image (λ i, c i * i.1) c.support),
  -- N is the common denom
  choose after_clear_denominator hacd using hN,
  have prop1 : ∀ i, i ∈ c.support → c i * i.1 ∈ (finset.image (λ i, c i * i.1) c.support),
  { intros i hi, rw finset.mem_image, refine ⟨_, hi, rfl⟩, },
  have eq3 := calc (localization.mk (b^m) 1 : localization.away f) * localization.mk (f^N) 1
          = localization.mk (b^m) ⟨f^degree, ⟨_, rfl⟩⟩ * localization.mk (f^degree) 1 * localization.mk (f^N) 1
          : begin
            congr,
            rw [localization.mk_mul, localization.mk_eq_mk', is_localization.eq],
            use 1,
            erw [mul_one, mul_one, mul_one, mul_one, ←subtype.val_eq_coe],
          end
      ... = localization.mk (f^degree) 1 * localization.mk (b^m) ⟨f^degree, ⟨_, rfl⟩⟩ * localization.mk (f^N) 1
          : by ring
      ... = localization.mk (f^degree) 1 * localization.mk (f^N) 1 * ∑ i in c.support, c i * i.1
          : begin
            erw eq1, rw homogeneous_localization.val_mk',
            simp only [subtype.coe_mk, mk_mul, one_mul, mul_one],
            congr' 1, ring,
          end
      ... = localization.mk (f^degree) 1 * (localization.mk (f^N) 1 * ∑ i in c.support, c i * i.1) : by ring
      ... = localization.mk (f^degree) 1 * ∑ i in c.support, (localization.mk (f^N) 1) * (c i * i.1)
          : begin
            congr' 1,
            rw finset.mul_sum,
          end
      ... = localization.mk (f^degree) 1 * ∑ i in c.support.attach, (localization.mk (f^N) 1) * (c i.1 * i.1.1)
          : begin
            congr' 1,
            symmetry,
            convert finset.sum_attach,
            refl,
          end
      ... = localization.mk (f^degree) 1 * ∑ i in c.support.attach, (localization.mk (after_clear_denominator (c i.1 * i.1.1) (prop1 i.1 i.2)) 1)
          : begin
            congr' 1,
            rw finset.sum_congr rfl (λ j hj, _),
            have eq2 := (hacd (c j.1 * j.1.1) (prop1 j.1 j.2)).2,
            dsimp only at eq2,
            erw eq2,
            rw mul_comm,
          end
      ... = ∑ i in c.support.attach, (localization.mk (f^degree) 1) * (localization.mk (after_clear_denominator (c i.1 * i.1.1) (prop1 i.1 i.2)) 1)
          : begin
            rw finset.mul_sum,
          end
      ... = ∑ i in c.support.attach, localization.mk (f^degree * (after_clear_denominator (c i.1 * i.1.1) (prop1 i.1 i.2))) 1
          : begin
            rw finset.sum_congr rfl (λ j hj, _),
            erw [localization.mk_mul, one_mul],
          end
      ... = localization.mk (∑ i in c.support.attach, (f^degree * (after_clear_denominator (c i.1 * i.1.1) (prop1 i.1 i.2)))) 1
          : begin
            induction c.support.attach using finset.induction_on with y s hy ih,
            rw [finset.sum_empty, finset.sum_empty, localization.mk_zero],
            rw [finset.sum_insert hy, finset.sum_insert hy, ih, localization.add_mk, mul_one, ←subtype.val_eq_coe,
              show (1 : submonoid.powers f).1 = 1, from rfl, one_mul, one_mul, add_comm],
          end,
  erw [localization.mk_mul, one_mul] at eq3,
  simp only [localization.mk_eq_mk', is_localization.eq] at eq3,
  obtain ⟨⟨_, ⟨l, rfl⟩⟩, eq3⟩ := eq3,
  erw [mul_one, ←subtype.val_eq_coe, mul_one] at eq3,
  dsimp only at eq3,
  suffices : (∑ i in c.support.attach, (f^degree * (after_clear_denominator (c i.1 * i.1.1) (prop1 i.1 i.2)))) * f^l ∈ z.1.as_homogeneous_ideal,
  erw ←eq3 at this,
  rcases z.1.is_prime.mem_or_mem this with H1 | H3,
  rcases z.1.is_prime.mem_or_mem H1 with H1 | H2,
  { apply b_not_mem,
    rw z.1.is_prime.pow_mem_iff_mem at H1,
    exact H1,
    exact hm, },
  { have mem3 := z.2,
    have mem4 := z.1.is_prime.mem_of_pow_mem _ H2,
    erw projective_spectrum.mem_basic_open at mem3,
    apply mem3,
    exact mem4, },
  { have mem3 := z.2,
    have mem4 := z.1.is_prime.mem_of_pow_mem _ H3,
    erw projective_spectrum.mem_basic_open at mem3,
    apply mem3,
    exact mem4, },
  apply ideal.mul_mem_right,
  apply ideal.sum_mem,
  intros j hj,
  apply ideal.mul_mem_left,
  set g := classical.some j.1.2 with g_eq,
  have mem3 : g ∈ z.1.as_homogeneous_ideal := (classical.some_spec j.1.2).1,
  have eq3 : j.1.1 = localization.mk g 1 := (classical.some_spec j.1.2).2.symm,
  have eq4 := (hacd (c j.1 * j.1.1) (prop1 j.1 j.2)).2,
  dsimp only at eq4,
  have eq5 : ∃ (a : A) (zz : ℕ), c j.1 = localization.mk a ⟨f^zz, ⟨zz, rfl⟩⟩,
  { induction (c j.1) using localization.induction_on with data,
    rcases data with ⟨a, ⟨_, ⟨zz, rfl⟩⟩⟩,
    refine ⟨a, zz, rfl⟩, },
  obtain ⟨α, zz, hzz⟩ := eq5,
  have eq6 := calc localization.mk (after_clear_denominator (c j.1 * j.1.1) (prop1 j.1 j.2)) 1
          = c j.1 * j.1.1 * localization.mk (f^N) 1 : eq4
      ... = (localization.mk α ⟨f^zz, ⟨zz, rfl⟩⟩ : localization.away f) * j.1.1 * localization.mk (f^N) 1
          : by erw hzz
      ... = (localization.mk α ⟨f^zz, ⟨zz, rfl⟩⟩ : localization.away f) * localization.mk g 1 * localization.mk (f^N) 1
          : by erw eq3
      ... = localization.mk (α * g * f^N) ⟨f^zz, ⟨zz, rfl⟩⟩
          : begin
            erw [localization.mk_mul, localization.mk_mul, mul_one, mul_one],
          end,
  simp only [localization.mk_eq_mk', is_localization.eq] at eq6,
  obtain ⟨⟨_, ⟨v, rfl⟩⟩, eq6⟩ := eq6,
  erw [←subtype.val_eq_coe, ←subtype.val_eq_coe, mul_one] at eq6,
  dsimp only at eq6,
  have mem4 : α * g * f ^ N * f ^ v ∈ z.1.as_homogeneous_ideal,
  { apply ideal.mul_mem_right,
    apply ideal.mul_mem_right,
    apply ideal.mul_mem_left,
    exact mem3, },
  erw ←eq6 at mem4,
  rcases z.1.is_prime.mem_or_mem mem4 with H1 | H3,
  rcases z.1.is_prime.mem_or_mem H1 with H1 | H2,
  { exact H1 },
  { exfalso,
    have mem3 := z.2,
    have mem4 := z.1.is_prime.mem_of_pow_mem _ H2,
    erw projective_spectrum.mem_basic_open at mem3,
    apply mem3,
    exact mem4, },
  { exfalso,
    have mem3 := z.2,
    have mem4 := z.1.is_prime.mem_of_pow_mem _ H3,
    erw projective_spectrum.mem_basic_open at mem3,
    apply mem3,
    exact mem4, },
end

include hm
lemma mk_proj_pow_not_mem
  (V : opens (projective_spectrum.Top 𝒜))
  (z : Proj .restrict (@opens.open_embedding (projective_spectrum.Top 𝒜)
    (projective_spectrum.basic_open 𝒜 f)))
  (C : A) (j : ℕ) (hj : graded_algebra.proj 𝒜 j C ∉ z.1.as_homogeneous_ideal) :
  (localization.mk ((graded_algebra.proj 𝒜 j) C ^ m) ⟨f ^ j, ⟨j, rfl⟩⟩ : localization.away f) ∉
    ideal.span ((algebra_map A (away f)) '' ↑(projective_spectrum.as_homogeneous_ideal z.val)) :=
begin
  haveI : decidable_eq (away f) := classical.dec_eq _,

  intro rid,
  erw [←ideal.submodule_span_eq, finsupp.span_eq_range_total, set.mem_range] at rid,
  obtain ⟨c, eq1⟩ := rid,
  erw [finsupp.total_apply, finsupp.sum] at eq1,
  obtain ⟨N, hN⟩ := localization.away.clear_denominator (finset.image (λ i, c i * i.1) c.support),
  -- N is the common denom
  choose after_clear_denominator hacd using hN,
  have prop1 : ∀ i, i ∈ c.support → c i * i.1 ∈ (finset.image (λ i, c i * i.1) c.support),
  { intros i hi, rw finset.mem_image, refine ⟨_, hi, rfl⟩, },
  have eq3 := calc (localization.mk ((graded_algebra.proj 𝒜 j) C ^ m) 1 : localization.away f) * localization.mk (f^N) 1
          = localization.mk ((graded_algebra.proj 𝒜 j) C ^ m) ⟨f^j, ⟨_, rfl⟩⟩ * localization.mk (f^j) 1 * localization.mk (f^N) 1
          : begin
            congr,
            rw [localization.mk_mul, localization.mk_eq_mk', is_localization.eq],
            use 1,
            erw [mul_one, mul_one, mul_one, mul_one, ←subtype.val_eq_coe],
          end
      ... = localization.mk (f^j) 1 * localization.mk ((graded_algebra.proj 𝒜 j) C ^ m) ⟨f^j, ⟨_, rfl⟩⟩ * localization.mk (f^N) 1
          : by ring
      ... = localization.mk (f^j) 1 * localization.mk (f^N) 1 * ∑ i in c.support, c i * i.1
          : begin
            erw eq1, ring,
          end
      ... = localization.mk (f^j) 1 * (localization.mk (f^N) 1 * ∑ i in c.support, c i * i.1) : by ring
      ... = localization.mk (f^j) 1 * ∑ i in c.support, (localization.mk (f^N) 1) * (c i * i.1)
          : begin
            congr' 1,
            rw finset.mul_sum,
          end
      ... = localization.mk (f^j) 1 * ∑ i in c.support.attach, (localization.mk (f^N) 1) * (c i.1 * i.1.1)
          : begin
            congr' 1,
            symmetry,
            convert finset.sum_attach,
            refl,
          end
      ... = localization.mk (f^j) 1 * ∑ i in c.support.attach, (localization.mk (after_clear_denominator (c i.1 * i.1.1) (prop1 i.1 i.2)) 1)
          : begin
            congr' 1,
            rw finset.sum_congr rfl (λ j hj, _),
            have eq2' := (hacd (c j.1 * j.1.1) (prop1 j.1 j.2)).2,
            dsimp only at eq2',
            erw eq2',
            rw mul_comm,
          end
      ... = ∑ i in c.support.attach, (localization.mk (f^j) 1) * (localization.mk (after_clear_denominator (c i.1 * i.1.1) (prop1 i.1 i.2)) 1)
          : begin
            rw finset.mul_sum,
          end
      ... = ∑ i in c.support.attach, localization.mk (f^j * (after_clear_denominator (c i.1 * i.1.1) (prop1 i.1 i.2))) 1
          : begin
            rw finset.sum_congr rfl (λ j hj, _),
            erw [localization.mk_mul, one_mul],
          end
      ... = localization.mk (∑ i in c.support.attach, (f^j * (after_clear_denominator (c i.1 * i.1.1) (prop1 i.1 i.2)))) 1
          : begin
            induction c.support.attach using finset.induction_on with y s hy ih,
            rw [finset.sum_empty, finset.sum_empty, localization.mk_zero],
            erw [finset.sum_insert hy, finset.sum_insert hy, ih, localization.add_mk, mul_one, one_mul, one_mul, add_comm],
          end,
  erw [localization.mk_mul, one_mul] at eq3,
  simp only [localization.mk_eq_mk', is_localization.eq] at eq3,
  obtain ⟨⟨_, ⟨l, rfl⟩⟩, eq3⟩ := eq3,
  erw [mul_one, ←subtype.val_eq_coe, mul_one] at eq3,
  dsimp only at eq3,
  suffices : (∑ i in c.support.attach, (f^j * (after_clear_denominator (c i.1 * i.1.1) (prop1 i.1 i.2)))) * f^l ∈ z.1.as_homogeneous_ideal,
  erw ←eq3 at this,
  rcases z.1.is_prime.mem_or_mem this with H1 | H3,
  rcases z.1.is_prime.mem_or_mem H1 with H1 | H2,
  { apply hj,
    rw z.1.is_prime.pow_mem_iff_mem at H1,
    exact H1,
    exact hm, },
  { have mem3 := z.2,
    have mem4 := z.1.is_prime.mem_of_pow_mem _ H2,
    erw projective_spectrum.mem_basic_open at mem3,
    apply mem3,
    exact mem4, },
  { have mem3 := z.2,
    have mem4 := z.1.is_prime.mem_of_pow_mem _ H3,
    erw projective_spectrum.mem_basic_open at mem3,
    apply mem3,
    exact mem4, },
  apply ideal.mul_mem_right,
  apply ideal.sum_mem,
  intros j hj,
  apply ideal.mul_mem_left,
  set g := classical.some j.1.2 with g_eq,
  have mem3 : g ∈ z.1.as_homogeneous_ideal := (classical.some_spec j.1.2).1,
  have eq3 : j.1.1 = localization.mk g 1 := (classical.some_spec j.1.2).2.symm,
  have eq4 := (hacd (c j.1 * j.1.1) (prop1 j.1 j.2)).2,
  dsimp only at eq4,

  have eq5 : ∃ (a : A) (zz : ℕ), c j.1 = localization.mk a ⟨f^zz, ⟨zz, rfl⟩⟩,
  { induction (c j.1) using localization.induction_on with data,
    rcases data with ⟨a, ⟨_, ⟨zz, rfl⟩⟩⟩,
    refine ⟨a, zz, rfl⟩, },
  obtain ⟨α, zz, hzz⟩ := eq5,

  have eq6 := calc localization.mk (after_clear_denominator (c j.1 * j.1.1) (prop1 j.1 j.2)) 1
          = c j.1 * j.1.1 * localization.mk (f^N) 1 : eq4
      ... = (localization.mk α ⟨f^zz, ⟨zz, rfl⟩⟩ : localization.away f) * j.1.1 * localization.mk (f^N) 1
          : by erw hzz
      ... = (localization.mk α ⟨f^zz, ⟨zz, rfl⟩⟩ : localization.away f) * localization.mk g 1 * localization.mk (f^N) 1
          : by erw eq3
      ... = localization.mk (α * g * f^N) ⟨f^zz, ⟨zz, rfl⟩⟩
          : begin
            erw [localization.mk_mul, localization.mk_mul, mul_one, mul_one],
          end,
  simp only [localization.mk_eq_mk', is_localization.eq] at eq6,
  obtain ⟨⟨_, ⟨v, rfl⟩⟩, eq6⟩ := eq6,
  erw [←subtype.val_eq_coe, ←subtype.val_eq_coe, mul_one] at eq6,
  dsimp only at eq6,

  have mem4 : α * g * f ^ N * f ^ v ∈ z.1.as_homogeneous_ideal,
  { apply ideal.mul_mem_right,
    apply ideal.mul_mem_right,
    apply ideal.mul_mem_left,
    exact mem3, },
  erw ←eq6 at mem4,

  rcases z.1.is_prime.mem_or_mem mem4 with H1 | H3,
  rcases z.1.is_prime.mem_or_mem H1 with H1 | H2,
  { exact H1 },
  { exfalso,
    have mem3 := z.2,
    have mem4 := z.1.is_prime.mem_of_pow_mem _ H2,
    erw projective_spectrum.mem_basic_open at mem3,
    apply mem3,
    exact mem4, },
  { exfalso,
    have mem3 := z.2,
    have mem4 := z.1.is_prime.mem_of_pow_mem _ H3,
    erw projective_spectrum.mem_basic_open at mem3,
    apply mem3,
    exact mem4, }
end

omit hm
lemma final_eq
  (d_hh n_hh a b C : A) (degree i_hh j : ℕ) (INEQ : graded_algebra.proj 𝒜 j C ≠ 0)
  (d_hh_mem : d_hh ∈ 𝒜 i_hh) (n_hh_mem : n_hh ∈ 𝒜 i_hh)
  (a_hom : a ∈ 𝒜 degree) (b_hom : b ∈ 𝒜 degree)
  (eq1 : n_hh * b * C = a * d_hh * C) : n_hh * b * graded_algebra.proj 𝒜 j C = a * d_hh * graded_algebra.proj 𝒜 j C :=
begin
  have eq2 := congr_arg (graded_algebra.proj 𝒜 (i_hh + degree + j)) eq1,
  rw [graded_algebra.proj_hom_mul, graded_algebra.proj_hom_mul] at eq2,
  exact eq2,

  rw add_comm,
  apply set_like.graded_monoid.mul_mem,
  exact a_hom,
  exact d_hh_mem,
  exact INEQ,

  apply set_like.graded_monoid.mul_mem,
  exact n_hh_mem,
  exact b_hom,
  exact INEQ,
end

lemma inv_hom_mem_bo (V : opens Proj.T) (z : Proj.T| (pbo f))
  (subset2 : open_set 𝒜 hm f_deg V ⟶ unop U) (z_mem : z.1 ∈ V) :
  (((Proj_iso_Spec_Top_component hm f_deg).inv)
    (subset2 ⟨(homeo_of_iso (Proj_iso_Spec_Top_component hm f_deg)) z, begin
    erw [set.mem_preimage],
    refine ⟨z, z_mem, rfl⟩,
  end⟩).val).val ∈ projective_spectrum.basic_open 𝒜 f :=
begin
  erw projective_spectrum.mem_basic_open,
  intro rid,
  change ∀ _, _ at rid,
  specialize rid m,
  simp only [graded_algebra.proj_apply, direct_sum.decompose_of_mem_same 𝒜 f_deg] at rid,
  change _ ∈ ((homeo_of_iso (Proj_iso_Spec_Top_component hm f_deg)) z).1 at rid,
  have rid2 : (1 : A⁰_ f) ∈ ((homeo_of_iso (Proj_iso_Spec_Top_component hm f_deg)) z).1,
  { convert rid,
    simp only [homogeneous_localization.ext_iff_val, subtype.coe_mk, homogeneous_localization.one_val,
      homogeneous_localization.val_mk'],
    convert (localization.mk_self _).symm,
    refl, },
  rw homeo_of_iso_apply at rid2,
  apply (((Proj_iso_Spec_Top_component hm f_deg).hom) z).is_prime.1,
  rw ideal.eq_top_iff_one,
  exact rid2,
end

lemma inv_hom_mem2
  (V : opens Proj.T)
  (z : Proj.T| (pbo f))
  (subset2 : open_set 𝒜 hm f_deg V ⟶ unop U)
  (z_mem : z.1 ∈ V) :
  (((Proj_iso_Spec_Top_component hm f_deg).inv)
    (subset2 ⟨(homeo_of_iso (Proj_iso_Spec_Top_component hm f_deg)) z, begin
    erw [set.mem_preimage],
    refine ⟨z, z_mem, rfl⟩,
  end⟩).val).val ∈
  ((@opens.open_embedding (projective_spectrum.Top 𝒜) (projective_spectrum.basic_open 𝒜 f)).is_open_map.functor.op.obj
    ((opens.map (Proj_iso_Spec_Top_component hm f_deg).hom).op.obj U)).unop :=
begin
  simp only [unop_op, functor.op_obj],
  set z' := (((Proj_iso_Spec_Top_component hm f_deg).inv)
    (subset2 ⟨(homeo_of_iso (Proj_iso_Spec_Top_component hm f_deg)) z, begin
    erw [set.mem_preimage],
    refine ⟨z, z_mem, rfl⟩,
  end⟩).val).val with z'_eq,
  refine ⟨⟨z', _⟩, _, rfl⟩,
  have mem_z' : z' ∈ projective_spectrum.basic_open 𝒜 f,
  erw projective_spectrum.mem_basic_open,
  intro rid,
  erw z'_eq at rid,
  change ∀ _, _ at rid,
  specialize rid m,
  simp only [graded_algebra.proj_apply, direct_sum.decompose_of_mem_same 𝒜 f_deg] at rid,
  change _ ∈ ((homeo_of_iso (Proj_iso_Spec_Top_component hm f_deg)) z).1 at rid,
  have rid2 : (1 : A⁰_ f) ∈ ((homeo_of_iso (Proj_iso_Spec_Top_component hm f_deg)) z).1,
  { convert rid,
    simp only [homogeneous_localization.ext_iff_val, homogeneous_localization.one_val,
      homogeneous_localization.val_mk', subtype.coe_mk],
    convert (localization.mk_self _).symm,
    refl, },
  rw homeo_of_iso_apply at rid2,
  apply (((Proj_iso_Spec_Top_component hm f_deg).hom) z).is_prime.1,
  rw ideal.eq_top_iff_one,
  exact rid2,
  exact mem_z',
  erw [set.mem_preimage],
  have subset3 := le_of_hom subset2,
  suffices : ((Proj_iso_Spec_Top_component hm f_deg).hom) ⟨z', _⟩ ∈ open_set 𝒜 hm f_deg V,
  apply subset3,
  exact this,

  refine ⟨z, z_mem, _⟩,
  simp only [homeo_of_iso_apply],
  congr',
  rw subtype.ext_iff,
  dsimp only [subtype.coe_mk],
  rw z'_eq,
  change z.1 = (Proj_iso_Spec_Top_component.from_Spec hm f_deg (Proj_iso_Spec_Top_component.to_Spec _ _ _)).1,
  congr',
  symmetry,
  apply Proj_iso_Spec_Top_component.from_Spec_to_Spec 𝒜 hm f_deg z,
end

end is_locally_quotient

variables (hm f_deg)
lemma fmk_is_locally_quotient (y : unop U) :
  ∃ (V : opens (Spec.T (A⁰_ f))) (mem : y.val ∈ V) (i : V ⟶ unop U) (r s : (A⁰_ f)),
    ∀ (z : V),
      ∃ (s_not_mem : s ∉ prime_spectrum.as_ideal z.val),
        fmk hm f_deg hh ⟨(i z).1, (i z).2⟩ = mk r ⟨s, s_not_mem⟩ :=
begin
  classical,

  obtain ⟨V, mem1, subset1, degree, ⟨a, a_mem⟩, ⟨b, b_mem⟩, eq1⟩ := hh.2 ⟨((Proj_iso_Spec_Top_component hm f_deg).inv y.1).1, inv_mem y⟩,
  set VVo : opens (Spec.T (A⁰_ f)) := is_locally_quotient.open_set 𝒜 hm f_deg V with VVo_eq,
  have subset2 : VVo ⟶ unop U := is_locally_quotient.open_set_is_subset 𝒜 hm f_deg V y subset1,
  have y_mem1 : y.1 ∈ VVo,
  { convert is_locally_quotient.mem_open_subset_of_inv_mem 𝒜 hm f_deg V y mem1 },
  refine ⟨VVo, y_mem1, subset2,
    quotient.mk' ⟨m * degree, ⟨a * b^m.pred,
      begin
        have mem1 : b^m.pred ∈ 𝒜 (m.pred * degree) := set_like.pow_mem_graded _ b_mem,
        have mem2 := set_like.graded_monoid.mul_mem a_mem mem1,
        convert mem2,
        exact calc m * degree
                = (m.pred + 1) * degree
                : begin
                  congr' 1,
                  symmetry,
                  apply nat.succ_pred_eq_of_pos hm,
                end
            ... = m.pred * degree + 1 * degree : by rw add_mul
            ... = m.pred * degree + degree : by rw one_mul
            ... = degree + m.pred * degree : by rw add_comm,
      end⟩, ⟨f^degree, by rw [mul_comm]; exact set_like.pow_mem_graded _ f_deg⟩, ⟨_, rfl⟩⟩,
    quotient.mk' ⟨m * degree, ⟨b^m, set_like.pow_mem_graded _ b_mem⟩,
      ⟨f^degree, by rw [mul_comm]; exact set_like.pow_mem_graded _ f_deg⟩, ⟨_, rfl⟩⟩, _⟩,

  rintros ⟨z, z_mem⟩,
  obtain ⟨z, z_mem, rfl⟩ := z_mem,
  specialize eq1 ⟨z.1, z_mem⟩,
  obtain ⟨b_not_mem, eq1⟩ := eq1,

  refine ⟨is_locally_quotient.not_mem 𝒜 hm f_deg V b degree b_mem z z_mem b_not_mem, _⟩,

  have eq2 := (hh.val (subset1 ⟨z.val, z_mem⟩)).eq_num_div_denom,
  dsimp only at eq1,
  rw [homogeneous_localization.ext_iff_val] at eq1,
  rw [eq2, homogeneous_localization.val_mk'] at eq1,
  simp only [← subtype.val_eq_coe] at eq1,
  rw [localization.mk_eq_mk', is_localization.eq] at eq1,
  obtain ⟨⟨C, hC⟩, eq1⟩ := eq1,
  unfold fmk,
  rw [localization.mk_eq_mk', is_localization.eq],
  simp only [←subtype.val_eq_coe] at eq1,
  set degree_hh := (hh.val (subset1 ⟨z.val, z_mem⟩)).deg with degree_hh_eq,
  have mem_C : ∃ (j : ℕ), graded_algebra.proj 𝒜 j C ∉ z.1.as_homogeneous_ideal,
  { by_contra rid,
    rw not_exists at rid,
    apply hC,
    rw ←direct_sum.sum_support_decompose 𝒜 C,
    apply ideal.sum_mem,
    intros j hj,
    specialize rid j,
    rw not_not at rid,
    apply rid, },
  obtain ⟨j, hj⟩ := mem_C,
  refine ⟨⟨quotient.mk' ⟨m * j, ⟨(graded_algebra.proj 𝒜 j C)^m,
    set_like.pow_mem_graded _ (submodule.coe_mem _)⟩, ⟨f^j,
    by rw [mul_comm]; exact set_like.pow_mem_graded _ f_deg⟩, ⟨_, rfl⟩⟩, _⟩, _⟩,

  { change _ ∉ _,
    simp only [← subtype.val_eq_coe],
    erw Proj_iso_Spec_Top_component.to_Spec.mem_carrier_iff,
    apply is_locally_quotient.mk_proj_pow_not_mem hm V z C j hj, },

  set z' := (((Proj_iso_Spec_Top_component hm f_deg).inv)
    (subset2 ⟨(homeo_of_iso (Proj_iso_Spec_Top_component hm f_deg)) z, begin
    erw [set.mem_preimage],
    refine ⟨z, z_mem, rfl⟩,
  end⟩).val).val with z'_eq,

  have z'_mem : z' ∈ (((@opens.open_embedding Proj.T) (pbo f)).is_open_map.functor.op.obj
        ((opens.map (Proj_iso_Spec_Top_component hm f_deg).hom).op.obj U)).unop,
  { convert is_locally_quotient.inv_hom_mem2 𝒜 hm f_deg V z subset2 z_mem },

  have eq_pt : (subset1 ⟨z.1, z_mem⟩) = ⟨z', z'_mem⟩,
  { rw subtype.ext_iff,
    change z.1 = (Proj_iso_Spec_Top_component.from_Spec hm f_deg (Proj_iso_Spec_Top_component.to_Spec 𝒜 f _)).1,
    congr',
    symmetry,
    apply Proj_iso_Spec_Top_component.from_Spec_to_Spec 𝒜 hm f_deg z, },
  erw [eq_pt] at eq1,

  unfold num denom,
  simp only [subtype.coe_mk, homogeneous_localization.ext_iff_val,
    homogeneous_localization.mul_val, homogeneous_localization.val_mk',
    localization.mk_mul, submonoid.coe_mul],
  rw [localization.mk_eq_mk', is_localization.eq],
  use 1,
  simp only [submonoid.coe_mul, submonoid.coe_one],
  simp only [←subtype.val_eq_coe, one_mul, mul_one, ←pow_add],

  set d_hh := (hh.val ⟨z', z'_mem⟩).denom with d_hh_eq,
  set n_hh := (hh.val ⟨z', z'_mem⟩).num with n_hh_eq,
  set i_hh := (hh.val ⟨z', z'_mem⟩).deg with i_hh_eq,
  simp only [←d_hh_eq, ←n_hh_eq, ←i_hh_eq] at eq1,

  suffices : n_hh * d_hh ^ m.pred * b ^ m * (graded_algebra.proj 𝒜 j) C ^ m * f ^ (degree + i_hh + j)
    = a * b ^ m.pred * d_hh ^ m * (graded_algebra.proj 𝒜 j) C ^ m * f ^ (i_hh + degree + j),
  convert this,

  suffices EQ : n_hh * b * graded_algebra.proj 𝒜 j C = a * d_hh * graded_algebra.proj 𝒜 j C,
  erw calc n_hh * d_hh ^ m.pred * b ^ m * (graded_algebra.proj 𝒜 j) C ^ m * f ^ (degree + i_hh + j)
        = n_hh * d_hh ^ m.pred * b ^ (m.pred + 1) * (graded_algebra.proj 𝒜 j) C^(m.pred + 1) * f^(degree + i_hh + j)
        : begin
          congr';
          symmetry;
          apply nat.succ_pred_eq_of_pos hm,
        end
    ... = n_hh * d_hh ^ m.pred * (b ^ m.pred * b) * ((graded_algebra.proj 𝒜 j C) ^ m.pred * (graded_algebra.proj 𝒜 j C)) * f^(degree + i_hh + j)
        : begin
          congr',
          all_goals { rw [pow_add, pow_one], },
        end
    ... = (n_hh * b * graded_algebra.proj 𝒜 j C) * (d_hh ^ m.pred * b ^ m.pred * (graded_algebra.proj 𝒜 j C)^m.pred) * f^(degree + i_hh + j)  : by ring
    ... = (a * d_hh * graded_algebra.proj 𝒜 j C) * (d_hh ^ m.pred * b ^ m.pred * (graded_algebra.proj 𝒜 j C)^m.pred) * f^(degree + i_hh + j)  : by rw EQ
    ... = a * b ^ m.pred * (d_hh ^ m.pred * d_hh) * ((graded_algebra.proj 𝒜 j C)^m.pred * graded_algebra.proj 𝒜 j C) * f^(degree + i_hh + j)  : by ring
    ... = a * b ^ m.pred * (d_hh ^ m.pred * d_hh^1) * ((graded_algebra.proj 𝒜 j C)^m.pred * graded_algebra.proj 𝒜 j C ^ 1) * f^(degree + i_hh + j)
        : by rw [pow_one, pow_one]
    ... =  a * b ^ m.pred * (d_hh ^ (m.pred + 1)) * ((graded_algebra.proj 𝒜 j C)^(m.pred + 1)) * f^(degree + i_hh + j)
        : by simp only [pow_add]
    ... = a * b ^ m.pred * d_hh ^ m * (graded_algebra.proj 𝒜 j C)^m * f^(degree + i_hh + j)
        : begin
          congr',
          all_goals { apply nat.succ_pred_eq_of_pos hm, },
        end
    ... = a * b ^ m.pred * d_hh ^ m * (graded_algebra.proj 𝒜 j C)^m * f^(i_hh + degree + j)
        : begin
          congr' 1,
          rw add_comm i_hh degree,
        end,
  have INEQ : graded_algebra.proj 𝒜 j C ≠ 0,
  { intro rid,
    apply hj,
    rw rid,
    exact submodule.zero_mem _, },

  have eq2 := congr_arg (graded_algebra.proj 𝒜 (i_hh + degree + j)) eq1,
  rw [graded_algebra.proj_hom_mul, graded_algebra.proj_hom_mul] at eq2,
  exact eq2,

  rw add_comm,
  apply set_like.graded_monoid.mul_mem,
  exact a_mem,
  exact (hh.val ⟨z', z'_mem⟩).denom_mem_deg,
  exact INEQ,

  apply set_like.graded_monoid.mul_mem,
  exact (hh.val ⟨z', z'_mem⟩).num_mem_deg,
  exact b_mem,
  exact INEQ,
end

variable (U)
def to_fun : (pf_sheaf (Proj| (pbo f))).obj U ⟶ (Spec (A⁰_ f_deg)).presheaf.obj U :=
{ to_fun := λ hh, ⟨λ y, fmk hm hh y, begin
    rw algebraic_geometry.structure_sheaf.is_locally_fraction_pred',
    exact fmk_is_locally_quotient hm f_deg hh,
  end⟩,
  map_one' := begin
    rw subtype.ext_iff,
    dsimp only [subtype.coe_mk],
    ext y,
    rw [fmk.one hm],
    convert pi.one_apply _,
  end,
  map_mul' := λ x y, begin
    rw subtype.ext_iff,
    dsimp only [subtype.coe_mk],
    ext z,
    rw [fmk.mul hm],
    change _ * _ = _ * _,
    dsimp only,
    refl,
  end,
  map_zero' := begin
    rw subtype.ext_iff,
    dsimp only [subtype.coe_mk],
    ext y,
    rw [fmk.zero hm],
    convert pi.zero_apply _,
  end,
  map_add' := λ x y, begin
    rw subtype.ext_iff,
    dsimp only [subtype.coe_mk],
    ext z,
    rw [fmk.add hm],
    change _ + _ = fmk hm x z + fmk hm y z,
    dsimp only,
    refl
  end }

end to_Spec

section

def to_Spec {f : A} {m : ℕ} (hm : 0 < m) (f_deg : f ∈ 𝒜 m):
  ((Proj_iso_Spec_Top_component hm f_deg).hom _* (Proj| (pbo f)).presheaf) ⟶ (Spec (A⁰_ f_deg)).presheaf :=
{ app := λ U, to_Spec.to_fun hm f_deg U,
  naturality' := λ U V subset1, begin
    ext1 z,
    simp only [comp_apply, ring_hom.coe_mk, functor.op_map, presheaf.pushforward_obj_map],
    refl,
  end }

end

end Proj_iso_Spec_Sheaf_component

end algebraic_geometry
