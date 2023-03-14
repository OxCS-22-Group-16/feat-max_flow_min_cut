/-
Copyright (c) 2018 Kevin Buzzard, Patrick Massot. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Kevin Buzzard, Patrick Massot

This file is to a certain extent based on `quotient_module.lean` by Johannes Hölzl.
-/
import group_theory.congruence
import group_theory.coset
import group_theory.subgroup.finite
import group_theory.subgroup.pointwise

/-!
# Quotients of groups by normal subgroups

> THIS FILE IS SYNCHRONIZED WITH MATHLIB4.
> Any changes to this file require a corresponding PR to mathlib4.

This files develops the basic theory of quotients of groups by normal subgroups. In particular it
proves Noether's first and second isomorphism theorems.

## Main definitions

* `mk'`: the canonical group homomorphism `G →* G/N` given a normal subgroup `N` of `G`.
* `lift φ`: the group homomorphism `G/N →* H` given a group homomorphism `φ : G →* H` such that
  `N ⊆ ker φ`.
* `map f`: the group homomorphism `G/N →* H/M` given a group homomorphism `f : G →* H` such that
  `N ⊆ f⁻¹(M)`.

## Main statements

* `quotient_ker_equiv_range`: Noether's first isomorphism theorem, an explicit isomorphism
  `G/ker φ → range φ` for every group homomorphism `φ : G →* H`.
* `quotient_inf_equiv_prod_normal_quotient`: Noether's second isomorphism theorem, an explicit
  isomorphism between `H/(H ∩ N)` and `(HN)/N` given a subgroup `H` and a normal subgroup `N` of a
  group `G`.
* `quotient_group.quotient_quotient_equiv_quotient`: Noether's third isomorphism theorem,
  the canonical isomorphism between `(G / N) / (M / N)` and `G / M`, where `N ≤ M`.

## Tags

isomorphism theorems, quotient groups
-/

open function
universes u v

namespace quotient_group

variables {G : Type u} [group G] (N : subgroup G) [nN : N.normal] {H : Type v} [group H]
include nN

/-- The congruence relation generated by a normal subgroup. -/
@[to_additive "The additive congruence relation generated by a normal additive subgroup."]
protected def con : con G :=
{ to_setoid := left_rel N,
  mul' := λ a b c d hab hcd, begin
    rw [left_rel_eq] at hab hcd ⊢,
    calc (a * c)⁻¹ * (b * d) = c⁻¹ * (a⁻¹ * b) * c⁻¹⁻¹ * (c⁻¹ * d) :
      by simp only [mul_inv_rev, mul_assoc, inv_mul_cancel_left]
    ... ∈ N : N.mul_mem (nN.conj_mem _ hab _) hcd
  end }

@[to_additive] instance quotient.group : group (G ⧸ N) := (quotient_group.con N).group

/-- The group homomorphism from `G` to `G/N`. -/
@[to_additive "The additive group homomorphism from `G` to `G/N`."]
def mk' : G →* G ⧸ N := monoid_hom.mk' (quotient_group.mk) (λ _ _, rfl)

@[simp, to_additive]
lemma coe_mk' : (mk' N : G → G ⧸ N) = coe := rfl

@[simp, to_additive]
lemma mk'_apply (x : G) : mk' N x = x := rfl

@[to_additive]
lemma mk'_surjective : surjective $ mk' N := @mk_surjective _ _ N

@[to_additive]
lemma mk'_eq_mk' {x y : G} : mk' N x = mk' N y ↔ ∃ z ∈ N, x * z = y :=
quotient_group.eq'.trans $
  by simp only [← _root_.eq_inv_mul_iff_mul_eq, exists_prop, exists_eq_right]

/-- Two `monoid_hom`s from a quotient group are equal if their compositions with
`quotient_group.mk'` are equal.

See note [partially-applied ext lemmas]. -/
@[ext, to_additive /-" Two `add_monoid_hom`s from an additive quotient group are equal if their
compositions with `add_quotient_group.mk'` are equal.

See note [partially-applied ext lemmas]. "-/]
lemma monoid_hom_ext ⦃f g : G ⧸ N →* H⦄ (h : f.comp (mk' N) = g.comp (mk' N)) : f = g :=
monoid_hom.ext $ λ x, quotient_group.induction_on x $ (monoid_hom.congr_fun h : _)

@[simp, to_additive]
lemma eq_one_iff {N : subgroup G} [nN : N.normal] (x : G) : (x : G ⧸ N) = 1 ↔ x ∈ N :=
begin
  refine quotient_group.eq.trans _,
  rw [mul_one, subgroup.inv_mem_iff],
end

@[simp, to_additive]
lemma ker_mk : monoid_hom.ker (quotient_group.mk' N : G →* G ⧸ N) = N :=
subgroup.ext eq_one_iff

@[to_additive]
lemma eq_iff_div_mem {N : subgroup G} [nN : N.normal] {x y : G} :
  (x : G ⧸ N) = y ↔ x / y ∈ N :=
begin
  refine eq_comm.trans (quotient_group.eq.trans _),
  rw [nN.mem_comm_iff, div_eq_mul_inv]
end

-- for commutative groups we don't need normality assumption
omit nN

@[to_additive]
instance quotient.comm_group {G : Type*} [comm_group G] (N : subgroup G) : comm_group (G ⧸ N) :=
{ mul_comm := λ a b, quotient.induction_on₂' a b
    (λ a b, congr_arg mk (mul_comm a b)),
  .. @quotient_group.quotient.group _ _ N N.normal_of_comm }

include nN

local notation ` Q ` := G ⧸ N

@[simp, to_additive] lemma coe_one : ((1 : G) : Q) = 1 := rfl
@[simp, to_additive] lemma coe_mul (a b : G) : ((a * b : G) : Q) = a * b := rfl
@[simp, to_additive] lemma coe_inv (a : G) : ((a⁻¹ : G) : Q) = a⁻¹ := rfl
@[simp, to_additive] lemma coe_div (a b : G) : ((a / b : G) : Q) = a / b := rfl
@[simp, to_additive] lemma coe_pow (a : G) (n : ℕ) : ((a ^ n : G) : Q) = a ^ n := rfl
@[simp, to_additive] lemma coe_zpow (a : G) (n : ℤ) : ((a ^ n : G) : Q) = a ^ n := rfl

/-- A group homomorphism `φ : G →* H` with `N ⊆ ker(φ)` descends (i.e. `lift`s) to a
group homomorphism `G/N →* H`. -/
@[to_additive "An `add_group` homomorphism `φ : G →+ H` with `N ⊆ ker(φ)` descends (i.e. `lift`s)
to a group homomorphism `G/N →* H`."]
def lift (φ : G →* H) (HN : ∀x∈N, φ x = 1) : Q →* H :=
(quotient_group.con N).lift φ $ λ x y h, begin
  simp only [quotient_group.con, left_rel_apply, con.rel_mk] at h,
  calc φ x = φ (y * (x⁻¹ * y)⁻¹) : by rw [mul_inv_rev, inv_inv, mul_inv_cancel_left]
       ... = φ y                 : by rw [φ.map_mul, HN _ (N.inv_mem h), mul_one]
  end

@[simp, to_additive]
lemma lift_mk {φ : G →* H} (HN : ∀x∈N, φ x = 1) (g : G) : lift N φ HN (g : Q) = φ g := rfl

@[simp, to_additive]
lemma lift_mk' {φ : G →* H} (HN : ∀x∈N, φ x = 1) (g : G) : lift N φ HN (mk g : Q) = φ g := rfl

@[simp, to_additive]
lemma lift_quot_mk {φ : G →* H} (HN : ∀x∈N, φ x = 1) (g : G) :
  lift N φ HN (quot.mk _ g : Q) = φ g := rfl

/-- A group homomorphism `f : G →* H` induces a map `G/N →* H/M` if `N ⊆ f⁻¹(M)`. -/
@[to_additive "An `add_group` homomorphism `f : G →+ H` induces a map `G/N →+ H/M` if
`N ⊆ f⁻¹(M)`."]
def map (M : subgroup H) [M.normal] (f : G →* H) (h : N ≤ M.comap f) :
  G ⧸ N →* H ⧸ M :=
begin
  refine quotient_group.lift N ((mk' M).comp f) _,
  assume x hx,
  refine quotient_group.eq.2 _,
  rw [mul_one, subgroup.inv_mem_iff],
  exact h hx,
end

@[simp, to_additive] lemma map_coe (M : subgroup H) [M.normal] (f : G →* H) (h : N ≤ M.comap f)
  (x : G) :
  map N M f h ↑x = ↑(f x) :=
rfl

@[to_additive] lemma map_mk' (M : subgroup H) [M.normal] (f : G →* H) (h : N ≤ M.comap f) (x : G) :
  map N M f h (mk' _ x) = ↑(f x) :=
rfl

@[to_additive]
lemma map_id_apply (h : N ≤ subgroup.comap (monoid_hom.id _) N := (subgroup.comap_id N).le) (x) :
  map N N (monoid_hom.id _) h x = x :=
induction_on' x $ λ x, rfl

@[simp, to_additive]
lemma map_id (h : N ≤ subgroup.comap (monoid_hom.id _) N := (subgroup.comap_id N).le) :
  map N N (monoid_hom.id _) h = monoid_hom.id _ :=
monoid_hom.ext (map_id_apply N h)

@[simp, to_additive]
lemma map_map {I : Type*} [group I] (M : subgroup H) (O : subgroup I)
  [M.normal] [O.normal]
  (f : G →* H) (g : H →* I) (hf : N ≤ subgroup.comap f M) (hg : M ≤ subgroup.comap g O)
  (hgf : N ≤ subgroup.comap (g.comp f) O :=
    hf.trans ((subgroup.comap_mono hg).trans_eq (subgroup.comap_comap _ _ _))) (x : G ⧸ N) :
  map M O g hg (map N M f hf x) = map N O (g.comp f) hgf x :=
begin
  refine induction_on' x (λ x, _),
  simp only [map_coe, monoid_hom.comp_apply]
end

@[simp, to_additive]
lemma map_comp_map {I : Type*} [group I] (M : subgroup H) (O : subgroup I)
  [M.normal] [O.normal]
  (f : G →* H) (g : H →* I) (hf : N ≤ subgroup.comap f M) (hg : M ≤ subgroup.comap g O)
  (hgf : N ≤ subgroup.comap (g.comp f) O :=
    hf.trans ((subgroup.comap_mono hg).trans_eq (subgroup.comap_comap _ _ _))) :
  (map M O g hg).comp (map N M f hf) = map N O (g.comp f) hgf :=
monoid_hom.ext (map_map N M O f g hf hg hgf)

omit nN

section congr

variables (G' : subgroup G) (H' : subgroup H) [subgroup.normal G'] [subgroup.normal H']

/-- `quotient_group.congr` lifts the isomorphism `e : G ≃ H` to `G ⧸ G' ≃ H ⧸ H'`,
given that `e` maps `G` to `H`. -/
@[to_additive "`quotient_add_group.congr` lifts the isomorphism `e : G ≃ H` to `G ⧸ G' ≃ H ⧸ H'`,
given that `e` maps `G` to `H`."]
def congr (e : G ≃* H) (he : G'.map ↑e = H') : G ⧸ G' ≃* H ⧸ H' :=
{ to_fun := map G' H' ↑e (he ▸ G'.le_comap_map e),
  inv_fun := map H' G' ↑e.symm (he ▸ (G'.map_equiv_eq_comap_symm e).le),
  left_inv := λ x, by rw map_map; -- `simp` doesn't like this lemma...
    simp only [map_map, ← mul_equiv.coe_monoid_hom_trans, mul_equiv.self_trans_symm,
        mul_equiv.coe_monoid_hom_refl, map_id_apply],
  right_inv := λ x, by rw map_map; -- `simp` doesn't like this lemma...
    simp only [← mul_equiv.coe_monoid_hom_trans, mul_equiv.symm_trans_self,
        mul_equiv.coe_monoid_hom_refl, map_id_apply],
  .. map G' H' ↑e (he ▸ G'.le_comap_map e) }

@[simp] lemma congr_mk (e : G ≃* H) (he : G'.map ↑e = H')
  (x) : congr G' H' e he (mk x) = e x :=
rfl

lemma congr_mk' (e : G ≃* H) (he : G'.map ↑e = H')
  (x) : congr G' H' e he (mk' G' x) = mk' H' (e x) :=
rfl

@[simp] lemma congr_apply (e : G ≃* H) (he : G'.map ↑e = H')
  (x : G) : congr G' H' e he x = mk' H' (e x) :=
rfl

@[simp] lemma congr_refl (he : G'.map (mul_equiv.refl G : G →* G) = G' := subgroup.map_id G') :
  congr G' G' (mul_equiv.refl G) he = mul_equiv.refl (G ⧸ G') :=
by { ext ⟨x⟩, refl }

@[simp] lemma congr_symm (e : G ≃* H) (he : G'.map ↑e = H') :
  (congr G' H' e he).symm = congr H' G' e.symm ((subgroup.map_symm_eq_iff_map_eq _).mpr he) :=
rfl

end congr

variables (φ : G →* H)

open monoid_hom

/-- The induced map from the quotient by the kernel to the codomain. -/
@[to_additive "The induced map from the quotient by the kernel to the codomain."]
def ker_lift : G ⧸ ker φ →* H :=
lift _ φ $ λ g, φ.mem_ker.mp

@[simp, to_additive]
lemma ker_lift_mk (g : G) : (ker_lift φ) g = φ g := lift_mk _ _ _

@[simp, to_additive]
lemma ker_lift_mk' (g : G) : (ker_lift φ) (mk g) = φ g := lift_mk' _ _ _

@[to_additive]
lemma ker_lift_injective : injective (ker_lift φ) :=
assume a b, quotient.induction_on₂' a b $
  assume a b (h : φ a = φ b), quotient.sound' $
  by rw [left_rel_apply, mem_ker, φ.map_mul, ← h, φ.map_inv, inv_mul_self]

-- Note that `ker φ` isn't definitionally `ker (φ.range_restrict)`
-- so there is a bit of annoying code duplication here

/-- The induced map from the quotient by the kernel to the range. -/
@[to_additive "The induced map from the quotient by the kernel to the range."]
def range_ker_lift : G ⧸ ker φ →* φ.range :=
lift _ φ.range_restrict $ λ g hg, (mem_ker _).mp $ by rwa ker_range_restrict

@[to_additive]
lemma range_ker_lift_injective : injective (range_ker_lift φ) :=
assume a b, quotient.induction_on₂' a b $
  assume a b (h : φ.range_restrict a = φ.range_restrict b), quotient.sound' $
  by rw [left_rel_apply, ←ker_range_restrict, mem_ker,
  φ.range_restrict.map_mul, ← h, φ.range_restrict.map_inv, inv_mul_self]

@[to_additive]
lemma range_ker_lift_surjective : surjective (range_ker_lift φ) :=
begin
  rintro ⟨_, g, rfl⟩,
  use mk g,
  refl,
end

/-- **Noether's first isomorphism theorem** (a definition): the canonical isomorphism between
`G/(ker φ)` to `range φ`. -/
@[to_additive "The first isomorphism theorem (a definition): the canonical isomorphism between
`G/(ker φ)` to `range φ`."]
noncomputable def quotient_ker_equiv_range : G ⧸ ker φ ≃* range φ :=
mul_equiv.of_bijective (range_ker_lift φ) ⟨range_ker_lift_injective φ, range_ker_lift_surjective φ⟩

/-- The canonical isomorphism `G/(ker φ) ≃* H` induced by a homomorphism `φ : G →* H`
with a right inverse `ψ : H → G`. -/
@[to_additive "The canonical isomorphism `G/(ker φ) ≃+ H` induced by a homomorphism `φ : G →+ H`
with a right inverse `ψ : H → G`.", simps]
def quotient_ker_equiv_of_right_inverse (ψ : H → G) (hφ : right_inverse ψ φ) :
  G ⧸ ker φ ≃* H :=
{ to_fun := ker_lift φ,
  inv_fun := mk ∘ ψ,
  left_inv := λ x, ker_lift_injective φ (by rw [comp_app, ker_lift_mk', hφ]),
  right_inv := hφ,
  .. ker_lift φ }

/-- The canonical isomorphism `G/⊥ ≃* G`. -/
@[to_additive "The canonical isomorphism `G/⊥ ≃+ G`.", simps]
def quotient_bot : G ⧸ (⊥ : subgroup G) ≃* G :=
quotient_ker_equiv_of_right_inverse (monoid_hom.id G) id (λ x, rfl)

/-- The canonical isomorphism `G/(ker φ) ≃* H` induced by a surjection `φ : G →* H`.

For a `computable` version, see `quotient_group.quotient_ker_equiv_of_right_inverse`.
-/
@[to_additive "The canonical isomorphism `G/(ker φ) ≃+ H` induced by a surjection `φ : G →+ H`.

For a `computable` version, see `quotient_add_group.quotient_ker_equiv_of_right_inverse`."]
noncomputable def quotient_ker_equiv_of_surjective (hφ : surjective φ) :
  G ⧸ (ker φ) ≃* H :=
quotient_ker_equiv_of_right_inverse φ _ hφ.has_right_inverse.some_spec

/-- If two normal subgroups `M` and `N` of `G` are the same, their quotient groups are
isomorphic. -/
@[to_additive "If two normal subgroups `M` and `N` of `G` are the same, their quotient groups are
isomorphic."]
def quotient_mul_equiv_of_eq {M N : subgroup G} [M.normal] [N.normal] (h : M = N) :
  G ⧸ M ≃* G ⧸ N :=
{ map_mul' := λ q r, quotient.induction_on₂' q r (λ g h, rfl),
  .. subgroup.quotient_equiv_of_eq h }

@[simp, to_additive]
lemma quotient_mul_equiv_of_eq_mk {M N : subgroup G} [M.normal] [N.normal] (h : M = N) (x : G) :
  quotient_group.quotient_mul_equiv_of_eq h (quotient_group.mk x) = (quotient_group.mk x) :=
rfl

/-- Let `A', A, B', B` be subgroups of `G`. If `A' ≤ B'` and `A ≤ B`,
then there is a map `A / (A' ⊓ A) →* B / (B' ⊓ B)` induced by the inclusions. -/
@[to_additive "Let `A', A, B', B` be subgroups of `G`. If `A' ≤ B'` and `A ≤ B`,
then there is a map `A / (A' ⊓ A) →+ B / (B' ⊓ B)` induced by the inclusions."]
def quotient_map_subgroup_of_of_le {A' A B' B : subgroup G}
  [hAN : (A'.subgroup_of A).normal] [hBN : (B'.subgroup_of B).normal]
  (h' : A' ≤ B') (h : A ≤ B) :
  A ⧸ (A'.subgroup_of A) →* B ⧸ (B'.subgroup_of B) :=
map _ _ (subgroup.inclusion h) $ subgroup.comap_mono h'

@[simp, to_additive]
lemma quotient_map_subgroup_of_of_le_coe {A' A B' B : subgroup G}
  [hAN : (A'.subgroup_of A).normal] [hBN : (B'.subgroup_of B).normal]
  (h' : A' ≤ B') (h : A ≤ B) (x : A) :
  quotient_map_subgroup_of_of_le h' h x = ↑(subgroup.inclusion h x : B) := rfl

/-- Let `A', A, B', B` be subgroups of `G`.
If `A' = B'` and `A = B`, then the quotients `A / (A' ⊓ A)` and `B / (B' ⊓ B)` are isomorphic.

Applying this equiv is nicer than rewriting along the equalities, since the type of
`(A'.subgroup_of A : subgroup A)` depends on on `A`.
-/
@[to_additive "Let `A', A, B', B` be subgroups of `G`.
If `A' = B'` and `A = B`, then the quotients `A / (A' ⊓ A)` and `B / (B' ⊓ B)` are isomorphic.

Applying this equiv is nicer than rewriting along the equalities, since the type of
`(A'.add_subgroup_of A : add_subgroup A)` depends on on `A`.
"]
def equiv_quotient_subgroup_of_of_eq {A' A B' B : subgroup G}
  [hAN : (A'.subgroup_of A).normal] [hBN : (B'.subgroup_of B).normal]
  (h' : A' = B') (h : A = B) :
  A ⧸ (A'.subgroup_of A) ≃* B ⧸ (B'.subgroup_of B) :=
monoid_hom.to_mul_equiv
  (quotient_map_subgroup_of_of_le h'.le h.le) (quotient_map_subgroup_of_of_le h'.ge h.ge)
  (by { ext ⟨x, hx⟩, refl })
  (by { ext ⟨x, hx⟩, refl })

section zpow

variables {A B C : Type u} [comm_group A] [comm_group B] [comm_group C]
variables (f : A →* B) (g : B →* A) (e : A ≃* B) (d : B ≃* C) (n : ℤ)

/-- The map of quotients by powers of an integer induced by a group homomorphism. -/
@[to_additive "The map of quotients by multiples of an integer induced by an additive group
homomorphism."]
def hom_quotient_zpow_of_hom :
  A ⧸ (zpow_group_hom n : A →* A).range →* B ⧸ (zpow_group_hom n : B →* B).range :=
lift _ ((mk' _).comp f) $
  λ g ⟨h, (hg : h ^ n = g)⟩, (eq_one_iff _).mpr ⟨_, by simpa only [← hg, map_zpow]⟩

@[simp, to_additive]
lemma hom_quotient_zpow_of_hom_id :
  hom_quotient_zpow_of_hom (monoid_hom.id A) n = monoid_hom.id _ :=
monoid_hom_ext _ rfl

@[simp, to_additive]
lemma hom_quotient_zpow_of_hom_comp :
  hom_quotient_zpow_of_hom (f.comp g) n
    = (hom_quotient_zpow_of_hom f n).comp (hom_quotient_zpow_of_hom g n) :=
monoid_hom_ext _ rfl

@[simp, to_additive]
lemma hom_quotient_zpow_of_hom_comp_of_right_inverse (i : function.right_inverse g f) :
  (hom_quotient_zpow_of_hom f n).comp (hom_quotient_zpow_of_hom g n) = monoid_hom.id _ :=
monoid_hom_ext _ $ monoid_hom.ext $ λ x, congr_arg coe $ i x

/-- The equivalence of quotients by powers of an integer induced by a group isomorphism. -/
@[to_additive "The equivalence of quotients by multiples of an integer induced by an additive group
isomorphism."]
def equiv_quotient_zpow_of_equiv :
  A ⧸ (zpow_group_hom n : A →* A).range ≃* B ⧸ (zpow_group_hom n : B →* B).range :=
monoid_hom.to_mul_equiv _ _ (hom_quotient_zpow_of_hom_comp_of_right_inverse e.symm e n e.left_inv)
  (hom_quotient_zpow_of_hom_comp_of_right_inverse e e.symm n e.right_inv)

@[simp, to_additive]
lemma equiv_quotient_zpow_of_equiv_refl :
  mul_equiv.refl (A ⧸ (zpow_group_hom n : A →* A).range)
    = equiv_quotient_zpow_of_equiv (mul_equiv.refl A) n :=
by { ext x, rw [← quotient.out_eq' x], refl }

@[simp, to_additive]
lemma equiv_quotient_zpow_of_equiv_symm :
  (equiv_quotient_zpow_of_equiv e n).symm = equiv_quotient_zpow_of_equiv e.symm n :=
rfl

@[simp, to_additive]
lemma equiv_quotient_zpow_of_equiv_trans :
  (equiv_quotient_zpow_of_equiv e n).trans (equiv_quotient_zpow_of_equiv d n)
    = equiv_quotient_zpow_of_equiv (e.trans d) n :=
by { ext x, rw [← quotient.out_eq' x], refl }

end zpow

section snd_isomorphism_thm

open _root_.subgroup

/-- **Noether's second isomorphism theorem**: given two subgroups `H` and `N` of a group `G`, where
`N` is normal, defines an isomorphism between `H/(H ∩ N)` and `(HN)/N`. -/
@[to_additive "The second isomorphism theorem: given two subgroups `H` and `N` of a group `G`,
where `N` is normal, defines an isomorphism between `H/(H ∩ N)` and `(H + N)/N`"]
noncomputable def quotient_inf_equiv_prod_normal_quotient (H N : subgroup G) [N.normal] :
  H ⧸ (N.subgroup_of H) ≃* _ ⧸ (N.subgroup_of (H ⊔ N)) :=
/- φ is the natural homomorphism H →* (HN)/N. -/
let φ : H →* _ ⧸ (N.subgroup_of (H ⊔ N)) :=
  (mk' $ N.subgroup_of (H ⊔ N)).comp (inclusion le_sup_left) in
have φ_surjective : surjective φ := λ x, x.induction_on' $
  begin
    rintro ⟨y, (hy : y ∈ ↑(H ⊔ N))⟩, rw mul_normal H N at hy,
    rcases hy with ⟨h, n, hh, hn, rfl⟩,
    use [h, hh], apply quotient.eq.mpr,
    change setoid.r _ _,
    rw left_rel_apply,
    change h⁻¹ * (h * n) ∈ N,
    rwa [←mul_assoc, inv_mul_self, one_mul],
  end,
(quotient_mul_equiv_of_eq (by simp [← comap_ker])).trans
  (quotient_ker_equiv_of_surjective φ φ_surjective)

end snd_isomorphism_thm

section third_iso_thm

variables (M : subgroup G) [nM : M.normal]

include nM nN

@[to_additive] instance map_normal : (M.map (quotient_group.mk' N)).normal :=
nM.map _ mk_surjective

variables (h : N ≤ M)

/-- The map from the third isomorphism theorem for groups: `(G / N) / (M / N) → G / M`. -/
@[to_additive "The map from the third isomorphism theorem for additive groups:
`(A / N) / (M / N) → A / M`."]
def quotient_quotient_equiv_quotient_aux :
  (G ⧸ N) ⧸ (M.map (mk' N)) →* G ⧸ M :=
lift (M.map (mk' N))
  (map N M (monoid_hom.id G) h)
  (by { rintro _ ⟨x, hx, rfl⟩, rw map_mk' N M _ _ x,
        exact (quotient_group.eq_one_iff _).mpr hx })

@[simp, to_additive]
lemma quotient_quotient_equiv_quotient_aux_coe (x : G ⧸ N) :
  quotient_quotient_equiv_quotient_aux N M h x = quotient_group.map N M (monoid_hom.id G) h x :=
quotient_group.lift_mk' _ _ x

@[to_additive]
lemma quotient_quotient_equiv_quotient_aux_coe_coe (x : G) :
  quotient_quotient_equiv_quotient_aux N M h (x : G ⧸ N) =
    x :=
quotient_group.lift_mk' _ _ x

/-- **Noether's third isomorphism theorem** for groups: `(G / N) / (M / N) ≃* G / M`. -/
@[to_additive "**Noether's third isomorphism theorem** for additive groups:
`(A / N) / (M / N) ≃+ A / M`."]
def quotient_quotient_equiv_quotient :
  (G ⧸ N) ⧸ (M.map (quotient_group.mk' N)) ≃* G ⧸ M :=
monoid_hom.to_mul_equiv
  (quotient_quotient_equiv_quotient_aux N M h)
  (quotient_group.map _ _ (quotient_group.mk' N) (subgroup.le_comap_map _ _))
  (by { ext, simp })
  (by { ext, simp })

end third_iso_thm

section trivial

@[to_additive] lemma subsingleton_quotient_top :
  subsingleton (G ⧸ (⊤ : subgroup G)) :=
begin
  dsimp [has_quotient.quotient, subgroup.has_quotient, quotient],
  rw left_rel_eq,
  exact @trunc.subsingleton G,
end

/-- If the quotient by a subgroup gives a singleton then the subgroup is the whole group. -/
@[to_additive "If the quotient by an additive subgroup gives a singleton then the additive subgroup
is the whole additive group."] lemma subgroup_eq_top_of_subsingleton (H : subgroup G)
  (h : subsingleton (G ⧸ H)) : H = ⊤ :=
top_unique $ λ x _,
  have this : 1⁻¹ * x ∈ H := quotient_group.eq.1 (subsingleton.elim _ _),
  by rwa [inv_one, one_mul] at this

end trivial

@[to_additive]
lemma comap_comap_center {H₁ : subgroup G} [H₁.normal] {H₂ : subgroup (G ⧸ H₁)} [H₂.normal] :
  (((subgroup.center ((G ⧸ H₁) ⧸ H₂))).comap (mk' H₂)).comap (mk' H₁) =
  (subgroup.center (G ⧸ H₂.comap (mk' H₁))).comap (mk' (H₂.comap (mk' H₁))) :=
begin
  ext x,
  simp only [mk'_apply, subgroup.mem_comap, subgroup.mem_center_iff, forall_coe,
    ← coe_mul, eq_iff_div_mem, coe_div]
end

end quotient_group

namespace group

open_locale classical
open quotient_group subgroup

variables {F G H : Type u} [group F] [group G] [group H] [fintype F] [fintype H]
variables (f : F →* G) (g : G →* H)

/-- If `F` and `H` are finite such that `ker(G →* H) ≤ im(F →* G)`, then `G` is finite. -/
@[to_additive "If `F` and `H` are finite such that `ker(G →+ H) ≤ im(F →+ G)`, then `G` is finite."]
noncomputable def fintype_of_ker_le_range (h : g.ker ≤ f.range) : fintype G :=
@fintype.of_equiv _ _ (@prod.fintype _ _ (fintype.of_injective _ $ ker_lift_injective g) $
                                          fintype.of_injective _ $ inclusion_injective h)
  group_equiv_quotient_times_subgroup.symm

/-- If `F` and `H` are finite such that `ker(G →* H) = im(F →* G)`, then `G` is finite. -/
@[to_additive "If `F` and `H` are finite such that `ker(G →+ H) = im(F →+ G)`, then `G` is finite."]
noncomputable def fintype_of_ker_eq_range (h : g.ker = f.range) : fintype G :=
fintype_of_ker_le_range _ _ h.le

/-- If `ker(G →* H)` and `H` are finite, then `G` is finite. -/
@[to_additive "If `ker(G →+ H)` and `H` are finite, then `G` is finite."]
noncomputable def fintype_of_ker_of_codom [fintype g.ker] : fintype G :=
fintype_of_ker_le_range ((top_equiv : _ ≃* G).to_monoid_hom.comp $ inclusion le_top) g $
  λ x hx, ⟨⟨x, hx⟩, rfl⟩

/-- If `F` and `coker(F →* G)` are finite, then `G` is finite. -/
@[to_additive "If `F` and `coker(F →+ G)` are finite, then `G` is finite."]
noncomputable def fintype_of_dom_of_coker [normal f.range] [fintype $ G ⧸ f.range] : fintype G :=
fintype_of_ker_le_range _ (mk' f.range) $ λ x, (eq_one_iff x).mp

end group
